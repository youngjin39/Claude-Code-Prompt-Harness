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
git clone --depth 1 "$REPO_URL" "$HARNESS_DIR" 2>/dev/null
rm -rf "$HARNESS_DIR/.git"

# --- Step 2: Move files ---
info "Setting up project structure..."
mv "$HARNESS_DIR"/.claude .
mv "$HARNESS_DIR"/.gitignore .
mv "$HARNESS_DIR"/.mcp.json .
mv "$HARNESS_DIR"/CLAUDE.md .
mv "$HARNESS_DIR"/LICENSE .
mv "$HARNESS_DIR"/docs .
# Skip README.md (user will create their own), setup.sh (this script)

rm -rf "$HARNESS_DIR"

# --- Step 3: Clean harness-specific content ---
info "Cleaning harness development artifacts..."

# Remove harness-specific docs (keep directory structure)
rm -f docs/decisions/master-plan-v2.md
rm -f docs/references/repo-analysis-summary.md

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
> Max 50 lines per file (exception: `type: archive`). Frontmatter required: title, keywords, created, last_used.
> 100+ memory files → consider SQLite. 200+ lines in this file → split into sub-indexes.

## Search Protocol
1. Scan keyword table below for relevant keywords.
2. Read only matched files.
3. No match → skip memory loading (save tokens).
4. **Never load an entire category at once.**

## Save Protocol
1. Create memory file: `docs/{category}/{topic}.md`
2. Frontmatter required:
   ```yaml
   ---
   title: {title}
   keywords: [keyword1, keyword2, ...]
   created: {YYYY-MM-DD}
   last_used: {YYYY-MM-DD}
   ---
   ```
3. Max 50 lines. Split if exceeded.
4. **Add a row to the keyword table below** (auto-update).
5. Duplicate keywords → add file to same row (1:N).

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
sed -i '' "s/SETUP_DATE/$(date +%Y-%m-%d)/g" docs/memory-map.md

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
read -p "Language/Framework (e.g., TypeScript/Next.js): " LANG_FRAMEWORK
read -p "Package manager (e.g., npm, pnpm, pip): " PKG_MANAGER

# Update CLAUDE.md (use perl to avoid sed delimiter issues with user input)
if [ -n "$PROJECT_NAME" ]; then
  P="$PROJECT_NAME" perl -pi -e 's/claude-code-harness — Claude Code Project Management Harness/$ENV{P} — Claude Code Project Management Harness/' CLAUDE.md 2>/dev/null
fi
if [ -n "$LANG_FRAMEWORK" ]; then
  P="$LANG_FRAMEWORK" perl -pi -e 's/\| Language\/Framework \| TBD \(project management harness\) \|/| Language\/Framework | $ENV{P} |/' CLAUDE.md 2>/dev/null
fi
if [ -n "$PKG_MANAGER" ]; then
  P="$PKG_MANAGER" perl -pi -e 's/\| Package Manager \| TBD \|/| Package Manager | $ENV{P} |/' CLAUDE.md 2>/dev/null
fi

# --- Step 6: Clean settings.local.json ---
info "Resetting settings.local.json to template..."
cat > .claude/settings.local.json << 'SETEOF'
{
  "permissions": {
    "allow": []
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh\"",
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
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/pre-compact.sh\"",
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
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/post-edit-check.sh\"",
            "timeout": 10,
            "statusMessage": "Checking debug statements + credentials..."
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
echo "  Project: ${PROJECT_NAME:-unnamed}"
echo "  Agents:  3 (orchestrator, executor, quality)"
echo "  Skills:  8 (brainstorming, plans, verification, interview,"
echo "              code-review, testing, git-commit, project-doctor)"
echo "  Hooks:   3 (SessionStart, PreCompact, PostToolUse)"
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
