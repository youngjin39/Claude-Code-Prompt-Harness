#!/bin/bash
# claude-code-harness setup script
# Usage: Place in an empty project folder and run: bash setup.sh
#
# What it does:
#   1. Clones the harness repo
#   2. Removes harness-specific development history
#   3. Initializes clean project files (tasks/, docs/)
#   4. Sets up CLAUDE.md with your project info
#   5. Initializes a fresh git repo

set -euo pipefail

REPO_URL="https://github.com/youngjin39/Claude-Code-Prompt-Harness.git"
HARNESS_DIR=".harness-tmp"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Pre-checks ---
if [ "$(ls -A 2>/dev/null | grep -v setup.sh | grep -v .DS_Store)" ]; then
  error "Directory is not empty. Run this script in an empty folder."
fi

command -v git >/dev/null 2>&1 || error "git is not installed."

# --- Step 1: Clone ---
info "Cloning claude-code-harness..."
git clone --depth 1 "$REPO_URL" "$HARNESS_DIR" || { echo -e "${RED}ERROR: Failed to clone harness repo. Check network connection.${NC}"; exit 1; }
rm -rf "$HARNESS_DIR/.git"

# --- Step 2: Move files ---
info "Setting up project structure..."

# Guard against overwriting existing .claude/ directory
if [ -d ".claude" ]; then
  echo -e "${RED}ERROR: .claude/ directory already exists. Remove it first or run from an empty directory.${NC}"
  rm -rf "$HARNESS_DIR"
  exit 1
fi

mv "$HARNESS_DIR"/.claude .
mv "$HARNESS_DIR"/.gitignore .
mv "$HARNESS_DIR"/CLAUDE.md .
mv "$HARNESS_DIR"/LICENSE .
mv "$HARNESS_DIR"/docs .
# Skip README.md (user will create their own), setup.sh (this script)
# Skip .mcp.json (generated in module selection step)

rm -rf "$HARNESS_DIR"

# --- Step 3: Clean harness-specific content ---
info "Cleaning harness development artifacts..."

# Remove harness-specific docs (keep directory structure)
rm -f docs/decisions/master-plan-v2.md
rm -f docs/decisions/optimization-log.md
rm -f docs/references/repo-analysis-summary.md
rm -f docs/patterns/module-blueprint-system.md

# Ensure all docs/ subdirectories exist
for dir in architecture decisions patterns domain risks integrations references; do
  mkdir -p "docs/$dir"
  touch "docs/$dir/.gitkeep"
done

# Reset memory-map.md to empty template
cat > docs/memory-map.md << 'MEMEOF'
---
title: Neuron Memory Map — Keyword Index
keywords: [memory, index, keyword, search, storage]
created: SETUP_DATE
last_used: SETUP_DATE
type: index
---

# Memory Map

> Long-term memory. No decay. Load only what's needed via category map.
> Max 50 lines per file (exception: `type: archive`). Frontmatter required: title, keywords, related, created, last_used.
> 100+ memory files → consider SQLite. 200+ lines in this file → split into sub-indexes.

## Search Protocol
1. Scan keyword table below for relevant keywords.
2. Read only matched files.
3. If file has `related` field, consider loading related files too.
4. No match → skip memory loading (save tokens).
5. **Never load an entire category at once.**

## Save Protocol
1. Create memory file: `docs/{category}/{topic}.md`
2. Frontmatter required:
   ```yaml
   ---
   title: {title}
   keywords: [keyword1, keyword2, ...]
   related: [other-file.md, ...]
   created: {YYYY-MM-DD}
   last_used: {YYYY-MM-DD}
   ---
   ```
3. Max 50 lines. Split if exceeded.
4. **Add a row to the keyword table below** (auto-update).
5. Duplicate keywords → add file to same row (1:N).
6. **Cascade**: check keyword table for existing files sharing keywords → review for contradiction/overlap → update affected files.

## Skill Usage Tracking
| Skill | Last Used | Count |
|---|---|---|
| brainstorming | — | 0 |
| code-review | — | 0 |
| deep-interview | — | 0 |
| git-commit | — | 0 |
| project-doctor | — | 0 |
| testing | — | 0 |
| verification | — | 0 |
| writing-plans | — | 0 |

