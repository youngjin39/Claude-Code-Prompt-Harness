#!/bin/bash
# SessionEnd hook: auto-save session snapshot + memory harvesting reminder
# Fires when session closes. stdout → Claude's context window.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SESSIONS_DIR="$PROJECT_DIR/tasks/sessions"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_FILE="$SESSIONS_DIR/session-${TIMESTAMP}.md"

mkdir -p "$SESSIONS_DIR" || { echo "[SessionEnd] ERROR: Cannot create $SESSIONS_DIR"; exit 0; }

# Auto-generate session snapshot
{
  echo "# Session Snapshot — $TIMESTAMP"
  echo ""
  echo "## Changes This Session"
  if [ -d "$PROJECT_DIR/.git" ]; then
    # Show commits from today
    git -C "$PROJECT_DIR" log --oneline --since="8 hours ago" 2>/dev/null | sed 's/^/- /'
  fi
  echo ""
  echo "## Modified Files"
  if [ -d "$PROJECT_DIR/.git" ]; then
    git -C "$PROJECT_DIR" diff --name-only HEAD~5 HEAD 2>/dev/null | sed 's/^/- /' | head -20
  fi
  echo ""
  echo "## TODO (agent fills before exit)"
  echo "- What Worked:"
  echo "- What Did NOT Work:"
  echo "- Decisions Made:"
  echo "- Next Step:"
  echo "- Memory Harvest: (new insights to save to docs/)"
} > "$SNAPSHOT_FILE"

echo "[SessionEnd] Session snapshot saved: $SNAPSHOT_FILE"
echo ""
echo "Before exiting, review and complete the snapshot:"
echo "  1. Fill the TODO section in $SNAPSHOT_FILE"
echo "  2. Check: any conversation insights worth saving to docs/? (Memory Harvesting)"
echo "  3. Clean up older snapshots in tasks/sessions/ (keep only latest)"
