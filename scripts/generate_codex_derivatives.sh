#!/bin/bash

set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_ROOT="${CODEX_DERIVATION_OUTPUT_ROOT:-.}"
DERIVATION_PROFILE="${CODEX_DERIVATION_PROFILE:-core}"
if [ "$OUTPUT_ROOT" = "." ]; then
  OUTPUT_ROOT="$ROOT_DIR"
elif [[ "$OUTPUT_ROOT" != /* ]]; then
  OUTPUT_ROOT="$ROOT_DIR/$OUTPUT_ROOT"
fi

if [ ! -f "CLAUDE.md" ]; then
  echo "ERROR: CLAUDE.md not found in repository root." >&2
  exit 1
fi

mkdir -p "$OUTPUT_ROOT/.codex/agents" "$OUTPUT_ROOT/.agents/skills" "$OUTPUT_ROOT/.codex-sync"

CORE_SKILLS=(
  brainstorming
  code-review
  deep-interview
  git-commit
  project-doctor
  self-audit
  testing
  ux-ui-design
  verification
  writing-plans
)

FULL_SKILLS=(
  brainstorming
  browser-automation
  code-review
  code-review-graph
  deep-interview
  git-commit
  knowledge-ingest
  knowledge-lint
  project-doctor
  self-audit
  testing
  ux-ui-design
  verification
  writing-plans
)

extract_frontmatter_field() {
  local file="$1"
  local key="$2"
  perl -0ne '
    if (/^---\n(.*?)\n---/s) {
      my $fm = $1;
      if ($fm =~ /^'"$key"':\s*(.+)$/m) {
        my $value = $1;
        $value =~ s/^"(.*)"$/$1/;
        print $value;
      }
    }
  ' "$file"
}

body_without_frontmatter() {
  local file="$1"
  awk '
    BEGIN { in_fm = 0; seen = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" && seen == 0 { in_fm = 0; seen = 1; next }
    !in_fm { print }
  ' "$file"
}

body_preface_without_frontmatter() {
  local file="$1"
  body_without_frontmatter "$file" | awk '
    /^## / { exit }
    { print }
  '
}

has_exact_heading() {
  local file="$1"
  local heading="$2"
  awk -v heading="$heading" '$0 == heading { found = 1; exit } END { exit found ? 0 : 1 }' "$file"
}

is_canonical_starter_claude() {
  local file="$1"
  has_exact_heading "$file" "## Required Reads" \
    && has_exact_heading "$file" "## Workflow" \
    && has_exact_heading "$file" "## Agent / Skill / Hook Contract"
}

escape_toml_multiline() {
  perl -0pe 's/"""/\\"""/g'
}

selected_skill_names() {
  case "$DERIVATION_PROFILE" in
    core) printf '%s\n' "${CORE_SKILLS[@]}" ;;
    full) printf '%s\n' "${FULL_SKILLS[@]}" ;;
    *)
      echo "ERROR: unsupported CODEX_DERIVATION_PROFILE=$DERIVATION_PROFILE" >&2
      exit 1
      ;;
  esac
}

has_selected_skill() {
  local name="$1"
  selected_skill_names | grep -qx "$name"
}

emit_section() {
  local file="$1"
  local heading="$2"
  awk -v heading="$heading" '
    $0 == "```" { in_fence = !in_fence }
    $0 == heading { in_section = 1 }
    in_section {
      if (!in_fence && $0 ~ /^## / && $0 != heading) exit
      if (!in_fence && $0 ~ /^<Failure_Modes_To_Avoid>$/) exit
      print
    }
  ' "$file"
}

emit_shared_policy_sections() {
  local file="$1"
  local first=1
  local headings=(
    "## Context Management"
    "## Language Protocol"
    "## Surgical Change Rules"
    "## Token Efficiency"
    "## Principles"
  )

  local heading
  for heading in "${headings[@]}"; do
    if [ "$first" -eq 0 ]; then
      echo
    fi
    emit_section "$file" "$heading"
    first=0
  done
}

emit_runtime_sections() {
  local file="$1"
  local first=1
  local headings=(
    "## Required Reads"
    "## Workflow"
    "## Mode Classification"
    "## Agent / Skill / Hook Contract"
    "## Harness Defaults"
    "## Custom Harness Rules"
    "## Codex Derivation Layer"
    "## Codex Use Boundary"
    "## Skill Trigger Table"
  )

  local heading
  for heading in "${headings[@]}"; do
    if [ "$first" -eq 0 ]; then
      echo
    fi
    emit_section "$file" "$heading"
    first=0
  done
}

emit_agent_sections_for_codex() {
  local src="$1"
  local name="$2"
  local first=1
  local headings=()

  case "$name" in
    main-orchestrator)
      headings=(
        "## Ambiguity Gate"
        "## Task Classification"
        "## Simple Tasks (direct execution)"
        "## Complex Tasks (pipeline)"
        "## Post-completion"
        "## Feedback → Learning"
        "## Reporting"
        "## Language"
      )
      ;;
    executor-agent)
      headings=(
        "## Protocol"
        "## State Checkpoint (externalize, don't trust memory)"
        "## Report Format"
        "## Language"
      )
      ;;
    quality-agent)
      headings=(
        "## Adversarial Lens"
        "## Protocol"
        "## Starter Drift Checks"
        "## Report Format"
        "## Language"
      )
      ;;
    *)
      body_without_frontmatter "$src"
      return
      ;;
  esac

  body_preface_without_frontmatter "$src"

  local heading
  for heading in "${headings[@]}"; do
    echo
    emit_section "$src" "$heading"
  done

  local failure_block
  failure_block="$(body_without_frontmatter "$src" | awk '
    /<Failure_Modes_To_Avoid>/ { in_block = 1 }
    in_block { print }
    /<\/Failure_Modes_To_Avoid>/ { exit }
  ')"
  if [ -n "$failure_block" ]; then
    echo
    printf '%s\n' "$failure_block"
  fi
}

emit_codex_agent_skill_hook_contract() {
  local file="$1"
  emit_section "$file" "## Agent / Skill / Hook Contract" | python3 -c '
import sys
text = sys.stdin.read()
replacements = {
    "- Hooks own automatic enforcement and state:": "- Hooks describe Claude automatic behavior and the Codex mirror obligations for the same outcomes:",
    "  - `SessionStart` loads startup context (`tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, latest session snapshot when present); treat that context as authoritative, then read more only when the task requires it.": "  - [Claude] `SessionStart` loads startup context (`tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, latest session snapshot when present); treat that context as authoritative, then read more only when the task requires it. [Codex] Read the same startup files manually before acting.",
    "  - `PreCompact` creates a handoff skeleton before context reduction; review and complete it before compacting. This is advisory; the hook does not block compaction.": "  - [Claude] `PreCompact` creates a handoff skeleton before context reduction; review and complete it before compacting. This is advisory; the hook does not block compaction. [Codex] Before invoking compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract.",
    "  - `PreToolUse` enforces path safety before edits/commands.": "  - [Claude] `PreToolUse` enforces path safety before edits/commands. [Codex] Apply the same blocked-intent rules through the instruction contract and verifier-backed drift checks.",
    "  - `TddGuard` enforces the test-first rule for edits to existing implementation files when related tests are detectable.": "  - [Claude] `TddGuard` enforces the test-first rule for edits to existing implementation files when related tests are detectable. [Codex] Apply the same test-first rule through the instruction contract and verifier-backed drift checks.",
    "  - `PostToolUse` inspects edits for debug leftovers and credential leaks.": "  - [Claude] `PostToolUse` inspects edits for debug leftovers and credential leaks. [Codex] Treat the same review as mandatory manual post-edit work.",
    "  - `SessionEnd` saves the latest session snapshot for continuity. This preserves state, not proof of completion.": "  - [Claude] `SessionEnd` saves the latest session snapshot for continuity. This preserves state, not proof of completion. [Codex] At session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.",
}
for old, new in replacements.items():
    text = text.replace(old, new)
sys.stdout.write(text)
'
}

emit_codex_required_reads() {
  local file="$1"
  emit_section "$file" "## Required Reads" | python3 -c '
import sys
text = sys.stdin.read()
text = text.replace(
    "9. `docs/operations/claude-runtime.md` when task flow, hooks, or memory behavior matters",
    "9. `docs/operations/codex-runtime.md` when task flow, generated instructions, or memory behavior matters",
)
sys.stdout.write(text)
'
}

write_agents_md() {
  local skill_list
  skill_list="$(selected_skill_names | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  if is_canonical_starter_claude CLAUDE.md; then
    {
      echo "<!-- GENERATED FILE: edit CLAUDE.md and rerun scripts/generate_codex_derivatives.sh -->"
      echo
      echo "# Codex Project Instructions"
      echo
      echo "## Source Of Truth"
      echo "- Edit \`CLAUDE.md\`, \`.claude/agents/*\`, \`.claude/skills/*\`."
      echo "- Do not hand-edit \`AGENTS.md\`, \`.codex/\`, or \`.agents/\`."
      echo
      echo "## Startup"
      echo "- Read the startup context files required by the SessionStart mirror rule before acting."
      echo "- Use generated Codex skills first."
      echo "- If derived files are stale, regenerate from Claude source."
      echo
      echo "- Skills: \`$skill_list\`"
      echo
      emit_codex_required_reads CLAUDE.md
      echo
      emit_section CLAUDE.md "## Workflow"
      echo
      emit_section CLAUDE.md "## Mode Classification"
      echo
      emit_codex_agent_skill_hook_contract CLAUDE.md
      echo
      emit_section CLAUDE.md "## Harness Defaults"
      echo
      emit_section CLAUDE.md "## Custom Harness Rules"
      echo
      emit_section CLAUDE.md "## Codex Derivation Layer"
      echo
      emit_section CLAUDE.md "## Codex Use Boundary"
      echo
      emit_section CLAUDE.md "## Skill Trigger Table"
      echo
      emit_shared_policy_sections CLAUDE.md
    } > "$OUTPUT_ROOT/AGENTS.md"
  else
    {
      echo "<!-- GENERATED FILE: edit CLAUDE.md and rerun scripts/generate_codex_derivatives.sh -->"
      echo
      echo "# Codex Project Instructions"
      echo
      echo
      echo "## Source Of Truth"
      echo "- Edit \`CLAUDE.md\`, \`.claude/agents/*\`, \`.claude/skills/*\`."
      echo "- Do not hand-edit \`AGENTS.md\`, \`.codex/\`, or \`.agents/\`."
      echo
      echo "## Startup"
      echo "- Read the startup context files required by the local Claude workflow before acting."
      echo "- Use generated Codex skills first."
      echo "- If derived files are stale, regenerate from Claude source."
      echo
      echo "- Skills: \`$skill_list\`"
      echo
      body_without_frontmatter CLAUDE.md
    } > "$OUTPUT_ROOT/AGENTS.md"
  fi
}

write_config_toml() {
  local approval_policy="on-request"
  local settings_source=""
  if [ -f ".claude/settings.local.json" ]; then
    settings_source=".claude/settings.local.json"
  elif [ -f ".claude/settings.json" ]; then
    settings_source=".claude/settings.json"
  fi
  if [ -n "$settings_source" ]; then
    local mode
    mode="$(jq -r '.permissions.defaultMode // empty' "$settings_source" 2>/dev/null || true)"
    if [ "$mode" = "bypassPermissions" ]; then
      approval_policy="never"
    fi
  fi

  {
    echo "# GENERATED FILE: edit Claude source files and rerun scripts/generate_codex_derivatives.sh"
    echo
    echo "approval_policy = \"$approval_policy\""
    echo 'sandbox_mode = "workspace-write"'
    echo 'web_search = "cached"'
    echo 'personality = "pragmatic"'
    echo 'project_doc_fallback_filenames = ["AGENTS.md"]'
    echo 'project_doc_max_bytes = 32768'
    echo
    echo '[agents]'
    echo 'max_threads = 6'
    echo 'max_depth = 1'
    echo
    echo '[features]'
    echo 'multi_agent = true'
    echo 'shell_snapshot = true'
    echo 'personality = true'
    echo
    if [ -f ".mcp.json" ]; then
      jq -r '
        .mcpServers
        | to_entries[]
        | "\n[mcp_servers.\"" + .key + "\"]\ncommand = \"" + .value.command + "\"\nargs = [" + ((.value.args // []) | map("\"" + . + "\"") | join(", ")) + "]"
      ' .mcp.json
    fi
  } > "$OUTPUT_ROOT/.codex/config.toml"
}

write_agent_toml() {
  local src="$1"
  local name description developer_instructions out sandbox_mode disallowed_tools
  name="$(extract_frontmatter_field "$src" "name")"
  description="$(extract_frontmatter_field "$src" "description")"
  developer_instructions="$(emit_agent_sections_for_codex "$src" "$name" | escape_toml_multiline)"
  disallowed_tools="$(extract_frontmatter_field "$src" "disallowedTools")"
  out="$OUTPUT_ROOT/.codex/agents/${name}.toml"
  sandbox_mode="workspace-write"
  if [ "$name" = "quality-agent" ]; then
    sandbox_mode="read-only"
  fi

  {
    echo "# GENERATED FILE: edit $src and rerun scripts/generate_codex_derivatives.sh"
    echo "name = \"$name\""
    echo "description = \"$description\""
    echo "sandbox_mode = \"$sandbox_mode\""
    echo 'developer_instructions = """'
    echo "Use \`AGENTS.md\` as the shared runtime contract for startup, workflow, mode classification, hook mirrors, and shared policy."
    echo "Do not duplicate or reinterpret that shared contract here. This file should contain only agent-specific behavior."
    if [ -n "$disallowed_tools" ]; then
      echo "Do not use these tools in this generated Codex mirror: $disallowed_tools."
    fi
    echo
    printf '%s\n' "$developer_instructions"
    echo '"""'
  } > "$out"
}

write_skill_md() {
  local src="$1"
  local rel dir out
  rel="${src#.claude/skills/}"
  dir="$(dirname "$rel")"
  out="$OUTPUT_ROOT/.agents/skills/$rel"
  mkdir -p "$OUTPUT_ROOT/.agents/skills/$dir"
  {
    echo "<!-- GENERATED FILE: edit $src and rerun scripts/generate_codex_derivatives.sh -->"
    cat "$src"
  } > "$out"
}

write_manifest_json() {
  local tmp
  tmp="$(mktemp)"
  {
    echo '{'
    echo '  "version": 1,'
    echo '  "strategy": "one-way-claude-to-codex",'
    echo '  "generated_by": "scripts/generate_codex_derivatives.sh",'
    echo '  "mappings": ['

    local first=1
    append_mapping() {
      local source="$1"
      shift
      local targets_json="$1"
      shift
      local scope="$1"
      shift
      local notes="$1"
      if [ "$first" -eq 0 ]; then
        echo ','
      fi
      first=0
      printf '    {\n'
      printf '      "source": "%s",\n' "$source"
      printf '      "targets": %s,\n' "$targets_json"
      printf '      "change_scope": "%s",\n' "$scope"
      printf '      "sync_policy": "regenerate",\n'
      printf '      "owner": "project-maintainer",\n'
      printf '      "notes": "%s"\n' "$notes"
      printf '    }'
    }

    append_mapping "CLAUDE.md" '["AGENTS.md"]' "content" "Main Codex instructions"

    local src rel name
    while IFS= read -r src; do
      [ -n "$src" ] || continue
      name="$(extract_frontmatter_field "$src" "name")"
      append_mapping "$src" "[\".codex/agents/${name}.toml\"]" "content" "Generated custom agent"
    done < <(printf '%s\n' .claude/agents/*.md | LC_ALL=C sort)

    while IFS= read -r src; do
      [ -n "$src" ] || continue
      rel="${src#.claude/skills/}"
      name="$(basename "$(dirname "$src")")"
      if ! has_selected_skill "$name"; then
        continue
      fi
      append_mapping "$src" "[\".agents/skills/${rel}\"]" "content" "Generated Codex skill"
    done < <(printf '%s\n' .claude/skills/*/SKILL.md | LC_ALL=C sort)

    if [ -f ".claude/settings.local.json" ] || [ -f ".claude/settings.json" ] || [ -f ".mcp.json" ]; then
      append_mapping "__CONFIG_SOURCES__" '[".codex/config.toml"]' "config" "Semantic mapping from Claude permissions and MCP settings"
    fi

    echo
    echo '  ]'
    echo '}'
  } > "$tmp"

  local config_source_label=""
  local label_sep=""
  if [ -f ".claude/settings.local.json" ]; then
    config_source_label="${config_source_label}${label_sep}.claude\\/settings.local.json"
    label_sep=" + "
  elif [ -f ".claude/settings.json" ]; then
    config_source_label="${config_source_label}${label_sep}.claude\\/settings.json"
    label_sep=" + "
  fi
  if [ -f ".mcp.json" ]; then
    config_source_label="${config_source_label}${label_sep}.mcp.json"
  fi
  perl -0pi -e "s/\"source\": \"__CONFIG_SOURCES__\"/\"source\": \"$config_source_label\"/g" "$tmp"
  mv "$tmp" "$OUTPUT_ROOT/.codex-sync/manifest.json"
}

write_agents_md
write_config_toml

find "$OUTPUT_ROOT/.agents/skills" -mindepth 1 -depth -exec rm -rf {} +

while IFS= read -r src; do
  [ -n "$src" ] || continue
  write_agent_toml "$src"
done < <(printf '%s\n' .claude/agents/*.md | LC_ALL=C sort)

while IFS= read -r src; do
  [ -n "$src" ] || continue
  name="$(basename "$(dirname "$src")")"
  if ! has_selected_skill "$name"; then
    continue
  fi
  write_skill_md "$src"
done < <(printf '%s\n' .claude/skills/*/SKILL.md | LC_ALL=C sort)

write_manifest_json

echo "Generated Codex derivatives:"
echo "  $OUTPUT_ROOT/AGENTS.md"
echo "  $OUTPUT_ROOT/.codex/config.toml"
echo "  $OUTPUT_ROOT/.codex/agents/*.toml"
echo "  $OUTPUT_ROOT/.agents/skills/*/SKILL.md"
echo "  $OUTPUT_ROOT/.codex-sync/manifest.json"
echo "  profile=$DERIVATION_PROFILE"
