#!/bin/bash
# SessionStart hook: inject startup contract into context
# stdout → Claude's context window

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

echo "=== SESSION CONTEXT ==="

if [ -f "$PROJECT_DIR/tasks/plan.md" ]; then
  echo "--- plan.md ---"
  head -50 "$PROJECT_DIR/tasks/plan.md"
fi

echo ""

if [ -f "$PROJECT_DIR/tasks/lessons.md" ]; then
  echo "--- lessons.md ---"
  head -50 "$PROJECT_DIR/tasks/lessons.md"
fi

echo ""

if [ -f "$PROJECT_DIR/docs/memory-map.md" ]; then
  echo "--- memory-map.md ---"
  head -80 "$PROJECT_DIR/docs/memory-map.md"
fi

echo ""

# Latest session snapshot (if exists) — use find to avoid glob expansion issues
LATEST_SESSION=$(find "$PROJECT_DIR/tasks/sessions" -name "*.md" -type f 2>/dev/null | sort -r | head -1)
if [ -n "$LATEST_SESSION" ] && [ -f "$LATEST_SESSION" ]; then
  echo "--- latest session ---"
  head -50 "$LATEST_SESSION"
fi

echo "=== END SESSION CONTEXT ==="
