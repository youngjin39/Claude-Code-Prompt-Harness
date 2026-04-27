#!/bin/bash
# mir-claude-starter setup script
# Usage: Place in an empty project folder and run: bash setup.sh
#
# What it does:
#   1. Clones the starter repo
#   2. Removes starter-specific development history
#   3. Initializes clean project files (tasks/, docs/)
#   4. Sets up CLAUDE.md with your project info
#   5. Initializes a fresh git repo

set -euo pipefail

REPO_URL="https://github.com/youngjin39/mir-claude-starter.git"
STARTER_DIR=".starter-tmp"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Message definitions ---
load_messages_en() {
  # Errors
  MSG_ERR_DIR_NOT_EMPTY="Directory is not empty. Run this script in an empty folder."
  MSG_ERR_GIT_NOT_FOUND="git is not installed."
  MSG_ERR_CLONE_FAILED="${RED}ERROR: Failed to clone starter repo. Check network connection.${NC}"
  MSG_ERR_CLAUDE_DIR_EXISTS="${RED}ERROR: .claude/ directory already exists. Remove it first or run from an empty directory.${NC}"
  MSG_ERR_CODEX_SCRIPT_MISSING="${RED}ERROR: Codex derivation script is missing from the starter.${NC}"

  # Info / progress
  MSG_INFO_CLONING="Cloning mir-claude-starter..."
  MSG_INFO_SETUP_STRUCTURE="Setting up project structure..."
  MSG_INFO_CLEANING="Cleaning starter development artifacts..."
  MSG_INFO_INIT_TASKS="Initializing tasks/..."
  MSG_INFO_PREP_CLAUDE_MD="Preparing CLAUDE.md..."
  MSG_INFO_CONF_MODULES="Configuring optional modules..."
  MSG_INFO_PERM_LEVEL="Permission level: "
  MSG_INFO_GEN_SETTINGS="Generating settings.local.json..."
  MSG_INFO_GEN_CODEX="Generating Codex derived files..."
  MSG_INFO_GIT_INIT="Initializing git repository..."

  # Section headers
  MSG_HDR_TARGET="--- Install Target ---"
  MSG_HDR_PROJECT_CONFIG="--- Project Configuration ---"
  MSG_HDR_PRESET="--- Project Preset ---"
  MSG_HDR_MODULE="--- Module Selection ---"
  MSG_HDR_PERM="--- Permission Level ---"

  # Target section
  MSG_TARGET_INTRO="  Choose which agent environment to prepare."
  MSG_TARGET_1="   [1] Claude only        — starter source files only"
  MSG_TARGET_2="   [2] Codex only         — keep Claude source + generate Codex layer"
  MSG_TARGET_3="   [3] Both               — Claude source + generated Codex layer"
  MSG_TARGET_SELECT_PROMPT="  Select [1-3, default: 1]: "

  # Project config prompts
  MSG_PROJECT_NAME_PROMPT="Project name: "
  MSG_LANG_FW_PROMPT="Language/Framework (e.g., TypeScript/Next.js): "
  MSG_PKG_MANAGER_PROMPT="Package manager (e.g., npm, pnpm, pip): "

  # Preset section
  MSG_PRESET_INTRO="  Pick a preset to auto-fill stack + modules + permissions."
  MSG_PRESET_EDIT_NOTE="  You can still edit CLAUDE.md and .mcp.json afterwards."
  MSG_PRESET_1="   [1]  Flutter Mobile App     (Dart, pub)         testing+code-review, Context7"
  MSG_PRESET_2="   [2]  Next.js Web App        (TypeScript, pnpm)  testing+code-review, Context7+SeqThink"
  MSG_PRESET_3="   [3]  Node/TS Backend API    (TypeScript, npm)   testing+code-review, SeqThink"
  MSG_PRESET_4="   [4]  Python Backend         (Python, uv)        testing+code-review, Context7"
  MSG_PRESET_5="   [5]  Python Data/ML         (Python, uv)        testing, SeqThink"
  MSG_PRESET_6="   [6]  Rust Systems           (Rust, cargo)       testing+code-review, Strict perms"
  MSG_PRESET_7="   [7]  Go Service             (Go, go mod)        testing+code-review"
  MSG_PRESET_8="   [8]  Embedded C/C++         (C/C++, cmake)      code-review only, Strict perms"
  MSG_PRESET_9="   [9]  Claude-only Agent      (no code, content)  no testing, SeqThink"
  MSG_PRESET_10="   [10] Static Site / Docs     (Astro/Hugo, npm)   minimal modules"
  MSG_PRESET_11="   [11] Custom                 (manual entry — current behavior)"
  MSG_PRESET_SELECT_PROMPT="  Select [1-11, default: 11]: "
  MSG_PRESET_LOCKED="Preset: "
  MSG_PRESET_LOCKED_MODULES="  Modules locked by preset: "

  # Module section
  MSG_MOD_CORE_HEADER="  Core (always included):"
  MSG_MOD_CORE_SKILLS="    ✓ 6 skills: brainstorming, writing-plans, verification,"
  MSG_MOD_CORE_SKILLS2="                 deep-interview, git-commit, project-doctor"
  MSG_MOD_CORE_AGENTS="    ✓ 3 agents: orchestrator, executor, quality"
  MSG_MOD_CORE_HOOKS="    ✓ 6 hooks:  session-start, pre-compact, pre-tool-use, tdd-guard, post-edit-check, session-end"
  MSG_MOD_CORE_WEB="    ✓ Web:      built-in WebFetch / WebSearch (no MCP needed)"
  MSG_MOD_OPTIONAL_HEADER="  Optional modules:"
  MSG_MOD_1="    [1] code-review skill  — PR/quality review"
  MSG_MOD_2="    [2] testing skill      — TDD enforcement"
  MSG_MOD_3="    [3] Context7 MCP       — latest library docs auto-injection"
  MSG_MOD_4="    [4] Sequential Thinking MCP — structured reasoning chains"
  MSG_MOD_5="    [5] Knowledge Wiki     — LLM Wiki pattern (docs/sources + docs/wiki + ingest/lint skills)"
  MSG_MOD_6="    [6] Browser Automation — agent-browser CLI (Vercel Labs, accessibility-tree snapshots)"
  MSG_MOD_7="    [7] Code Review Graph  — local code knowledge graph + blast-radius analysis (8.2x token saving)"
  MSG_MOD_SELECT_PROMPT="  Select [1-7, comma-separated, 'all', or 'none', default: none]: "
  MSG_MOD_SKIP_CODE_REVIEW="  Skipping: code-review skill"
  MSG_MOD_INC_CODE_REVIEW="  Including: code-review skill"
  MSG_MOD_SKIP_TESTING="  Skipping: testing skill"
  MSG_MOD_INC_TESTING="  Including: testing skill"
  MSG_MOD_SKIP_KNOWLEDGE_WIKI="  Skipping: Knowledge Wiki"
  MSG_MOD_INC_KNOWLEDGE_WIKI="  Including: Knowledge Wiki (docs/sources + docs/wiki + ingest/lint skills)"
  MSG_MOD_SKIP_BROWSER="  Skipping: Browser Automation"
  MSG_MOD_INC_BROWSER="  Including: Browser Automation (agent-browser CLI)"
  MSG_MOD_BROWSER_INSTALL="  agent-browser is NOT auto-installed. Run in your terminal after setup:"
  MSG_MOD_BROWSER_CMD="    npm install -g agent-browser && agent-browser install"
  MSG_MOD_SKIP_CODE_GRAPH="  Skipping: Code Review Graph"
  MSG_MOD_INC_CODE_GRAPH="  Including: Code Review Graph (blast-radius + MCP 22 tools)"
  MSG_MOD_CODE_GRAPH_INSTALL="  code-review-graph is NOT auto-installed. Run in your terminal after setup:"
  MSG_MOD_CODE_GRAPH_CMD="    pip install code-review-graph && code-review-graph install"
  MSG_MOD_SKIP_CONTEXT7="  Skipping: Context7 MCP"
  MSG_MOD_INC_CONTEXT7="  Including: Context7 MCP"
  MSG_MOD_SKIP_SEQ_THINK="  Skipping: Sequential Thinking MCP"
  MSG_MOD_INC_SEQ_THINK="  Including: Sequential Thinking MCP"
  MSG_MOD_COUNT_SELECTED=" optional modules selected."

  # Permission section
  MSG_PERM_1="  [1] Strict  — ask before every tool use (safest)"
  MSG_PERM_2="  [2] Standard — allow read-only tools, ask for writes (recommended)"
  MSG_PERM_3="  [3] Permissive — allow most tools, ask for destructive ops only"
  MSG_PERM_SELECT_PROMPT="  Select [1-3, default: 2]: "
  MSG_PERM_LOCKED="  Permissions locked by preset: option "
  MSG_PERM_BROWSER_ADDED="  + allowed: Bash(agent-browser *)"

  # Summary labels
  MSG_SUM_HEADER_LINE="${GREEN}========================================${NC}"
  MSG_SUM_HEADER_TEXT="${GREEN}  Setup complete!${NC}"
  MSG_SUM_PROJECT="  Project:    "
  MSG_SUM_TARGET="  Target:     "
  MSG_SUM_PRESET="  Preset:     "
  MSG_SUM_STACK="  Stack:      "
  MSG_SUM_LANGUAGE="  Language:   "
  MSG_SUM_PERMS="  Permissions:"
  MSG_SUM_AGENTS="  Agents:      3 (orchestrator, executor, quality)"
  MSG_SUM_SKILLS="  Skills:     "
  MSG_SUM_MCP="  MCP:        "
  MSG_SUM_HOOKS="  Hooks:       6 (SessionStart, PreCompact, PreToolUse, TddGuard, PostToolUse, SessionEnd)"
  MSG_SUM_TASKS_NOTE="  Note: tasks/ files are local working memory (gitignored by default)."

  # Next steps
  MSG_NEXT_HEADER="  Next steps:"
  MSG_NEXT_2="    2. Review CLAUDE.md and customize Build & Run section"
  MSG_NEXT_3="    3. Configure tool permissions in .claude/settings.local.json"
  MSG_NEXT_4_CLAUDE="    4. Start Claude Code: claude"
  MSG_NEXT_4_CODEX="    4. Start Codex: codex"
  MSG_NEXT_5_CODEX_BOTH="    5. Start Codex: codex"
  MSG_NEXT_6_BOTH="    6. Switch between Claude and Codex in the same repo after regeneration checks"
  MSG_NEXT_OPT_HEADER="  Optional:"
  MSG_NEXT_OPT_SKILLS="    - Add domain skills to .claude/skills/"
  MSG_NEXT_OPT_REMOTE="    - Connect to remote: git remote add origin <url> && git push -u origin main"

  # MCP none label
  MSG_MCP_NONE="(none — built-in WebFetch only)"
}