## Promotion Pipeline
- Project local (docs/) → 2+ same pattern → promote to lessons.md rule
- 2+ projects with same pattern → consider promoting to ~/.claude/global-memory/

## Keyword → File Mapping
| Keyword | Category | File |
|---|---|---|
| | | |

## Category Items

### architecture
> System structure, design patterns, dependency relationships
- (none)

### decisions
> Key decisions and their rationale (ADR style)
- (none)

### patterns
> Recurring code/workflow patterns
- (none)

### domain
> Domain knowledge, business rules, glossary
- (none)

### risks
> Known risks, vulnerabilities, caveats
- (none)

### integrations
> External system integrations, APIs, services
- (none)

### references
> Reference projects, documents, repo analysis results
- (none)
MEMEOF
# Replace SETUP_DATE with actual date
SETUP_DATE=$(date +%Y-%m-%d) perl -pi -e 's/SETUP_DATE/$ENV{SETUP_DATE}/g' docs/memory-map.md

# --- Step 4: Initialize tasks/ ---
info "Initializing tasks/..."
mkdir -p tasks/handoffs tasks/sessions tasks/log

cat > tasks/plan.md << 'EOF'
# Plan

## Current State
- Project initialized with claude-code-harness.

## Next Action
- Define project scope and goals.
EOF

cat > tasks/context.md << 'EOF'
# Context — Decision Rationale

| Date | Decision | Rationale | Alternatives Considered |
|---|---|---|---|
| | | | |
EOF

cat > tasks/checklist.md << 'EOF'
# Checklist

## In Progress
- [ ] Project setup

## Done
- (none)
EOF

cat > tasks/change_log.md << 'EOF'
# Change Log

| Time | File | Change Summary | Reason |
|---|---|---|---|
| | | | |
EOF

cat > tasks/lessons.md << 'EOF'
# Lessons

## What Did NOT Work
| Date | Task | Attempted Approach | Failure Reason | Correct Approach |
|---|---|---|---|---|
| | | | | |

## What Worked
| Date | Task | Approach | Why It Was Effective |
|---|---|---|---|
| | | | |

## Codified Lessons
(Promote to rule when a pattern repeats 2+ times)
EOF

cat > tasks/cost-log.md << 'EOF'
# Cost Log

| Date | Task | Model | Est. Tokens | Notes |
|---|---|---|---|---|
| | | | | |
EOF

# --- Step 5: Update CLAUDE.md placeholders ---
info "Preparing CLAUDE.md..."

# Prompt user for project info
echo ""
echo -e "${YELLOW}--- Project Configuration ---${NC}"
read -p "Project name: " PROJECT_NAME

# --- Preset Selection ---
echo ""
echo -e "${YELLOW}--- Project Preset ---${NC}"
echo "  Pick a preset to auto-fill stack + modules + permissions."
echo "  You can still edit CLAUDE.md and .mcp.json afterwards."
echo ""
echo "   [1]  Flutter Mobile App     (Dart, pub)         testing+code-review, Context7"
echo "   [2]  Next.js Web App        (TypeScript, pnpm)  testing+code-review, Context7+SeqThink"
echo "   [3]  Node/TS Backend API    (TypeScript, npm)   testing+code-review, SeqThink"
echo "   [4]  Python Backend         (Python, uv)        testing+code-review, Context7"
echo "   [5]  Python Data/ML         (Python, uv)        testing, SeqThink"
echo "   [6]  Rust Systems           (Rust, cargo)       testing+code-review, Strict perms"
echo "   [7]  Go Service             (Go, go mod)        testing+code-review"
echo "   [8]  Embedded C/C++         (C/C++, cmake)      code-review only, Strict perms"
echo "   [9]  Claude-only Agent      (no code, content)  no testing, SeqThink"
echo "   [10] Static Site / Docs     (Astro/Hugo, npm)   minimal modules"
echo "   [11] Custom                 (manual entry — current behavior)"
echo ""
read -p "  Select [1-11, default: 11]: " PRESET_CHOICE

