#!/bin/bash
# PostToolUse hook for Edit|Write: debug statements + credential leak detection
# Reads tool_input from stdin (JSON)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

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

# 2. Credential leak check (pattern-based heuristic, optimized for common real tokens)
# Patterns: sk-/sk_live_/sk_test_/pk_live_ (OpenAI/Stripe style), ghp_/gho_ (GitHub),
#           glpat- (GitLab), hf_ (Hugging Face), AIza (Google), xox*- (Slack),
#           AKIA/aws_secret_access_key (AWS), v1. (Vercel)
case "$EXT" in
  md|json|yaml|yml|sh|ts|js|py|env|toml|cfg)
    CRED_HITS=$(grep -nE '(sk-[a-zA-Z0-9_-]{20,}|sk_(live|test)_[a-zA-Z0-9]{16,}|pk_live_[a-zA-Z0-9]{16,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]{20,}|hf_[A-Za-z0-9]{16,}|AIza[a-zA-Z0-9_-]{35}|xox(b|a|p|r)-[A-Za-z0-9-]{10,}|AKIA[A-Z0-9]{16}|aws_secret_access_key[[:space:]]*=|v1\.[A-Za-z0-9._-]{20,})' "$FILE_PATH" 2>/dev/null | head -3)
    if [ -n "$CRED_HITS" ]; then
      WARNINGS="${WARNINGS:+$WARNINGS
}[CRITICAL] Possible credential/API key detected in $FILE_PATH — rotate immediately if real:
$CRED_HITS"
    fi
    ;;
esac

if [ -n "$WARNINGS" ]; then
  INCIDENT=$(python3 "$PROJECT_DIR/execute.py" record-incident \
    --source post-edit-check \
    --key "$FILE_PATH" \
    --message "Post edit warnings for $FILE_PATH" 2>/dev/null || true)
  TRIPPED=$(echo "$INCIDENT" | jq -r '.tripped // false' 2>/dev/null)
  if [ "$TRIPPED" = "true" ]; then
    WARNINGS="${WARNINGS}
[CIRCUIT BREAKER] Same warning repeated 5+ times in 60s for $FILE_PATH. Change strategy before retrying."
  fi
  echo "$WARNINGS"
fi

exit 0