load_messages_ko() {
  # Errors
  MSG_ERR_DIR_NOT_EMPTY="디렉토리가 비어있지 않습니다. 빈 폴더에서 실행하세요."
  MSG_ERR_GIT_NOT_FOUND="git이 설치되어 있지 않습니다."
  MSG_ERR_CLONE_FAILED="${RED}ERROR: 스타터 레포 클론에 실패했습니다. 네트워크 연결을 확인하세요.${NC}"
  MSG_ERR_CLAUDE_DIR_EXISTS="${RED}ERROR: .claude/ 디렉토리가 이미 존재합니다. 먼저 삭제하거나 빈 디렉토리에서 실행하세요.${NC}"
  MSG_ERR_CODEX_SCRIPT_MISSING="${RED}ERROR: 스타터에 Codex 파생 스크립트가 없습니다.${NC}"

  # Info / progress
  MSG_INFO_CLONING="mir-claude-starter 클론 중..."
  MSG_INFO_SETUP_STRUCTURE="프로젝트 구조 설정 중..."
  MSG_INFO_CLEANING="스타터 개발 전용 파일 정리 중..."
  MSG_INFO_INIT_TASKS="tasks/ 초기화 중..."
  MSG_INFO_PREP_CLAUDE_MD="CLAUDE.md 준비 중..."
  MSG_INFO_CONF_MODULES="선택 모듈 구성 중..."
  MSG_INFO_PERM_LEVEL="권한 레벨: "
  MSG_INFO_GEN_SETTINGS="settings.local.json 생성 중..."
  MSG_INFO_GEN_CODEX="Codex 파생 파일 생성 중..."
  MSG_INFO_GIT_INIT="git 레포지토리 초기화 중..."

  # Section headers
  MSG_HDR_TARGET="--- 설치 대상 ---"
  MSG_HDR_PROJECT_CONFIG="--- 프로젝트 설정 ---"
  MSG_HDR_PRESET="--- 프로젝트 프리셋 ---"
  MSG_HDR_MODULE="--- 모듈 선택 ---"
  MSG_HDR_PERM="--- 권한 레벨 ---"

  # Target section
  MSG_TARGET_INTRO="  어떤 에이전트 환경을 준비할지 선택하세요."
  MSG_TARGET_1="   [1] Claude 전용        — 스타터 원본만 설치"
  MSG_TARGET_2="   [2] Codex 전용         — Claude 원본 유지 + Codex 레이어 생성"
  MSG_TARGET_3="   [3] 둘 다              — Claude 원본 + Codex 레이어 생성"
  MSG_TARGET_SELECT_PROMPT="  선택 [1-3, 기본값: 1]: "

  # Project config prompts
  MSG_PROJECT_NAME_PROMPT="프로젝트 이름: "
  MSG_LANG_FW_PROMPT="언어/프레임워크 (예: TypeScript/Next.js): "
  MSG_PKG_MANAGER_PROMPT="패키지 매니저 (예: npm, pnpm, pip): "

  # Preset section
  MSG_PRESET_INTRO="  프리셋을 선택하면 스택, 모듈, 권한이 자동으로 설정됩니다."
  MSG_PRESET_EDIT_NOTE="  설정 후 CLAUDE.md와 .mcp.json을 직접 수정할 수 있습니다."
  MSG_PRESET_1="   [1]  Flutter 모바일 앱     (Dart, pub)          testing+code-review, Context7"
  MSG_PRESET_2="   [2]  Next.js 웹 앱          (TypeScript, pnpm)   testing+code-review, Context7+SeqThink"
  MSG_PRESET_3="   [3]  Node/TS 백엔드 API    (TypeScript, npm)    testing+code-review, SeqThink"
  MSG_PRESET_4="   [4]  Python 백엔드          (Python, uv)         testing+code-review, Context7"
  MSG_PRESET_5="   [5]  Python 데이터/ML      (Python, uv)         testing, SeqThink"
  MSG_PRESET_6="   [6]  Rust 시스템            (Rust, cargo)        testing+code-review, Strict perms"
  MSG_PRESET_7="   [7]  Go 서비스              (Go, go mod)         testing+code-review"
  MSG_PRESET_8="   [8]  임베디드 C/C++         (C/C++, cmake)       code-review only, Strict perms"
  MSG_PRESET_9="   [9]  Claude 전용 에이전트   (코드 없음, 콘텐츠)  testing 없음, SeqThink"
  MSG_PRESET_10="   [10] 정적 사이트 / 문서     (Astro/Hugo, npm)    최소 모듈"
  MSG_PRESET_11="   [11] 커스텀                 (직접 입력)"
  MSG_PRESET_SELECT_PROMPT="  선택 [1-11, 기본값: 11]: "
  MSG_PRESET_LOCKED="프리셋 적용: "
  MSG_PRESET_LOCKED_MODULES="  프리셋으로 고정된 모듈: "

  # Module section
  MSG_MOD_CORE_HEADER="  기본 포함 (항상 설치):"
  MSG_MOD_CORE_SKILLS="    ✓ 스킬 6개: brainstorming, writing-plans, verification,"
  MSG_MOD_CORE_SKILLS2="                 deep-interview, git-commit, project-doctor"
  MSG_MOD_CORE_AGENTS="    ✓ 에이전트 3개: orchestrator, executor, quality"
  MSG_MOD_CORE_HOOKS="    ✓ 훅 6개:  session-start, pre-compact, pre-tool-use, tdd-guard, post-edit-check, session-end"
  MSG_MOD_CORE_WEB="    ✓ 웹:      내장 WebFetch / WebSearch (MCP 불필요)"
  MSG_MOD_OPTIONAL_HEADER="  선택 모듈:"
  MSG_MOD_1="    [1] code-review 스킬  — PR/품질 리뷰"
  MSG_MOD_2="    [2] testing 스킬      — TDD 강제 적용"
  MSG_MOD_3="    [3] Context7 MCP       — 최신 라이브러리 문서 자동 주입"
  MSG_MOD_4="    [4] Sequential Thinking MCP — 구조화된 추론 체인"
  MSG_MOD_5="    [5] Knowledge Wiki     — LLM 위키 패턴 (docs/sources + docs/wiki + ingest/lint 스킬)"
  MSG_MOD_6="    [6] Browser Automation — agent-browser CLI (Vercel Labs, 접근성 트리 스냅샷)"
  MSG_MOD_7="    [7] Code Review Graph  — 로컬 코드 지식 그래프 + blast-radius 분석 (토큰 8.2x 절감)"
  MSG_MOD_SELECT_PROMPT="  선택 [1-7, 쉼표 구분, 'all', 'none', 기본값: none]: "
  MSG_MOD_SKIP_CODE_REVIEW="  code-review 스킬 제외"
  MSG_MOD_INC_CODE_REVIEW="  code-review 스킬 포함"
  MSG_MOD_SKIP_TESTING="  testing 스킬 제외"
  MSG_MOD_INC_TESTING="  testing 스킬 포함"
  MSG_MOD_SKIP_KNOWLEDGE_WIKI="  Knowledge Wiki 제외"
  MSG_MOD_INC_KNOWLEDGE_WIKI="  Knowledge Wiki 포함 (docs/sources + docs/wiki + ingest/lint 스킬)"
  MSG_MOD_SKIP_BROWSER="  Browser Automation 제외"
  MSG_MOD_INC_BROWSER="  Browser Automation 포함 (agent-browser CLI)"
  MSG_MOD_BROWSER_INSTALL="  agent-browser는 자동 설치되지 않습니다. 설정 후 터미널에서 실행하세요:"
  MSG_MOD_BROWSER_CMD="    npm install -g agent-browser && agent-browser install"
  MSG_MOD_SKIP_CODE_GRAPH="  Code Review Graph 제외"
  MSG_MOD_INC_CODE_GRAPH="  Code Review Graph 포함 (blast-radius + MCP 22개 도구)"
  MSG_MOD_CODE_GRAPH_INSTALL="  code-review-graph는 자동 설치되지 않습니다. 설정 후 터미널에서 실행하세요:"
  MSG_MOD_CODE_GRAPH_CMD="    pip install code-review-graph && code-review-graph install"
  MSG_MOD_SKIP_CONTEXT7="  Context7 MCP 제외"
  MSG_MOD_INC_CONTEXT7="  Context7 MCP 포함"
  MSG_MOD_SKIP_SEQ_THINK="  Sequential Thinking MCP 제외"
  MSG_MOD_INC_SEQ_THINK="  Sequential Thinking MCP 포함"
  MSG_MOD_COUNT_SELECTED="개 선택 모듈 적용."

  # Permission section
  MSG_PERM_1="  [1] Strict     — 모든 도구 사용 전 확인 (가장 안전)"
  MSG_PERM_2="  [2] Standard   — 읽기 도구 허용, 쓰기 시 확인 (권장)"
  MSG_PERM_3="  [3] Permissive — 대부분 허용, 파괴적 작업만 확인"
  MSG_PERM_SELECT_PROMPT="  선택 [1-3, 기본값: 2]: "
  MSG_PERM_LOCKED="  프리셋으로 고정된 권한: 옵션 "
  MSG_PERM_BROWSER_ADDED="  + 허용 추가: Bash(agent-browser *)"

  # Summary labels
  MSG_SUM_HEADER_LINE="${GREEN}========================================${NC}"
  MSG_SUM_HEADER_TEXT="${GREEN}  설정 완료!${NC}"
  MSG_SUM_PROJECT="  프로젝트:   "
  MSG_SUM_TARGET="  대상:       "
  MSG_SUM_PRESET="  프리셋:     "
  MSG_SUM_STACK="  스택:       "
  MSG_SUM_LANGUAGE="  출력 언어:  "
  MSG_SUM_PERMS="  권한:       "
  MSG_SUM_AGENTS="  에이전트:    3개 (orchestrator, executor, quality)"
  MSG_SUM_SKILLS="  스킬:       "
  MSG_SUM_MCP="  MCP:        "
  MSG_SUM_HOOKS="  훅:          6개 (SessionStart, PreCompact, PreToolUse, TddGuard, PostToolUse, SessionEnd)"
  MSG_SUM_TASKS_NOTE="  참고: tasks/ 파일은 로컬 작업 메모리입니다 (기본적으로 gitignore 처리)."

  # Next steps
  MSG_NEXT_HEADER="  다음 단계:"
  MSG_NEXT_2="    2. CLAUDE.md 검토 후 Build & Run 섹션 커스터마이징"
  MSG_NEXT_3="    3. .claude/settings.local.json에서 도구 권한 설정"
  MSG_NEXT_4_CLAUDE="    4. Claude Code 시작: claude"
  MSG_NEXT_4_CODEX="    4. Codex 시작: codex"
  MSG_NEXT_5_CODEX_BOTH="    5. Codex 시작: codex"
  MSG_NEXT_6_BOTH="    6. 재생성 확인 후 같은 저장소에서 Claude와 Codex를 번갈아 사용"
  MSG_NEXT_OPT_HEADER="  선택 사항:"
  MSG_NEXT_OPT_SKILLS="    - 도메인 스킬 추가: .claude/skills/"
  MSG_NEXT_OPT_REMOTE="    - 원격 연결: git remote add origin <url> && git push -u origin main"

  # MCP none label
  MSG_MCP_NONE="(없음 — 내장 WebFetch만 사용)"
}