PRESET_NAME=""
PRESET_LOCKED=0
case "$PRESET_CHOICE" in
  1)  PRESET_NAME="Flutter Mobile App";   LANG_FRAMEWORK="Dart/Flutter";       PKG_MANAGER="pub";    MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  2)  PRESET_NAME="Next.js Web App";      LANG_FRAMEWORK="TypeScript/Next.js"; PKG_MANAGER="pnpm";   MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  3)  PRESET_NAME="Node/TS Backend API";  LANG_FRAMEWORK="TypeScript/Node.js"; PKG_MANAGER="npm";    MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  4)  PRESET_NAME="Python Backend";       LANG_FRAMEWORK="Python/FastAPI";     PKG_MANAGER="uv";     MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  5)  PRESET_NAME="Python Data/ML";       LANG_FRAMEWORK="Python/ML";          PKG_MANAGER="uv";     MOD_CODE_REVIEW=0; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  6)  PRESET_NAME="Rust Systems";         LANG_FRAMEWORK="Rust";               PKG_MANAGER="cargo";  MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; PERM_PRESET=1; PRESET_LOCKED=1 ;;
  7)  PRESET_NAME="Go Service";           LANG_FRAMEWORK="Go";                 PKG_MANAGER="go mod"; MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  8)  PRESET_NAME="Embedded C/C++";       LANG_FRAMEWORK="C/C++";              PKG_MANAGER="cmake";  MOD_CODE_REVIEW=1; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; PERM_PRESET=1; PRESET_LOCKED=1 ;;
  9)  PRESET_NAME="Claude-only Agent";    LANG_FRAMEWORK="Claude (no code)";   PKG_MANAGER="n/a";    MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  10) PRESET_NAME="Static Site / Docs";   LANG_FRAMEWORK="Astro or Hugo";      PKG_MANAGER="npm";    MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  *)  PRESET_NAME="Custom"; PRESET_LOCKED=0 ;;
esac

if [ "$PRESET_LOCKED" -eq 1 ]; then
  info "Preset: $PRESET_NAME → $LANG_FRAMEWORK ($PKG_MANAGER)"
else
  read -p "Language/Framework (e.g., TypeScript/Next.js): " LANG_FRAMEWORK
  read -p "Package manager (e.g., npm, pnpm, pip): " PKG_MANAGER
fi

echo ""
echo "  User-facing language (agent output, reports, logs):"
echo "    1) Korean (한국어)"
echo "    2) English"
echo "    3) Japanese (日本語)"
echo "    4) Chinese (中文)"
echo "    5) Other (enter language name)"
read -p "  Select [1-5, default: 2]: " LANG_CHOICE
case "$LANG_CHOICE" in
  1) USER_LANG="Korean" ;;
  3) USER_LANG="Japanese" ;;
  4) USER_LANG="Chinese" ;;
  5) read -p "  Enter language name: " USER_LANG ;;
  *) USER_LANG="English" ;;
esac

# Update CLAUDE.md (use perl to avoid sed delimiter issues with user input)
if [ -n "$PROJECT_NAME" ]; then
  P="$PROJECT_NAME" perl -pi -e 's/claude-code-harness — Claude Code Project Management Harness/$ENV{P} — Claude Code Project Management Harness/' CLAUDE.md
fi
if [ -n "$LANG_FRAMEWORK" ]; then
  P="$LANG_FRAMEWORK" perl -pi -e 's/\| Language\/Framework \| TBD \(project management harness\) \|/| Language\/Framework | $ENV{P} |/' CLAUDE.md
fi
if [ -n "$PKG_MANAGER" ]; then
  P="$PKG_MANAGER" perl -pi -e 's/\| Package Manager \| TBD \|/| Package Manager | $ENV{P} |/' CLAUDE.md
fi

# --- Step 5b: Set language protocol ---
if [ "$USER_LANG" = "English" ]; then
  # All English — simplify the protocol
  perl -pi -e 's/- User-facing output \(reports, task logs\) → Korean\./- User-facing output (reports, task logs) → English./' CLAUDE.md
else
  P="$USER_LANG" perl -pi -e 's/- User-facing output \(reports, task logs\) → Korean\./- User-facing output (reports, task logs) → $ENV{P}./' CLAUDE.md
fi

