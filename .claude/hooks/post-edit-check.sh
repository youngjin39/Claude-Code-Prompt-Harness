#!/bin/bash
# PostToolUse hook for Edit|Write: debug statements + credential leak detection
# Reads tool_input from stdin (JSON)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"
WARNINGS=""

# 1. Debug statement check (capture output, don't leak to stdout)
case "$EXT" in
  js|ts|jsx|tsx)
    DEBUG_HITS=$(grep -n "console\.log" "$FILE_PATH" 2>/dev/null | head -3)
    if [ -n "$DEBUG_HITS" ]; then
      WARNINGS="[WARNING] console.log detected in $FILE_PATH
$DEBUG_HITS"
    fi
    ;;
  py)
    DEBUG_HITS=$(grep -n "^\s*print(" "$FILE_PATH" 2>/dev/null | grep -v "# keep" | head -3)
    if [ -n "$DEBUG_HITS" ]; then
      WARNINGS="[WARNING] print() detected in $FILE_PATH
$DEBUG_HITS"
    fi
    ;;
esac

# 2. Credential leak check (20+ char after sk- to avoid false positives)
# Patterns: sk-{20+ alphanum/hyphen} (OpenAI/Anthropic), ghp_/gho_ (GitHub),
#           AIza (Google), xoxb- (Slack), AKIA (AWS), aws_secret_access_key
case "$EXT" in
  md|json|yaml|yml|sh|ts|js|py|env|toml|cfg)
    CRED_HITS=$(grep -nE '(sk-[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|AIza[a-zA-Z0-9_-]{35}|xoxb-[0-9]{10,}|AKIA[A-Z0-9]{16}|aws_secret_access_key[[:space:]]*=)' "$FILE_PATH" 2>/dev/null | head -3)
    if [ -n "$CRED_HITS" ]; then
      WARNINGS="${WARNINGS:+$WARNINGS
}[CRITICAL] Possible credential/API key detected in $FILE_PATH — rotate immediately if real:
$CRED_HITS"
    fi
    ;;
esac

if [ -n "$WARNINGS" ]; then
  echo "$WARNINGS"
fi

exit 0