# --- Pre-checks ---
if [ "$(ls -A 2>/dev/null | grep -v setup.sh | grep -v .DS_Store)" ]; then
  error "Directory is not empty. Run this script in an empty folder."
fi

command -v git >/dev/null 2>&1 || error "git is not installed."

# --- Language selection (bilingual prompt — we don't know the language yet) ---
echo ""
echo "  Select language / 언어를 선택하세요:"
echo "    [1] English"
echo "    [2] 한국어 (Korean)"
echo "    [3] Japanese (日本語)"
echo "    [4] Chinese (中文)"
echo "    [5] Other / 기타"
read -p "  [1-5, default: 1]: " _LANG_CHOICE

case "$_LANG_CHOICE" in
  2) USER_LANG="Korean";   load_messages_ko ;;
  3) USER_LANG="Japanese"; load_messages_en ;;
  4) USER_LANG="Chinese";  load_messages_en ;;
  5) read -p "  Enter language name / 언어 이름 입력: " USER_LANG; load_messages_en ;;
  *) USER_LANG="English";  load_messages_en ;;
esac

echo ""

# --- Target selection ---
echo -e "${YELLOW}$MSG_HDR_TARGET${NC}"
echo "$MSG_TARGET_INTRO"
echo ""
echo "$MSG_TARGET_1"
echo "$MSG_TARGET_2"
echo "$MSG_TARGET_3"
echo ""
read -p "$MSG_TARGET_SELECT_PROMPT" TARGET_CHOICE

