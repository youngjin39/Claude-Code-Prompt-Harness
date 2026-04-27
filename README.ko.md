# Mir Claude Starter

Claude Code 스타터 — 원커맨드로 3개 에이전트, 14개 스킬, 6개 훅, 3계층 메모리, `execute.py` 상태 엔진, 게이트 파이프라인을 새 프로젝트에 설치. 24라운드 무결성 감사(30개 fix)로 튜닝됨.

> **[English README](README.md)**

## 포지셔닝

이 프로젝트는 **스타터**이며 완전한 하네스가 아닙니다. 진짜 하네스는 규칙을 **구조적으로 강제**합니다 — 금지 경로 차단, 런타임 상태 파일(`state/current-task.json`), 빌드를 실패시키는 아키텍처 테스트. 이 스타터는 AI 엔지니어링 3단계 중 1~2단계는 완전히, 3단계는 부분적으로 커버합니다:

| 단계 | 커버리지 |
|---|---|
| 1. 프롬프트 엔지니어링 — 질문을 잘 던지기 | ✅ 스킬 + 4종 트리거 시스템 |
| 2. 맥락 엔지니어링 — 데이터를 잘 떠먹이기 | ✅ 3계층 메모리 + JIT 키워드 인덱스 |
| 3. 하네스 엔지니어링 — 구조적 강제 | ⚠️ 부분 (6개 훅, soft gate, 상태 엔진; 완전 강제는 로드맵) |

완전한 하네스는 별도 프로젝트로 추적합니다. 이 스타터로 프로젝트를 부트스트랩하고, 프로젝트가 요구하면 진짜 하네스로 그래듀에이트하세요.
핵심 계약은 AI 자기인식에 맞춰져 있습니다. 항상 읽는 문서만으로도 에이전트가 지금 어떤 런타임에 있는지, 어떤 모드인지, 무엇이 정책을 강제하는지, 무엇이 완료 증거인지 파악할 수 있어야 합니다.

## 빠른 시작

```bash
# 빈 프로젝트 디렉토리에서 실행
bash <(curl -fsSL https://raw.githubusercontent.com/youngjin39/mir-claude-starter/main/setup.sh)
```

설치 과정에서 다음을 설정합니다:

| 단계 | 내용 |
|---|---|
| 프로젝트 정보 | 이름, 언어/프레임워크, 패키지 매니저 |
| 프리셋 | 10개 스택 프리셋 또는 Custom (스택+모듈+권한 자동 설정) |
| 출력 언어 | 한국어, 영어, 일본어, 중국어, 기타 |
| 모듈 선택 | 선택적 스킬 및 MCP 서버 선택, Custom 설치의 기본값은 코어만 사용 (프리셋 선택 시 스킵) |
| 권한 수준 | Strict / Standard / Permissive (프리셋 선택 시 스킵) |

### 프로젝트 프리셋

| # | 프리셋 | 스택 | 자동 설정 |
|---|---|---|---|
| 1 | Flutter 모바일 앱 | Dart/Flutter, pub | testing+code-review, Context7 |
| 2 | Next.js 웹 앱 | TypeScript/Next.js, pnpm | testing+code-review, Context7+SeqThink |
| 3 | Node/TS 백엔드 API | TypeScript/Node, npm | testing+code-review, SeqThink |
| 4 | Python 백엔드 | Python/FastAPI, uv | testing+code-review, Context7 |
| 5 | Python 데이터/ML | Python, uv | testing, SeqThink |
| 6 | Rust 시스템 | Rust, cargo | testing+code-review, Strict 권한 |
| 7 | Go 서비스 | Go, go mod | testing+code-review |
| 8 | 임베디드 C/C++ | C/C++, cmake | code-review만, Strict 권한 |
| 9 | Claude 전용 에이전트 | 코드 없음, 콘텐츠/판단 | testing 제외, SeqThink |
| 10 | 정적 사이트/문서 | Astro/Hugo, npm | 최소 모듈 |
| 11 | Custom | 수동 입력 | (기존 동작) |

