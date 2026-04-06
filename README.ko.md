# Claude Code 프롬프트 하네스

Claude Code를 구조화된 개발 시스템으로 전환하는 프로젝트 관리 하네스. 에이전트, 스킬, 메모리, 품질 게이트를 포함합니다.

> **[English README](README.md)**

## 왜 만들었는가

Claude Code를 구조 없이 사용하면 30%의 성능만 발휘합니다. 에이전트 + 스킬 + 훅 + 메모리 하네스를 씌우면 100%가 됩니다. 이 프로젝트는 새 프로젝트에 원커맨드로 하네스를 설치하는 도구입니다.

설계 철학은 AI 엔지니어링의 3단계 진화를 따릅니다:
1. **프롬프트 엔지니어링** — 질문을 잘 던지는 법
2. **맥락 엔지니어링** — 데이터를 잘 떠먹이는 법
3. **하네스 엔지니어링** — 안전하게 굴리는 법

## 빠른 시작

```bash
# 빈 프로젝트 디렉토리에서 실행
bash <(curl -fsSL https://raw.githubusercontent.com/youngjin39/Claude-Code-Prompt-Harness/main/setup.sh)
```

설치 과정에서 다음을 설정합니다:

| 단계 | 내용 |
|---|---|
| 프로젝트 정보 | 이름, 언어/프레임워크, 패키지 매니저 |
| 출력 언어 | 한국어, 영어, 일본어, 중국어, 기타 |
| 모듈 선택 | 선택적 스킬 및 MCP 서버 |
| 권한 수준 | Strict / Standard / Permissive |

설치 후 `claude` 명령으로 시작하면 하네스가 자동으로 작동합니다.

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
  └─ 복잡 (3단계+) → 플랜 모드
       brainstorming → writing-plans → execution → verification → 완료
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
| main-orchestrator | opus | 대화, 판단, 작업 분류, 단순 작업 직접 실행 |
| executor-agent | sonnet | 복잡한 작업 전용 코드 작성 |
| quality-agent | sonnet | 읽기 전용 적대적 리뷰 (Write/Edit 금지) |

quality-agent는 **적대적 렌즈**를 사용합니다: executor가 놓친 것을 찾는 것이 역할이며, 확인이 아니라 의심합니다.

### 스킬 (6개 코어 + 2개 선택)

**코어** (항상 설치):

| 스킬 | 트리거 | 핵심 기능 |
|---|---|---|
| brainstorming | 설계, 아키텍처, 새 기능 | Hard Gate. 2~3개 다른 관점의 대안. 반대 서사 공격. 합성 옵션. |
| writing-plans | 계획, 구현 계획 | 구체적 코드 포함 필수. 금지: "테스트 추가", "필요시 리팩터링". |
| verification | 검증, 완료 확인 | 6단계 게이트 + Red Team 6Q 자가 공격 + 숨은 전제 심문. |
| deep-interview | 인터뷰, 요구사항, 명확화 | 모호성 점수 + 병목 진단 (팩트/논리/편향/실행). |
| git-commit | 커밋, git, 변경 저장 | 구조화된 커밋 규칙 + 트레일러. |
| project-doctor | 진단, 헬스체크 | 구조 + 메모리 + 컨텍스트 진단. |

**선택** (설치 시 선택):

| 스킬 | 트리거 | 선택인 이유 |
|---|---|---|
| code-review | 리뷰, PR, 품질 | 모든 프로젝트가 정식 PR 리뷰가 필요하지는 않음. |
| testing | 테스트, TDD, 단위 테스트 | 일부 프로젝트는 외부에서 테스트 관리. |

### MCP 서버

| 서버 | 역할 | 코어/선택 |
|---|---|---|
| fetch | 웹 접근 | 코어 |
| Context7 | 라이브러리 최신 문서 자동 주입 | 선택 |
| Sequential Thinking | 구조화된 추론 체인 | 선택 |

### 훅 (4개)

| 훅 | 이벤트 | 동작 |
|---|---|---|
| session-start.sh | SessionStart | plan.md + lessons.md + 최근 세션 자동 주입 |
| pre-compact.sh | PreCompact | /compact 전 핸드오프 문서 작성 리마인더 |
| post-edit-check.sh | PostToolUse (Edit\|Write) | 디버그 구문 + 자격증명 유출 탐지 |
| session-end.sh | SessionEnd | 세션 스냅샷 자동 저장 + 메모리 하베스팅 리마인더 |

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

Select [1-4, comma-separated, 'all', or 'none', default: all]:
```

미선택 모듈은 설치 시 제거됩니다 — 죽은 컨텍스트 없음, 토큰 낭비 없음.

## 프로젝트 구조

```
.
├── CLAUDE.md                    # 루트 설정 (AI 헌법)
├── .mcp.json                    # MCP 서버 (동적 생성)
├── setup.sh                     # 하네스 설치기
├── .claude/
│   ├── settings.local.json      # 권한 + 훅
│   ├── agents/                  # 에이전트 3개
│   ├── hooks/                   # 자동화 훅 4개
│   └── skills/                  # 스킬 6~8개 (선택에 따라)
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
    └── {category}/              # architecture, decisions, patterns, domain, risks, integrations, references
```

## 도메인 스킬 추가

하네스 스킬은 범용, 도메인 스킬은 프로젝트 전용:

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

그 후 `CLAUDE.md`의 Skill Keyword Table에 등록.

## 감사의 말

다음 오픈소스 프로젝트에서 영감을 받아 설계했습니다:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD 강제, Hard Gate 패턴, 검증 철학.
- **[CLI-Anything](https://github.com/HKUDS/CLI-Anything)** — 에이전트 하네스 구조, 스킬 레지스트리 패턴.
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — 작성/리뷰 분리, Deep Interview, 서킷 브레이커.
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — 토큰 최적화, 지연 로딩, 모델 라우팅.
- **[ByteRover CLI](https://github.com/campfirein/byterover-cli)** — Context Tree 아키텍처 분석: 연쇄 업데이트, 교차참조(`related` 필드), 메모리 린트 패턴.
- **[LLM Wiki (Karpathy)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** — 영속적 지식 축적 패턴: 인제스트 시 연쇄 업데이트, 모순 감지, 위키 린트.
- **[Obsidian Mind](https://github.com/breferrari/obsidian-mind)** — SessionEnd 훅 패턴: 세션 종료 시 스냅샷 자동 저장.

프롬프트 기법 참고 연구: ReAct, CoVE, Tree/Graph of Thoughts, Contrastive CoT, Maieutic Prompting, Self-Refinement, Chain of Density, Plan-and-Solve, Reflexion, Skeleton-of-Thought.

## 라이선스

MIT License.