case "${TARGET_CHOICE:-1}" in
  2) INSTALL_TARGET="codex" ;;
  3) INSTALL_TARGET="both" ;;
  *) INSTALL_TARGET="claude" ;;
esac

INCLUDE_CODEX_LAYER=0
if [ "$INSTALL_TARGET" = "codex" ] || [ "$INSTALL_TARGET" = "both" ]; then
  INCLUDE_CODEX_LAYER=1
fi

# --- Step 1: Clone ---
info "$MSG_INFO_CLONING"
git clone --depth 1 "$REPO_URL" "$STARTER_DIR" || { echo -e "$MSG_ERR_CLONE_FAILED"; exit 1; }
rm -rf "$STARTER_DIR/.git"

# --- Step 2: Move files ---
info "$MSG_INFO_SETUP_STRUCTURE"

# Guard against overwriting existing .claude/ directory
if [ -d ".claude" ]; then
  echo -e "$MSG_ERR_CLAUDE_DIR_EXISTS"
  rm -rf "$STARTER_DIR"
  exit 1
fi

mv "$STARTER_DIR"/.claude .
mv "$STARTER_DIR"/harness .
mv "$STARTER_DIR"/.gitignore .
mv "$STARTER_DIR"/CLAUDE.md .
mv "$STARTER_DIR"/execute.py .
mv "$STARTER_DIR"/LICENSE .
mv "$STARTER_DIR"/docs .
if [ "$INCLUDE_CODEX_LAYER" -eq 1 ]; then
  mv "$STARTER_DIR"/.codex-sync .
  mv "$STARTER_DIR"/scripts .