# --- Step 5c: Module Selection ---
info "Configuring optional modules..."
echo ""
echo -e "${YELLOW}--- Module Selection ---${NC}"
echo ""
echo "  Core (always included):"
echo "    ✓ 6 skills: brainstorming, writing-plans, verification,"
echo "                 deep-interview, git-commit, project-doctor"
echo "    ✓ 3 agents: orchestrator, executor, quality"
echo "    ✓ 4 hooks:  session-start, pre-compact, post-edit-check, session-end"
echo "    ✓ MCP:      fetch (web access)"
echo ""
echo "  Optional modules:"
echo "    [1] code-review skill  — PR/quality review"
echo "    [2] testing skill      — TDD enforcement"
echo "    [3] Context7 MCP       — latest library docs auto-injection"
echo "    [4] Sequential Thinking MCP — structured reasoning chains"
echo ""
if [ "$PRESET_LOCKED" -eq 1 ]; then
  MODULE_CHOICE="__preset__"
  info "  Modules locked by preset: code-review=$MOD_CODE_REVIEW testing=$MOD_TESTING context7=$MOD_CONTEXT7 seq-think=$MOD_SEQ_THINK"
else
  read -p "  Select [1-4, comma-separated, 'all', or 'none', default: all]: " MODULE_CHOICE
fi

# Parse selection
if [ "$MODULE_CHOICE" = "__preset__" ]; then
  : # already set by preset
elif [ -z "$MODULE_CHOICE" ] || [ "$MODULE_CHOICE" = "all" ]; then
  MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=1
elif [ "$MODULE_CHOICE" = "none" ]; then
  MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0
else
  MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0
  IFS=',' read -ra MODS <<< "$MODULE_CHOICE"
  for m in "${MODS[@]}"; do
    m=$(echo "$m" | tr -d ' ')
    case "$m" in
      1) MOD_CODE_REVIEW=1 ;;
      2) MOD_TESTING=1 ;;
      3) MOD_CONTEXT7=1 ;;
      4) MOD_SEQ_THINK=1 ;;
    esac
  done
fi

# Remove unselected optional skills + update CLAUDE.md references
if [ "$MOD_CODE_REVIEW" -eq 0 ]; then
  info "  Skipping: code-review skill"
  rm -rf .claude/skills/code-review
  rm -f docs/integrations/codex-code-review.md
  perl -ni -e 'print unless /code-review.*SKILL\.md/' CLAUDE.md
  perl -pi -e 's/ → code-review//g' CLAUDE.md
  perl -ni -e 'print unless /\| code-review /' docs/memory-map.md
else
  info "  Including: code-review skill"
fi

if [ "$MOD_TESTING" -eq 0 ]; then
  info "  Skipping: testing skill"
  rm -rf .claude/skills/testing
  rm -f docs/integrations/computer-use-gui-testing.md
  perl -ni -e 'print unless /\| test, TDD.*testing/' CLAUDE.md
  perl -pi -e 's/ → testing//g' CLAUDE.md
  perl -ni -e 'print unless /\| testing /' docs/memory-map.md
else
  info "  Including: testing skill"
fi

# Build .mcp.json dynamically
MCP_JSON='{\n  "mcpServers": {\n    "fetch": {\n      "command": "npx",\n      "args": ["-y", "@anthropic-ai/mcp-server-fetch"]\n    }'

if [ "$MOD_CONTEXT7" -eq 1 ]; then
  info "  Including: Context7 MCP"
  MCP_JSON="$MCP_JSON"',\n    "context7": {\n      "command": "npx",\n      "args": ["-y", "@upstash/context7-mcp@latest"]\n    }'
else
  info "  Skipping: Context7 MCP"
fi

if [ "$MOD_SEQ_THINK" -eq 1 ]; then
  info "  Including: Sequential Thinking MCP"
  MCP_JSON="$MCP_JSON"',\n    "sequential-thinking": {\n      "command": "npx",\n      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]\n    }'
else
  info "  Skipping: Sequential Thinking MCP"
fi

MCP_JSON="$MCP_JSON"'\n  }\n}'
echo -e "$MCP_JSON" > .mcp.json

