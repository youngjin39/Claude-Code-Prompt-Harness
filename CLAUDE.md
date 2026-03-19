# prompt_DEV — Claude Code Project Management Harness

## 개발 환경
| 항목 | 값 |
|---|---|
| OS | macOS Darwin 25.3.0 (ARM64, Apple Silicon) |
| 언어/프레임워크 | 미정 (프로젝트 관리 하네스) |
| 패키지 매니저 | 미정 |

## 빌드 & 실행
- 하네스 전용 구성. 코드 프로젝트 추가 시 이 섹션 갱신.

## 프로젝트 구조
```
.
├── CLAUDE.md
├── .mcp.json
├── .claude/
│   ├── settings.local.json
│   ├── agents/          # main-orchestrator, quality-agent, executor-agent
│   └── skills/          # 7개 스킬 (트리거 테이블 참조)
├── tasks/
│   ├── plan.md          # 현재 Phase 요약 (compact)
│   ├── context.md       # 결정 근거
│   ├── checklist.md     # 진행 상황
│   ├── change_log.md    # 수정 기록
│   ├── lessons.md       # 실패/성공 → 규칙
│   ├── handoffs/        # 단계 간 핸드오프 문서
│   ├── sessions/        # 세션 스냅샷
│   └── log/             # 완료 작업 아카이브
└── docs/                # 뉴런 장기 메모리 (감쇠 없음)
    ├── memory-map.md    # 키워드 인덱스
    ├── architecture/    # 시스템 구조
    ├── decisions/       # ADR + 전체 설계 아카이브
    ├── patterns/        # 반복 패턴
    ├── domain/          # 도메인 지식
    ├── risks/           # 리스크
    ├── integrations/    # 외부 연동
    └── references/      # 참조 레포 분석
```

## 워크플로우 파이프라인

### 모호 요청 게이트
요청에 구체성 신호(파일 경로, 함수명, 번호 단계, 에러 메시지) 0개 → deep-interview.
`force:` 접두사로 우회 가능.

### 작업 흐름
```
요청 → 구체성 신호? → 없으면 deep-interview → 분류
  ├─ 단순(1~2단계) → orchestrator 직접 실행 → 셀프체크 → 완료
  └─ 복합(3단계+) → 플랜 모드
       brainstorming → writing-plans → execution → verification → 완료
```

### 오케스트레이션 프리셋
| 프리셋 | 파이프라인 |
|---|---|
| feature | brainstorming → plans → executor → code-review → verification |
| bugfix | deep-interview(lite) → executor → testing → verification |
| refactor | brainstorming → plans → executor → code-review |
| security | code-review(security) → executor → verification |

### 에이전트 역할 분리
| 에이전트 | 모델 | 역할 | 코드 작성 |
|---|---|---|---|
| main-orchestrator | opus | 대화, 판단, 분류, 단순 작업 실행 | O (단순) |
| executor-agent | sonnet | 복합 작업 코드 작성 전담 서브에이전트 | O (복합) |
| quality-agent | sonnet | 읽기 전용 리뷰. Write/Edit 금지. | X |

### 분기 기준
- **단순 (1~2단계)**: orchestrator가 직접 실행. executor 호출 오버헤드 > 작업량일 때.
- **복합 (3단계+)**: brainstorming→plans→executor→verification 파이프라인.
- 기준이 모호하면 복합으로 분류 (과소평가보다 과대평가가 안전).

### 게이트 조건
| 단계 | 진입 | 탈출 |
|---|---|---|
| brainstorming | 복합 분류 | 사용자 설계 승인 |
| writing-plans | brainstorming 탈출 | 구체적 코드+명령어+예상 출력 포함 |
| execution | plans 탈출 | 모든 단계 완료 또는 3회 실패→STOP |
| verification | execution 탈출 | 실행 증거 기반 검증 통과 |

### 내장 규칙
- brainstorming: 2~3개 대안 비교 필수.
- writing-plans: 추상적 표현 금지. 실제 코드 포함.
- execution: 3회 실패 서킷 브레이커 → 아키텍처 재검토.
- verification: "should work", "probably fine" 금지. 증거만 인정.

## 스킬 트리거 테이블 (본문은 발동 시 Read로 로드)

| 키워드 | 스킬 | 경로 |
|---|---|---|
| 리뷰, PR, 품질 | code-review | .claude/skills/code-review/SKILL.md |
| 테스트, TDD, 검증 | testing | .claude/skills/testing/SKILL.md |
| 커밋, git | git-commit | .claude/skills/git-commit/SKILL.md |
| 진단, 헬스체크 | project-doctor | .claude/skills/project-doctor/SKILL.md |
| 설계, 브레인스토밍 | brainstorming | .claude/skills/brainstorming/SKILL.md |
| 계획, 구현 계획 | writing-plans | .claude/skills/writing-plans/SKILL.md |
| 완료 확인, 검증 | verification | .claude/skills/verification/SKILL.md |
| 인터뷰, 요구사항, 모호 | deep-interview | .claude/skills/deep-interview/SKILL.md |