fi
# Skip README.md (user will create their own), setup.sh (this script)
# Skip .mcp.json (generated in module selection step)

rm -rf "$STARTER_DIR"

# --- Step 3: Clean starter-specific content ---
info "$MSG_INFO_CLEANING"

# Remove starter-specific docs (keep directory structure)
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

cat > PRD.md << 'EOF'
# PRD

## Purpose
- Define what the product is, who it is for, and what must ship first.
- Prevent scope drift during AI-assisted development.

## Product Summary
- Product name:
- One-line value proposition:
- Primary user:
- Primary job-to-be-done:

## UX Priorities
- Highest-priority user flow:
- What must feel fast, clear, and trustworthy:
- What user confusion is unacceptable:
- Accessibility baseline:
- Mobile/Desktop priority:

## MVP Scope
- Must have:
- Should have:
- Explicitly out of scope:

## Functional Requirements
| ID | Requirement | Why It Exists | Acceptance Signal |
|---|---|---|---|
| FR-1 |  |  |  |

## Non-Functional Requirements
| ID | Requirement | Target |
|---|---|---|
| NFR-1 | Performance |  |
| NFR-2 | Reliability |  |
| NFR-3 | Security |  |
| NFR-4 | Privacy |  |

## Edge Cases
- Empty state:
- First-run onboarding:
- Slow network:
- Offline or degraded backend:
- Partial failure:
- Permission denied:
- Duplicate submission:
- Invalid input:
- Rate limit:

## Error Handling
- User-visible errors must be actionable, short, and recovery-oriented.
- Do not expose internal stack traces or vendor-only wording in the UI.
- Define retryable vs non-retryable failures before implementation.

## Success Metrics
- Task success metric:
- UX quality metric:
- Reliability metric:

## Open Questions
- 
EOF

cat > ARCHITECTURE.md << 'EOF'
# ARCHITECTURE

## Purpose
- Define how the system is built and which implementation patterns are mandatory.

## System Shape
- Runtime(s):
- Frontend:
- Backend:
- Storage:
- External integrations:

## Directory Rules
| Area | Responsibility | Allowed Dependencies | Forbidden Dependencies |
|---|---|---|---|
| app/ |  |  |  |

## Data Flow
1. User input enters at:
2. Validation happens at:
3. Business logic happens at:
4. External API calls happen through:
5. Persistence happens at:
6. User-visible errors are mapped at:

## Hard Constraints
- Required API wrapper:
- Banned libraries:
- DB schema change policy:
- State management policy:
- Logging policy:
- Feature flag policy:

## Patterns To Use
- Preferred module structure:
- Error handling boundary:
- Async/concurrency pattern:
- Test layering:

## Patterns To Avoid
- Direct vendor SDK calls outside wrappers
- Cross-layer imports that bypass the intended boundary
- Hidden global state
- Schema changes without ADR and migration review

## Security Boundaries
- Auth/authz entry points:
- Secret handling:
- PII handling:
- Audit logging:

## Failure Modes
- Upstream timeout:
- Upstream invalid response:
- Stale cache:
- Duplicate writes:
- Partial transaction:
- Background job retry storm:

## Verification
- Required commands:
- Required tests before merge:
- Required manual checks:
EOF

cat > ADR.md << 'EOF'
# ADR

## Purpose
- Record architectural decisions in short, reviewable entries.

## Entry Template
### ADR-000
- Status: Proposed | Accepted | Superseded
- Context: What problem or constraint forced a decision?
- Decision: What was chosen?
- Why: Why this option won?
- Tradeoff: What was rejected or made harder?
- Operational Impact: Migration, testing, rollback, observability implications.

## Decision Log
### ADR-001
- Status:
- Context:
- Decision:
- Why:
- Tradeoff:
- Operational Impact:
EOF

cat > UI_GUIDE.md << 'EOF'
# UI_GUIDE

## Purpose
- Define how the product should look, feel, and communicate.
- Keep AI-generated UI aligned with the intended user experience.

## UX Principles
- Prioritize clarity over visual novelty when the two conflict.
- Every primary screen should make the next action obvious within 3 seconds.
- Error, loading, and empty states are part of the product, not polish.

## Visual Direction
- Brand adjectives:
- Typography:
- Color palette:
- Spacing system:
- Corner radius / border style:
- Motion style:

## Component Rules
- Buttons:
- Forms:
- Tables/lists:
- Modals/drawers:
- Notifications/toasts:
- Navigation:

## States Required On Every Important Screen
- Initial load
- Empty state
- Partial data
- Validation failure
- Server failure
- Slow response
- Success confirmation

## UX Anti-Patterns
- Glassmorphism by default
- Purple gradient hero text by default
- Neon glow as primary emphasis
- Placeholder copy left in production flows
- Auto-submitting destructive actions without confirmation

## Accessibility
- Minimum contrast target:
- Keyboard navigation requirement:
- Screen reader requirement:
- Focus treatment:
- Reduced motion behavior:

## Content Rules
- Tone:
- CTA style:
- Error copy style:
- Confirmation copy style:
EOF

# --- Step 4: Initialize tasks/ ---
info "$MSG_INFO_INIT_TASKS"
mkdir -p tasks/handoffs tasks/sessions tasks/log

cat > tasks/plan.md << 'EOF'
# Plan

## Current State
- Project initialized with mir-claude-starter.

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
info "$MSG_INFO_PREP_CLAUDE_MD"