# Count selected modules
SELECTED_COUNT=0
[ "$MOD_CODE_REVIEW" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_TESTING" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_CONTEXT7" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_SEQ_THINK" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))

echo ""
info "$SELECTED_COUNT/4 optional modules selected."

# --- Step 6: Permissions + settings.local.json ---
echo ""
echo -e "${YELLOW}--- Permission Level ---${NC}"
echo ""
echo "  [1] Strict  — ask before every tool use (safest)"
echo "  [2] Standard — allow read-only tools, ask for writes (recommended)"
echo "  [3] Permissive — allow most tools, ask for destructive ops only"
echo ""
if [ "$PRESET_LOCKED" -eq 1 ]; then
  PERM_CHOICE="$PERM_PRESET"
  info "  Permissions locked by preset: option $PERM_CHOICE"
else
  read -p "  Select [1-3, default: 2]: " PERM_CHOICE
fi

case "$PERM_CHOICE" in
  1)
    PERM_LEVEL="strict"
    PERM_ALLOW='[]'
    ;;
  3)
    PERM_LEVEL="permissive"
    PERM_ALLOW='["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "WebFetch(*)", "WebSearch(*)", "Agent(*)", "Glob(*)", "Grep(*)", "Skill(*)"]'
    ;;
  *)
    PERM_LEVEL="standard"
    PERM_ALLOW='["Read(*)", "Glob(*)", "Grep(*)", "Agent(*)", "Skill(*)"]'
    ;;
esac

info "Permission level: $PERM_LEVEL"

info "Generating settings.local.json..."
cat > .claude/settings.local.json << SETEOF
{
  "permissions": {
    "allow": $PERM_ALLOW
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh\"",
            "timeout": 10,
            "statusMessage": "Loading session context..."
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/pre-compact.sh\"",
            "timeout": 5,
            "statusMessage": "Checking handoff..."
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/post-edit-check.sh\"",
            "timeout": 10,
            "statusMessage": "Checking debug statements + credentials..."
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/session-end.sh\"",
            "timeout": 10,
            "statusMessage": "Saving session snapshot..."
          }
        ]
      }
    ]
  }
}
SETEOF

# --- Step 7: Git init ---
info "Initializing git repository..."
git init -q
git add -A
git commit -q -m "feat: initialize project with claude-code-harness"

# --- Done ---
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
# Build skill list for summary
SKILL_LIST="brainstorming, writing-plans, verification, interview, git-commit, project-doctor, self-audit"
SKILL_COUNT=7
[ "$MOD_CODE_REVIEW" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, code-review"; SKILL_COUNT=$((SKILL_COUNT + 1)); }
[ "$MOD_TESTING" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, testing"; SKILL_COUNT=$((SKILL_COUNT + 1)); }

# Build MCP list for summary
MCP_LIST="fetch"
MCP_COUNT=1
[ "$MOD_CONTEXT7" -eq 1 ] && { MCP_LIST="$MCP_LIST, context7"; MCP_COUNT=$((MCP_COUNT + 1)); }
[ "$MOD_SEQ_THINK" -eq 1 ] && { MCP_LIST="$MCP_LIST, sequential-thinking"; MCP_COUNT=$((MCP_COUNT + 1)); }

echo "  Project:     ${PROJECT_NAME:-unnamed}"
echo "  Preset:      ${PRESET_NAME}"
echo "  Stack:       ${LANG_FRAMEWORK} (${PKG_MANAGER})"
echo "  Language:    ${USER_LANG} (user-facing output)"
echo "  Permissions: ${PERM_LEVEL}"
echo "  Agents:      3 (orchestrator, executor, quality)"
echo "  Skills:      ${SKILL_COUNT} (${SKILL_LIST})"
echo "  MCP:         ${MCP_COUNT} (${MCP_LIST})"
echo "  Hooks:       4 (SessionStart, PreCompact, PostToolUse, SessionEnd)"
echo ""
echo "  Note: tasks/ files are local working memory (gitignored by default)."
echo ""
echo "  Next steps:"
echo "    1. cd $(pwd)"
echo "    2. Review CLAUDE.md and customize Build & Run section"
echo "    3. Configure tool permissions in .claude/settings.local.json"
echo "    4. Start Claude Code: claude"
echo ""
echo "  Optional:"
echo "    - Add domain skills to .claude/skills/"
echo "    - Connect to remote: git remote add origin <url> && git push -u origin main"
echo ""