## 모델 라우팅
| 작업 유형 | 모델 | 근거 |
|---|---|---|
| 파일 탐색, 키워드 검색, 단순 변환 | haiku | 기계적, 판단 불필요 |
| 코드 작성, 버그 수정, 테스트 | sonnet | 구현력 필요 |
| 아키텍처 설계, 계획, 리뷰 종합 | opus | 복합 판단 + 맥락 이해 |

## 메모리 시스템 (3층)

### 층 1: 프로젝트 지식 (docs/) — what we know
- 장기 메모리. 감쇠 없음. 영구 보존.
- 키워드 인덱스(memory-map.md) → 카테고리 → 파일. 필요한 것만 로드.
- 파일당 50줄 이내. 프론트매터: title, keywords, created, last_used.

### 층 2: 행동 규칙 (tasks/lessons.md) — what to do / not do
- 실패/성공 테이블 → 2회 반복 시 규칙 승격.
- 세션 시작 시 반드시 읽기.

### 층 3: 세션 복원 (tasks/sessions/) — ephemeral snapshots
- What Worked / What Did NOT Work / Decisions / Next Step.
- 최근 1개만 유효. 오래된 것은 docs/로 승격하거나 삭제.

### 메모리 활용 프로토콜
1. 작업 시작: memory-map.md 키워드 테이블 스캔.
2. 관련 키워드 있으면 해당 파일만 Read.
3. 없으면 생략 (토큰 절약).
4. 작업 완료: 새로 배운 것 → docs/{category}/ 저장 + 인덱스 갱신.

## 컨텍스트 관리
- 논리적 전환점에서 /compact 고려: 리서치→계획, 디버그→기능.
- 압축 전 tasks/handoffs/ 에 핸드오프 작성.
- 컨텍스트 윈도우 마지막 20%에서 복합 작업 시작 금지.

### 서브에이전트 격리
- 서브에이전트에 세션 히스토리 **절대 전달 금지**.
- 핸드오프 문서에서 필요 컨텍스트만 추출하여 전달.
- 서브에이전트 1개 = 작업 1개 = 최소 컨텍스트.
- 서브에이전트 완료 후: 결과만 수신. 내부 과정은 버림.

## 작업 기억
- tasks/plan.md: 현재 Phase + 다음 액션 (compact).
- tasks/context.md: 결정 근거.
- tasks/checklist.md: 진행 상황.
- tasks/change_log.md: 수정 기록.
- tasks/lessons.md: 실패/성공 → 규칙.
- 컨텍스트 단절 시: plan + checklist + lessons 재독 → 3줄 요약 → 재개.

## 자동화 훅 (.claude/hooks/)
- **SessionStart**: plan.md + lessons.md + 최근 세션 자동 로드.
- **PreCompact**: 핸드오프 작성 리마인더.
- **PostToolUse(Edit|Write)**: 디버그 문(console.log, print) 경고.

## 메모리 자동 수확
- 작업 완료 시 판단: "새로 배운 것이 있는가?"
- 있으면 → docs/{category}/ 저장 + memory-map.md 갱신.
- 없으면 → 생략 (불필요한 메모리 방지).

## 품질 검사
- 수정마다 change_log.md 기록.
- 완료 후 린트/정적 분석. 에러 0~3 즉시 수정, 4+ quality-agent.
- 셀프체크: 최근 2파일 오류 처리 + 보안.

## 프로젝트 관리
- 시작 시 plan, checklist, lessons 읽기 (SessionStart 훅이 자동 주입).
- 변경 시 plan, checklist 수정 후 진행.
- 기능 완료 시 tasks/log/ 아카이브.

## 언어 프로토콜 (토큰 절약)
| 대상 | 언어 | 예시 |
|---|---|---|
| 사용자 대면 보고 | **한글** | "[발견] 인증 로직 누락" |
| tasks/ 로그 (change_log, lessons) | **한글** | "JWT 갱신 실패 → 만료 체크 추가" |
| 에이전트 간 통신 (핸드오프) | **영어** | "Decision: use refresh token rotation" |
| 컨텍스트 정리 (plan, context) | **영어** | "Phase 1 complete. Next: verification." |
| 스킬/에이전트 정의 파일 | **영어** | SKILL.md, agent .md 내부 |
| docs/ 장기 메모리 | **영어** | 키워드 인덱스, 패턴 기록 |
| 코드, 커밋 메시지 | **영어** | `feat(auth): add token refresh` |

## 원칙
- 단순함 우선. 최소 영향.
- 근본 원인 해결. 임시방편 금지.