# Prompt user for project info
echo ""
echo -e "${YELLOW}$MSG_HDR_PROJECT_CONFIG${NC}"
read -p "$MSG_PROJECT_NAME_PROMPT" PROJECT_NAME

# --- Preset Selection ---
echo ""
echo -e "${YELLOW}$MSG_HDR_PRESET${NC}"
echo "$MSG_PRESET_INTRO"
echo "$MSG_PRESET_EDIT_NOTE"
echo ""
echo "$MSG_PRESET_1"
echo "$MSG_PRESET_2"
echo "$MSG_PRESET_3"
echo "$MSG_PRESET_4"
echo "$MSG_PRESET_5"
echo "$MSG_PRESET_6"
echo "$MSG_PRESET_7"
echo "$MSG_PRESET_8"
echo "$MSG_PRESET_9"
echo "$MSG_PRESET_10"
echo "$MSG_PRESET_11"
echo ""
read -p "$MSG_PRESET_SELECT_PROMPT" PRESET_CHOICE

PRESET_NAME=""
PRESET_LOCKED=0
case "$PRESET_CHOICE" in
  1)  PRESET_NAME="Flutter Mobile App";   LANG_FRAMEWORK="Dart/Flutter";       PKG_MANAGER="pub";    MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  2)  PRESET_NAME="Next.js Web App";      LANG_FRAMEWORK="TypeScript/Next.js"; PKG_MANAGER="pnpm";   MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=1; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  3)  PRESET_NAME="Node/TS Backend API";  LANG_FRAMEWORK="TypeScript/Node.js"; PKG_MANAGER="npm";    MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  4)  PRESET_NAME="Python Backend";       LANG_FRAMEWORK="Python/FastAPI";     PKG_MANAGER="uv";     MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  5)  PRESET_NAME="Python Data/ML";       LANG_FRAMEWORK="Python/ML";          PKG_MANAGER="uv";     MOD_CODE_REVIEW=0; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; MOD_KNOWLEDGE_WIKI=1; MOD_BROWSER=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  6)  PRESET_NAME="Rust Systems";         LANG_FRAMEWORK="Rust";               PKG_MANAGER="cargo";  MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; PERM_PRESET=1; PRESET_LOCKED=1 ;;
  7)  PRESET_NAME="Go Service";           LANG_FRAMEWORK="Go";                 PKG_MANAGER="go mod"; MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  8)  PRESET_NAME="Embedded C/C++";       LANG_FRAMEWORK="C/C++";              PKG_MANAGER="cmake";  MOD_CODE_REVIEW=1; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; PERM_PRESET=1; PRESET_LOCKED=1 ;;
  9)  PRESET_NAME="Claude-only Agent";    LANG_FRAMEWORK="Claude (no code)";   PKG_MANAGER="n/a";    MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=1; MOD_KNOWLEDGE_WIKI=1; MOD_BROWSER=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  10) PRESET_NAME="Static Site / Docs";   LANG_FRAMEWORK="Astro or Hugo";      PKG_MANAGER="npm";    MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=1; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=1; PERM_PRESET=2; PRESET_LOCKED=1 ;;
  *)  PRESET_NAME="Custom"; PRESET_LOCKED=0 ;;
esac

if [ "$PRESET_LOCKED" -eq 1 ]; then
  info "$MSG_PRESET_LOCKED$PRESET_NAME → $LANG_FRAMEWORK ($PKG_MANAGER)"
else
  read -p "$MSG_LANG_FW_PROMPT" LANG_FRAMEWORK
  read -p "$MSG_PKG_MANAGER_PROMPT" PKG_MANAGER
fi

# Update CLAUDE.md (use perl to avoid sed delimiter issues with user input)
if [ -n "$PROJECT_NAME" ]; then
  P="$PROJECT_NAME" perl -pi -e 's/mir-claude-starter — Opinionated Claude Code Starter/$ENV{P} — Opinionated Claude Code Starter/' CLAUDE.md
fi
if [ -n "$LANG_FRAMEWORK" ]; then
  P="$LANG_FRAMEWORK" perl -pi -e 's/\| Language\/Framework \| TBD \(Claude Code starter\) \|/| Language\/Framework | $ENV{P} |/' CLAUDE.md
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
info "$MSG_INFO_CONF_MODULES"
echo ""
echo -e "${YELLOW}$MSG_HDR_MODULE${NC}"
echo ""
echo "$MSG_MOD_CORE_HEADER"
echo "$MSG_MOD_CORE_SKILLS"
echo "$MSG_MOD_CORE_SKILLS2"
echo "$MSG_MOD_CORE_AGENTS"
echo "$MSG_MOD_CORE_HOOKS"
echo "$MSG_MOD_CORE_WEB"
echo ""
echo "$MSG_MOD_OPTIONAL_HEADER"
echo "$MSG_MOD_1"
echo "$MSG_MOD_2"
echo "$MSG_MOD_3"
echo "$MSG_MOD_4"
echo "$MSG_MOD_5"
echo "$MSG_MOD_6"
echo "$MSG_MOD_7"
echo ""
if [ "$PRESET_LOCKED" -eq 1 ]; then
  MODULE_CHOICE="__preset__"
  info "$MSG_PRESET_LOCKED_MODULES""code-review=$MOD_CODE_REVIEW testing=$MOD_TESTING context7=$MOD_CONTEXT7 seq-think=$MOD_SEQ_THINK knowledge-wiki=$MOD_KNOWLEDGE_WIKI browser=$MOD_BROWSER"
else
  read -p "$MSG_MOD_SELECT_PROMPT" MODULE_CHOICE
fi

# Parse selection
if [ "$MODULE_CHOICE" = "__preset__" ]; then
  : # already set by preset
elif [ -z "$MODULE_CHOICE" ] || [ "$MODULE_CHOICE" = "none" ]; then
  MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; MOD_CODE_GRAPH=0
elif [ "$MODULE_CHOICE" = "all" ]; then
  MOD_CODE_REVIEW=1; MOD_TESTING=1; MOD_CONTEXT7=1; MOD_SEQ_THINK=1; MOD_KNOWLEDGE_WIKI=1; MOD_BROWSER=1; MOD_CODE_GRAPH=1
