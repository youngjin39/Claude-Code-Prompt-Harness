#!/bin/bash
# PreToolUse hook: input-stage guardrail.
# Blocks destructive patterns + denied paths BEFORE the tool runs.
# Reads tool_input from stdin (JSON). Exit 2 = block; exit 0 = allow.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
PROTECTED_BRANCHES='(main|master|release|develop|production|prod|staging)'

path_outside_project() {
  python3 - "$PROJECT_DIR" "$1" <<'PY'
from pathlib import Path
import sys

project = Path(sys.argv[1]).expanduser().resolve(strict=False)
target = Path(sys.argv[2]).expanduser()
home = Path.home().resolve(strict=False)
if not target.is_absolute():
    target = project / target
target = target.resolve(strict=False)

if target == project or project in target.parents:
    sys.exit(1)

# Allow only the Claude Code home auto-memory directory:
# ~/.claude/projects/<id>/memory/*.md after symlink resolution.
claude_projects_root = home / ".claude" / "projects"
if target.suffix == ".md" and target.parent.name == "memory":
    try:
        rel = target.relative_to(claude_projects_root)
    except ValueError:
        rel = None
    if rel is not None and len(rel.parts) == 3 and rel.parts[1] == "memory":
        sys.exit(1)

sys.exit(0)
PY
}

block() {
  # Claude Code: stdout on exit 2 is shown to the agent as a tool error.
  local message="$1"
  local incident
  local tripped="false"
  incident=$(python3 "$PROJECT_DIR/execute.py" record-incident \
    --source pre-tool-use \
    --key "$message" \
    --message "$message" 2>/dev/null || true)
  if [ -n "$incident" ]; then
    tripped=$(echo "$incident" | jq -r '.tripped // false' 2>/dev/null)
  fi
  if [ "$tripped" = "true" ]; then
    message="$message Circuit breaker: same guard triggered 5+ times in 60s. Change strategy."
  fi
  echo "[PreToolUse BLOCK] $message" >&2
  exit 2
}

# --- Bash command guards ---
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
  [ -z "$CMD" ] && exit 0

  # 1. rm -rf on anything remotely dangerous
  if echo "$CMD" | grep -qE 'rm[[:space:]]+(-[rRfF]+[[:space:]]+)+(/|~|\$HOME|\*|\.|\.\./)'; then
    block "Destructive rm pattern: $CMD"
  fi
  # 2. Force push to protected branches: main, master, release, develop, production, prod, staging
  if echo "$CMD" | grep -qE 'git[[:space:]]+push' \
    && echo "$CMD" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease)([[:space:]]|$)' \
    && echo "$CMD" | grep -qE "(^|[:/[:space:]])${PROTECTED_BRANCHES}([[:space:]]|$)"; then
    block "Force push to protected branch: $CMD"
  fi
  # 3. Hook bypass flags
  if echo "$CMD" | grep -qE '(--no-verify|--no-gpg-sign|-c[[:space:]]+commit\.gpgsign=false)'; then
    block "Hook/signing bypass flag: $CMD"
  fi
  # 4. History rewrite on shared refs: origin/*, upstream/*, protected branches, HEAD~N, HEAD^
  if echo "$CMD" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard' \
    && echo "$CMD" | grep -qE "(origin/|upstream/|HEAD~[0-9]+|HEAD\\^|${PROTECTED_BRANCHES})"; then
    block "History rewrite on shared refs: $CMD"
  fi
  if echo "$CMD" | grep -qE 'git[[:space:]]+rebase' \
    && echo "$CMD" | grep -qE "(origin/|upstream/|${PROTECTED_BRANCHES})"; then
    block "History rewrite on shared refs: $CMD"
  fi
  if echo "$CMD" | grep -qE 'git[[:space:]]+(filter-branch|filter-repo)'; then
    block "History rewrite on shared refs: $CMD"
  fi
  # 5. Piped remote install
  if echo "$CMD" | grep -qE '(curl|wget)[^|]*\|[[:space:]]*(bash|sh|zsh|python)'; then
    block "Piped remote install: $CMD"
  fi
  # 6. sudo in any form
  if echo "$CMD" | grep -qE '(^|[[:space:]])sudo([[:space:]]|$)'; then
    block "sudo requires user confirmation, not this hook: $CMD"
  fi
fi

# --- Write/Edit path guards ---
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
  [ -z "$FP" ] && exit 0

  # 1. Outside project root after path normalization. Blocks relative escapes, home paths, and /tmp writes.
  if path_outside_project "$FP"; then
    block "Write outside project root: $FP"
  fi
  # 2. Secret/env files
  case "$(basename "$FP")" in
    .env|.env.*|credentials|credentials.*|id_rsa|id_ed25519|*.pem|*.key|*.p12)
      block "Write to secret/credential file: $FP"
      ;;
  esac
  # 3. Git internal state
  if echo "$FP" | grep -qE '(^|/)\.git/(config|hooks/|refs/|objects/)'; then
    block "Write to git internal state: $FP"
  fi
fi

exit 0