설치 후 `claude` 명령으로 시작하면 스타터 파이프라인이 자동으로 작동합니다.

### Codex 파생 레이어

이 스타터에는 `Claude`를 원본으로 유지하고 `Codex` 산출물을 단방향으로 파생시키기 위한 `.codex-sync/` 레이어가 포함됩니다.

| 자산 | 목적 |
|---|---|
| `.codex-sync/manifest.template.json` | 변경 인지용 source-to-target 매핑 |
| `.codex-sync/manifest.json` | 현재 저장소 기준으로 생성된 source-to-target 매핑 |
| `.codex-sync/rollout-checklist.md` | 여러 저장소에 같은 전략을 반복 적용하기 위한 체크리스트 |
| `docs/integrations/claude-to-codex-derivation.md` | 단방향 파생 운영 전략 |
| `docs/patterns/one-way-sync-manifest.md` | drift 탐지와 유지보수 패턴 |

이 구조는 양방향 동기화가 아닙니다. Claude 파일을 먼저 수정하고, Codex 파일은 이후 재생성하는 방식입니다.
이 스타터에서 Codex parity는 manual compliance와 verifier-checked contract drift 수준으로 문서화되어 있습니다. native pre-execution blocking이나 behavioral parity를 주장하지는 않습니다.

Codex 파생 레이어 생성:

```bash
python3 scripts/verify_starter_integrity.py
bash scripts/generate_codex_derivatives.sh
python3 scripts/verify_codex_sync.py
```

기본 파생 프로필은 `core`이며, Codex 출력 크기를 줄이고 핵심 워크플로 스킬만 유지합니다. 생성된 Codex 설정과 agent 파일은 모델을 고정하지 않아서 Codex의 현재 default 선택을 그대로 사용합니다. 더 넓은 이식 스킬 세트가 필요하면 `CODEX_DERIVATION_PROFILE=full`을 사용하세요.

현재 도구 세션이 `.codex/`나 `.agents/` 같은 숨김 대상 디렉터리를 보호한다면 staging 경로로 먼저 생성할 수 있습니다:

```bash
CODEX_DERIVATION_OUTPUT_ROOT=.codex-sync/staging bash scripts/generate_codex_derivatives.sh
```

스타터 전반을 손본 뒤에는 `python3 scripts/verify_starter_integrity.py`를 먼저 실행하세요. 재생성 후에는 `python3 scripts/verify_codex_sync.py`를 실행해서 manifest 타깃 누락, checked-in skill set 드리프트, generator 출력과 문서 간 불일치를 바로 잡으세요.

### 사전 요구사항