else
  MOD_CODE_REVIEW=0; MOD_TESTING=0; MOD_CONTEXT7=0; MOD_SEQ_THINK=0; MOD_KNOWLEDGE_WIKI=0; MOD_BROWSER=0; MOD_CODE_GRAPH=0
  IFS=',' read -ra MODS <<< "$MODULE_CHOICE"
  for m in "${MODS[@]}"; do
    m=$(echo "$m" | tr -d ' ')
    case "$m" in
      1) MOD_CODE_REVIEW=1 ;;
      2) MOD_TESTING=1 ;;
      3) MOD_CONTEXT7=1 ;;
      4) MOD_SEQ_THINK=1 ;;
      5) MOD_KNOWLEDGE_WIKI=1 ;;
      6) MOD_BROWSER=1 ;;
      7) MOD_CODE_GRAPH=1 ;;
    esac
  done
fi
MOD_KNOWLEDGE_WIKI=${MOD_KNOWLEDGE_WIKI:-0}
MOD_BROWSER=${MOD_BROWSER:-0}
MOD_CODE_GRAPH=${MOD_CODE_GRAPH:-0}

# Remove unselected optional skills + update CLAUDE.md references
if [ "$MOD_CODE_REVIEW" -eq 0 ]; then
  info "$MSG_MOD_SKIP_CODE_REVIEW"
  rm -rf .claude/skills/code-review
  rm -f docs/integrations/codex-code-review.md
  perl -ni -e 'print unless /code-review.*SKILL\.md/' CLAUDE.md
  perl -pi -e 's/ → code-review//g' CLAUDE.md
  perl -ni -e 'print unless /\| code-review /' docs/memory-map.md
else
  info "$MSG_MOD_INC_CODE_REVIEW"
fi

if [ "$MOD_TESTING" -eq 0 ]; then
  info "$MSG_MOD_SKIP_TESTING"
  rm -rf .claude/skills/testing
  rm -f docs/integrations/computer-use-gui-testing.md
  perl -ni -e 'print unless /\| test, TDD.*testing/' CLAUDE.md
  perl -pi -e 's/ → testing//g' CLAUDE.md
  perl -ni -e 'print unless /\| testing /' docs/memory-map.md
else
  info "$MSG_MOD_INC_TESTING"
fi

if [ "$MOD_KNOWLEDGE_WIKI" -eq 0 ]; then
  info "$MSG_MOD_SKIP_KNOWLEDGE_WIKI"
  rm -rf .claude/skills/knowledge-ingest
  rm -rf .claude/skills/knowledge-lint
else
  info "$MSG_MOD_INC_KNOWLEDGE_WIKI"
  mkdir -p docs/sources docs/wiki
  cat > docs/sources/index.md << 'WIKIEOF'
---
title: Sources Index — LLM Wiki Raw Archive
keywords: [sources, index, wiki, ingest]
created: SETUP_DATE
last_used: SETUP_DATE
type: index
---

# Sources Index

> Raw, immutable. Edit only by appending rows. Files in this directory must never be modified after ingest.

| Date | Slug | 1-line Summary | Pages Touched |
|---|---|---|---|
| | | | |
WIKIEOF
  cat > docs/sources/log.md << 'WIKIEOF'
# Ingest Log

> Append-only. Parseable prefix: `INGEST {YYYY-MM-DD} {slug} → [pages]`.

WIKIEOF
  cat > docs/wiki/README.md << 'WIKIEOF'
---
title: Wiki Root
keywords: [wiki, root]
created: SETUP_DATE
last_used: SETUP_DATE
---

# Wiki

LLM-maintained knowledge pages derived from `docs/sources/`. Each page ≤50 lines. Every claim cites a source.

Lint with the `knowledge-lint` skill. Ingest new material with the `knowledge-ingest` skill.
WIKIEOF
  SETUP_DATE=$(date +%Y-%m-%d) perl -pi -e 's/SETUP_DATE/$ENV{SETUP_DATE}/g' docs/sources/index.md docs/wiki/README.md
fi

if [ "$MOD_BROWSER" -eq 0 ]; then
  info "$MSG_MOD_SKIP_BROWSER"
  rm -rf .claude/skills/browser-automation
else
  info "$MSG_MOD_INC_BROWSER"
  warn "$MSG_MOD_BROWSER_INSTALL"
  warn "$MSG_MOD_BROWSER_CMD"
fi

if [ "$MOD_CODE_GRAPH" -eq 0 ]; then
  info "$MSG_MOD_SKIP_CODE_GRAPH"
  rm -rf .claude/skills/code-review-graph
else
  info "$MSG_MOD_INC_CODE_GRAPH"
  # Ensure .code-review-graph/ is gitignored
  grep -qxF ".code-review-graph/" .gitignore 2>/dev/null || echo ".code-review-graph/" >> .gitignore
  warn "$MSG_MOD_CODE_GRAPH_INSTALL"
  warn "$MSG_MOD_CODE_GRAPH_CMD"
fi

# Build .mcp.json dynamically
# Note: web access is handled by Claude Code's built-in WebFetch tool — no MCP server needed.
MCP_JSON='{\n  "mcpServers": {'
MCP_FIRST=1

if [ "$MOD_CONTEXT7" -eq 1 ]; then
  info "$MSG_MOD_INC_CONTEXT7"
  [ "$MCP_FIRST" -eq 0 ] && MCP_JSON="$MCP_JSON"','
  MCP_JSON="$MCP_JSON"'\n    "context7": {\n      "command": "npx",\n      "args": ["-y", "@upstash/context7-mcp@latest"]\n    }'
  MCP_FIRST=0
else
  info "$MSG_MOD_SKIP_CONTEXT7"
fi

if [ "$MOD_SEQ_THINK" -eq 1 ]; then
  info "$MSG_MOD_INC_SEQ_THINK"
  [ "$MCP_FIRST" -eq 0 ] && MCP_JSON="$MCP_JSON"','
  MCP_JSON="$MCP_JSON"'\n    "sequential-thinking": {\n      "command": "npx",\n      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]\n    }'
  MCP_FIRST=0
else
  info "$MSG_MOD_SKIP_SEQ_THINK"
fi

MCP_JSON="$MCP_JSON"'\n  }\n}'
echo -e "$MCP_JSON" > .mcp.json

