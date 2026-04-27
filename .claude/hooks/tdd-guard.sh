#!/bin/bash
# PreToolUse hook for Edit|Write: block edits to existing implementation files with no related tests.

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

block() {
  echo "[TDD GUARD BLOCK] $1" >&2
  exit 2
}

[ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ] || exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  /*) TARGET="$FILE_PATH" ;;
  *) TARGET="$PROJECT_DIR/$FILE_PATH" ;;
esac

[ -f "$TARGET" ] || exit 0

TEST_INFO=$(python3 "$PROJECT_DIR/execute.py" related-tests "$TARGET" 2>/dev/null)
[ -z "$TEST_INFO" ] && exit 0

SOURCE_FILE=$(echo "$TEST_INFO" | jq -r '.source_file // false' 2>/dev/null)
[ "$SOURCE_FILE" = "true" ] || exit 0

COUNT=$(echo "$TEST_INFO" | jq -r '.count // 0' 2>/dev/null)
if [ "$COUNT" -gt 0 ]; then
  exit 0
fi

RELATIVE_TARGET=$(python3 - "$PROJECT_DIR" "$TARGET" <<'PY'
from pathlib import Path
import sys
project = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
try:
    print(target.relative_to(project))
except ValueError:
    print(target)
PY
)

INCIDENT=$(python3 "$PROJECT_DIR/execute.py" record-incident \
  --source tdd-guard \
  --key "$RELATIVE_TARGET" \
  --message "Missing related tests for $RELATIVE_TARGET" 2>/dev/null)
TRIPPED=$(echo "$INCIDENT" | jq -r '.tripped // false' 2>/dev/null)

MESSAGE="Implementation file $RELATIVE_TARGET has no related test file. Create the test first or edit the matching test in the same change."
if [ "$TRIPPED" = "true" ]; then
  MESSAGE="$MESSAGE Circuit breaker: repeated same block 5+ times in 60s. Change strategy."
fi

block "$MESSAGE"