- [Claude Code](https://claude.com/claude-code) CLI
- `git`
- `jq` (macOS 기본 포함, Linux: `apt-get install jq`)

## 아키텍처

### 3축 설계

```
                    ┌─────────────────────┐
                    │   워크플로우          │
                    │  (작업 수행 방식)     │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                                  │
   ┌──────────▼──────────┐           ┌──────────▼──────────┐
   │  메모리 효율          │           │  컨텍스트 효율       │
   │  (무엇을 기억할 것인가)│           │  (무엇을 로드할 것인가)│
   └─────────────────────┘           └─────────────────────┘
```

### 워크플로우 파이프라인

```
요청 → 구체성 신호? → 없음 → deep-interview → 분류
  ├─ 단순 (1~2단계) → 오케스트레이터 직접 실행 → 셀프체크 → 완료
  └─ 복잡 (3단계+) → 파이프라인 선택
       설계 분기 / 새 기능 / 아키텍처 변경
         → brainstorming → writing-plans → executor-agent → verification → 완료
       범위가 명확하고 경로가 자명한 실행 작업
         → writing-plans → executor-agent → verification → 완료
```

### 오케스트레이션 프리셋

| 프리셋 | 파이프라인 |
|---|---|
| feature | brainstorming → writing-plans → executor → testing → code-review → verification |
| bugfix | deep-interview(lite) → executor → testing → verification |
| refactor | brainstorming → writing-plans → executor → code-review → verification |
| security | code-review(security) → executor → verification |

## 구성 요소

### 에이전트 (3개)

| 에이전트 | 모델 | 역할 |
|---|---|---|
| main-orchestrator | opus | 대화, 판단, 작업 분류, 단순 작업 직접 실행, 스타터 유지보수 조정 |
| executor-agent | sonnet | 복잡한 작업 전용 코드 작성과 스타터 계약 갱신 수행 |
| quality-agent | sonnet | 읽기 전용 적대적 리뷰와 스타터 드리프트 점검 (Write/Edit 금지) |

quality-agent는 **적대적 렌즈**를 사용합니다: executor가 놓친 것을 찾는 것이 역할이며, 확인이 아니라 의심합니다.

스타터 자체를 수정할 때는 에이전트, 훅, 스킬, 스크립트, 생성된 Codex 산출물, 사용자 문서를 하나의 계약으로 취급하세요. 스타터 갱신 완료를 주장하기 전 `python3 scripts/verify_starter_integrity.py`를 실행해야 합니다.
이 계약은 사람 설명용만이 아닙니다. 에이전트가 처음 읽는 파일만으로 자신의 런타임과 게이트를 분류할 수 있게 쓰여야 합니다.

### 스킬 (10개 코어 + 선택형 확장)

**코어** (항상 설치):

| 스킬 | 트리거 | 핵심 기능 |
|---|---|---|
| brainstorming | 설계, 아키텍처, 새 기능 | Hard Gate. 2~3개 다른 관점의 대안. 반대 서사 공격. 합성 옵션. |
| writing-plans | 계획, 구현 계획 | 구체적 코드 포함 필수. 금지: "테스트 추가", "필요시 리팩터링". |
| verification | 검증, 완료 확인 | 6단계 게이트 + Red Team 6Q 자가 공격 + 숨은 전제 심문. |
| deep-interview | 인터뷰, 요구사항, 명확화 | 모호성 점수 + 병목 진단 (팩트/논리/편향/실행). |
| testing | 테스트, TDD, 단위 테스트 | 테스트 탐지, 신규 테스트 작성, 실행, 엣지케이스 점검. |
| code-review | 리뷰, PR, 품질 | 정확한 근거를 포함한 severity 기반 리뷰. |
| ux-ui-design | ui, ux, screen, frontend | 구현 전 플로우 + 와이어프레임 + 컴포넌트 명세를 강제하는 UI 하드 게이트. |
| git-commit | 커밋, git, 변경 저장 | 구조화된 커밋 규칙 + 트레일러. |
| project-doctor | 진단, 헬스체크 | 구조 + 메모리 + 컨텍스트 진단. |
| self-audit | audit, integrity, drift | 스타터 준수성과 drift 점검. 스타터 검증이 여기에 의존하므로 코어로 유지합니다. |

**선택** (설치 시 opt-in, Custom 설치 기본값은 none):

| 스킬 | 트리거 | 선택인 이유 |
|---|---|---|
| knowledge-ingest / knowledge-lint | wiki, source ingest | LLM 위키를 운영하는 프로젝트에만 필요합니다. |
| browser-automation | browser, GUI, screenshots | UI/브라우저 중심 프로젝트에만 필요합니다. |
| code-review-graph | blast radius, graph review | 로컬 그래프 도구를 설치한 경우에만 유용합니다. |

### MCP 서버

| 서버 | 역할 | 코어/선택 |
|---|---|---|
| Context7 | 라이브러리 최신 문서 자동 주입 | 선택 |
| Sequential Thinking | 구조화된 추론 체인 | 선택 |

### 훅 (6개)

| 훅 | 이벤트 | 동작 |
|---|---|---|
| session-start.sh | SessionStart | plan.md + lessons.md + memory-map.md + 최근 세션 자동 주입 |
| pre-compact.sh | PreCompact | /compact 전 핸드오프 스켈레톤 자동 생성 (advisory; 에이전트가 직접 완성해야 함) |
| pre-tool-use.sh | PreToolUse (Bash\|Edit\|Write) | 입력 단계 가드레일: 파괴적 패턴 + 금지 경로 사전 차단 |
| tdd-guard.sh | PreToolUse (Edit\|Write) | 관련 테스트가 없는 기존 구현 파일 수정 차단 |
| post-edit-check.sh | PostToolUse (Edit\|Write) | 디버그 구문 + 자격증명 유출 탐지 |
| session-end.sh | SessionEnd | 세션 스냅샷 자동 저장 + 메모리 하베스팅 리마인더 |

반복 가드 실패는 `execute.py record-incident`로 추적되어, 별도 데몬 없이도 60초 / 5회 기준의 circuit breaker 경고를 제공합니다.

### 에러 분류 + 출력 파싱 복구

모든 실패는 4가지 클래스로 분류 — 대응은 에러 메시지가 아니라 클래스가 결정:

| 클래스 | 대응 |
|---|---|
| transient | 지수 백오프 (1s → 4s → 10s), 최대 3회 재시도 |
| model-fixable | 에러를 관찰값으로 재전달, 호출 수정, 최대 3회 |
| interrupt | STOP, 사용자 에스컬레이션 (파괴적/모호/범위 확장) |
| unknown | lessons.md 기록, STOP, 즉흥 금지 |

파싱 실패는 partial-extract → feedback 라운드 → unknown 승격 순서. "기본값 가정", "동일 프롬프트 재시도"는 금지.

### 4종 스킬 트리거 시스템

| 유형 | 발동 방식 | 예시 |
|---|---|---|
| 키워드 | 요청에 키워드 포함 | "테스트" → testing 스킬 |
| 의도 | 추론된 사용자 목표 | "기능 추가" → brainstorming |
| 파일 경로 | 변경된 파일 패턴 매칭 | `*.test.*` → testing |
| 코드 패턴 | 위험 패턴 감지 | 외부 입력 처리 → 보안 리뷰 |

## 메모리 시스템 (3계층)

| 계층 | 위치 | 목적 | 수명 |
|---|---|---|---|
| 프로젝트 지식 | `docs/` | 장기 메모리, 소멸 없음 | 영구. 키워드 인덱스. 파일당 50줄 제한. |
| 행동 규칙 | `tasks/lessons.md` | 실패/성공 → 규칙 | 2회 반복 시 규칙으로 승격. |
| 세션 복원 | `tasks/sessions/` | 임시 스냅샷 | 최신 1개만 유효. 이전 것은 승격 또는 삭제. |

**프로토콜**: 작업 시작 시 키워드 인덱스 스캔 → 매칭 파일만 로드 → 매칭 없으면 스킵(토큰 절약). 작업 완료 시 새로운 학습 수확.

## 원칙

모든 에이전트 행동을 지배하는 최상위 규칙:

1. **기본값은 무행동.** 증거 없이 행동하지 마라. 미검증 결론은 무효.
2. **금지 > 지시.** 행동을 정의할 때 금지 사항을 먼저 명시하라.
3. **채움말 금지.** 모든 문장이 정보를 담아야 한다. 동어 반복, 미사여구, 패딩 금지.
4. **단순함 우선.** 최소 영향. 근본 원인 해결.

## 내장 프롬프트 기법

학술 프롬프트 기법을 구조적으로 통합했습니다:

| 기법 | 적용 위치 |
|---|---|
| Tree of Thoughts | brainstorming: 다른 관점의 2~3개 대안 |
| Graph of Thoughts | brainstorming: 여러 대안의 장점 합성 |
| Contrastive CoT | brainstorming: 매력적인 오답 반대 서사 공격 |
| Maieutic Prompting | verification: 숨은 전제 심문 (Red Team Q6) |
| Self-Refinement | verification: 6단계 게이트 후 Red Team 6Q 자가 공격 |
| Skeleton-of-Thought | 전 스킬: 구조화된 Output Format 템플릿 |
| Plan-and-Solve | 파이프라인 아키텍처: 프리셋 기반 작업 흐름 |
| Reflexion | lessons.md: 실패 기억 + 3회 실패 서킷 브레이커 |
| Chain of Density | 원칙: 채움말 금지 규칙으로 정보 밀도 강제 |
| S2A (Fact-First) | "코드 먼저 읽고 분석" 규칙 |

## 설치 옵션

### 권한 수준

| 수준 | 자동 허용 | 적합한 상황 |
|---|---|---|
| Strict | 없음 — 모든 도구 사용 시 확인 | 최대 안전, Claude Code 학습 중 |
| Standard | Read, Glob, Grep, Agent, Skill | 일상 개발 (추천) |
| Permissive | Bash, Write, Edit 포함 전체 | 숙련 사용자, 신뢰 환경 |

### 모듈 선택

설치 시 선택적 모듈을 포함/제외할 수 있습니다:

```
Optional modules:
  [1] code-review skill  — PR/품질 리뷰
  [2] testing skill      — TDD 강제
  [3] Context7 MCP       — 라이브러리 최신 문서 자동 주입
  [4] Sequential Thinking MCP — 구조화된 추론 체인

Select [1-4, comma-separated, 'all', or 'none', default: none]:
```

미선택 모듈은 설치 시 제거됩니다 — 죽은 컨텍스트 없음, 토큰 낭비 없음.

## 커스텀 하네스 문서

이 스타터는 프로젝트 레벨 하네스 문서 4개를 함께 제공합니다. 본격 구현 전에 먼저 채우는 것을 권장합니다.

- `PRD.md` — 범위, MVP 경계, UX 우선순위, 엣지 케이스, 에러 처리 기대치
- `ARCHITECTURE.md` — 허용 패턴, 래퍼, 경계, 실패 모드, 검증 규칙
- `ADR.md` — 왜 이런 선택을 했는지 남기는 짧은 의사결정 로그
- `UI_GUIDE.md` — 비주얼 방향, UX 규칙, 접근성, 안티패턴

예를 들어 "이 프로젝트의 API 호출은 반드시 래퍼를 통해야 한다", "DB 스키마는 고정이라 변경 금지", "외부 상태관리 라이브러리 금지" 같은 규칙은 여기에 하드 룰로 적어야 합니다.

## 프로젝트 구조

```
.
├── CLAUDE.md                    # 항상 읽히는 최소 Claude 런타임 헌장
├── AGENTS.md                    # 항상 읽히는 최소 Codex 런타임 헌장
├── .mcp.json                    # MCP 서버 (동적 생성)
├── execute.py                   # 하네스 상태 엔진 + 선택적 자동 커밋
├── harness/
│   ├── README.md                # 하네스 런타임 가이드
│   └── state/                   # 로컬 런타임 상태 (생성 파일)
├── .codex-sync/                 # 단방향 Claude -> Codex 파생 메타데이터
├── .codex/                      # 생성된 Codex 설정 + 커스텀 에이전트
├── .agents/                     # 생성된 Codex 스킬
├── PRD.md                       # 제품 범위, MVP, UX 우선순위, 엣지 케이스
├── ARCHITECTURE.md              # 경계, 래퍼, 데이터 흐름, 실패 모드
├── ADR.md                       # 짧은 아키텍처 의사결정 로그
├── UI_GUIDE.md                  # 비주얼 시스템, UX 규칙, 안티패턴
├── scripts/
│   └── generate_codex_derivatives.sh
├── setup.sh                     # 스타터 설치기
├── .claude/
│   ├── settings.local.json      # 권한 + 훅
│   ├── agents/                  # 에이전트 3개
│   ├── hooks/                   # 자동화 훅 6개
│   └── skills/                  # 코어 6개 + 선택형 확장
├── tasks/                       # 작업 메모리 (gitignore)
│   ├── plan.md                  # 현재 계획
│   ├── context.md               # 결정 근거
│   ├── checklist.md             # 진행 추적
│   ├── change_log.md            # 변경 기록
│   ├── lessons.md               # 실패/성공 규칙
│   ├── cost-log.md              # 토큰 비용 추적
│   ├── handoffs/                # 페이즈 핸드오프 문서
│   ├── sessions/                # 세션 스냅샷
│   └── log/                     # 완료 작업 아카이브
└── docs/                        # 장기 메모리 (소멸 없음)
    ├── memory-map.md            # 키워드 인덱스
    ├── operations/              # 항상 읽히지 않아도 되는 런타임 상세 가이드
    └── {category}/              # architecture, decisions, patterns, domain, risks, integrations, references
```

## 도메인 스킬 추가

스타터 스킬은 범용, 도메인 스킬은 프로젝트 전용:

```bash
mkdir -p .claude/skills/my-domain-skill
cat > .claude/skills/my-domain-skill/SKILL.md << 'EOF'
---
name: my-domain-skill
description: "역할 설명. Trigger: 키워드1, 키워드2"
---
# My Domain Skill
## 절차
1. ...
EOF
```

## 다중 저장소 Codex 이관

여러 저장소나 에이전트 묶음에 같은 `Claude -> Codex` 전략을 적용하려면 `.codex-sync/`를 각 저장소에 복사하고, manifest 스키마를 동일하게 유지하세요. 원본-파생 모델은 어디서나 동일해야 합니다: Claude 파일을 수정하고, Codex 파일을 재생성하며, stale target은 실패로 취급합니다.

그 후 축약된 `CLAUDE.md` 트리거 표에 등록.

런타임 수준의 훅 동작은 `docs/operations/hook-contract.md`에 따로 정리했습니다. 시작 로드, TDD 차단, post-edit 점검 같은 규칙을 프롬프트마다 중복해서 적지 않도록 분리한 문서입니다.

## 감사의 말

다음 오픈소스 프로젝트에서 영감을 받아 설계했습니다:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD 강제, Hard Gate 패턴, 검증 철학.
- **[Archon](https://github.com/coleam00/Archon)** — 결정론적 워크플로 엔진, 명시적 검증 게이트, 실행 상태 규율.
- **[CLI-Anything](https://github.com/HKUDS/CLI-Anything)** — 에이전트 하네스 구조, 스킬 레지스트리 패턴.
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — 작성/리뷰 분리, Deep Interview, 서킷 브레이커.
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — 토큰 최적화, 지연 로딩, 모델 라우팅.
- **[ByteRover CLI](https://github.com/campfirein/byterover-cli)** — Context Tree 아키텍처 분석: 연쇄 업데이트, 교차참조(`related` 필드), 메모리 린트 패턴.
- **[LLM Wiki (Karpathy)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** — 영속적 지식 축적 패턴: 인제스트 시 연쇄 업데이트, 모순 감지, 위키 린트.
- **[Obsidian Mind](https://github.com/breferrari/obsidian-mind)** — SessionEnd 훅 패턴: 세션 종료 시 스냅샷 자동 저장.

프롬프트 기법 참고 연구: ReAct, CoVE, Tree/Graph of Thoughts, Contrastive CoT, Maieutic Prompting, Self-Refinement, Chain of Density, Plan-and-Solve, Reflexion, Skeleton-of-Thought.

## 라이선스

MIT License.