# Count selected modules
SELECTED_COUNT=0
[ "$MOD_CODE_REVIEW" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_TESTING" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_CONTEXT7" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_SEQ_THINK" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_KNOWLEDGE_WIKI" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_BROWSER" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))
[ "$MOD_CODE_GRAPH" -eq 1 ] && SELECTED_COUNT=$((SELECTED_COUNT + 1))

echo ""
info "${SELECTED_COUNT}/7 $MSG_MOD_COUNT_SELECTED"

# --- Step 6: Permissions + settings.local.json ---
echo ""
echo -e "${YELLOW}$MSG_HDR_PERM${NC}"
echo ""
echo "$MSG_PERM_1"
echo "$MSG_PERM_2"
echo "$MSG_PERM_3"
echo ""
if [ "$PRESET_LOCKED" -eq 1 ]; then
  PERM_CHOICE="$PERM_PRESET"
  info "$MSG_PERM_LOCKED$PERM_CHOICE"
else
  read -p "$MSG_PERM_SELECT_PROMPT" PERM_CHOICE
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

info "$MSG_INFO_PERM_LEVEL$PERM_LEVEL"

# Inject agent-browser allow entry if Browser Automation module is enabled
if [ "$MOD_BROWSER" -eq 1 ] && [ "$PERM_LEVEL" != "permissive" ]; then
  if [ "$PERM_ALLOW" = "[]" ]; then
    PERM_ALLOW='["Bash(agent-browser *)"]'
  else
    PERM_ALLOW="${PERM_ALLOW%]}, \"Bash(agent-browser *)\"]"
  fi
  info "$MSG_PERM_BROWSER_ADDED"
fi

info "$MSG_INFO_GEN_SETTINGS"
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
    "PreToolUse": [
      {
        "matcher": "Bash|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/pre-tool-use.sh\"",
            "timeout": 5,
            "statusMessage": "Input-stage guardrail..."
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"\$CLAUDE_PROJECT_DIR/.claude/hooks/tdd-guard.sh\"",
            "timeout": 10,
            "statusMessage": "Checking related tests..."
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

if [ "$INCLUDE_CODEX_LAYER" -eq 1 ]; then
  info "$MSG_INFO_GEN_CODEX"
  if [ ! -f "scripts/generate_codex_derivatives.sh" ]; then
    echo -e "$MSG_ERR_CODEX_SCRIPT_MISSING"
    exit 1
  fi
  CODEX_DERIVATION_PROFILE=core bash scripts/generate_codex_derivatives.sh
fi

# --- Step 7: Git init ---
info "$MSG_INFO_GIT_INIT"
git init -q
git add -A
git commit -q -m "feat: initialize project with mir-claude-starter"

# --- Done ---
echo ""
echo -e "$MSG_SUM_HEADER_LINE"
echo -e "$MSG_SUM_HEADER_TEXT"
echo -e "$MSG_SUM_HEADER_LINE"
echo ""
# Build skill list for summary
SKILL_LIST="brainstorming, writing-plans, verification, interview, git-commit, project-doctor, self-audit, ux-ui-design"
SKILL_COUNT=8
[ "$MOD_CODE_REVIEW" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, code-review"; SKILL_COUNT=$((SKILL_COUNT + 1)); }
[ "$MOD_TESTING" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, testing"; SKILL_COUNT=$((SKILL_COUNT + 1)); }
[ "$MOD_KNOWLEDGE_WIKI" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, knowledge-ingest, knowledge-lint"; SKILL_COUNT=$((SKILL_COUNT + 2)); }
[ "$MOD_BROWSER" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, browser-automation"; SKILL_COUNT=$((SKILL_COUNT + 1)); }
[ "$MOD_CODE_GRAPH" -eq 1 ] && { SKILL_LIST="$SKILL_LIST, code-review-graph"; SKILL_COUNT=$((SKILL_COUNT + 1)); }

# Build MCP list for summary
MCP_LIST=""
MCP_COUNT=0
[ "$MOD_CONTEXT7" -eq 1 ] && { MCP_LIST="${MCP_LIST:+$MCP_LIST, }context7"; MCP_COUNT=$((MCP_COUNT + 1)); }
[ "$MOD_SEQ_THINK" -eq 1 ] && { MCP_LIST="${MCP_LIST:+$MCP_LIST, }sequential-thinking"; MCP_COUNT=$((MCP_COUNT + 1)); }
[ "$MCP_COUNT" -eq 0 ] && MCP_LIST="$MSG_MCP_NONE"

echo "$MSG_SUM_PROJECT${PROJECT_NAME:-unnamed}"
echo "$MSG_SUM_TARGET${INSTALL_TARGET}"
echo "$MSG_SUM_PRESET${PRESET_NAME}"
echo "$MSG_SUM_STACK${LANG_FRAMEWORK} (${PKG_MANAGER})"
echo "$MSG_SUM_LANGUAGE${USER_LANG}"
echo "$MSG_SUM_PERMS${PERM_LEVEL}"
echo "$MSG_SUM_AGENTS"
echo "$MSG_SUM_SKILLS${SKILL_COUNT} (${SKILL_LIST})"
echo "$MSG_SUM_MCP${MCP_COUNT} (${MCP_LIST})"
echo "$MSG_SUM_HOOKS"
echo ""
echo "$MSG_SUM_TASKS_NOTE"
echo ""
echo "$MSG_NEXT_HEADER"
echo "    1. cd $(pwd)"
echo "$MSG_NEXT_2"
echo "$MSG_NEXT_3"
if [ "$INSTALL_TARGET" = "claude" ]; then
  echo "$MSG_NEXT_4_CLAUDE"
elif [ "$INSTALL_TARGET" = "codex" ]; then
  echo "$MSG_NEXT_4_CODEX"
else
  echo "$MSG_NEXT_4_CLAUDE"
  echo "$MSG_NEXT_5_CODEX_BOTH"
  echo "$MSG_NEXT_6_BOTH"
fi
echo ""
echo "$MSG_NEXT_OPT_HEADER"
echo "$MSG_NEXT_OPT_SKILLS"
echo "$MSG_NEXT_OPT_REMOTE"
echo ""
