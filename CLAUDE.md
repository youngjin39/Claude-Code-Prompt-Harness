# claude-code-harness — Claude Code Project Management Harness

## Development Environment
| Item | Value |
|---|---|
| OS | macOS Darwin 25.3.0 (ARM64, Apple Silicon) |
| Language/Framework | TBD (project management harness) |
| Package Manager | TBD |

## Build & Run
- Harness-only configuration. Update this section when a code project is added.

## Project Structure
```
.
├── CLAUDE.md
├── .mcp.json
├── setup.sh             # harness installer
├── README.md
├── LICENSE
├── .claude/
│   ├── settings.local.json
│   ├── agents/          # main-orchestrator, quality-agent, executor-agent
│   ├── hooks/           # session-start, pre-compact, pre-tool-use, post-edit-check, session-end
│   └── skills/          # 10 skills (see skill trigger table)
├── tasks/
│   ├── plan.md          # current phase summary (compact)
│   ├── context.md       # decision rationale
│   ├── checklist.md     # progress tracking
│   ├── change_log.md    # change history
│   ├── lessons.md       # failures/successes → rules
│   ├── cost-log.md      # token usage tracking
│   ├── handoffs/        # inter-phase handoff documents
│   ├── sessions/        # session snapshots
│   └── log/             # completed task archive
└── docs/                # long-term memory (no decay)
    ├── memory-map.md    # keyword index
    ├── architecture/    # system structure
    ├── decisions/       # ADR + full design archive
    ├── patterns/        # recurring patterns
    ├── domain/          # domain knowledge
    ├── risks/           # risks
    ├── integrations/    # external integrations
    └── references/      # reference repo analysis
```

## Workflow Pipeline

### Ambiguous Request Gate
If a request contains zero specificity signals (file path, function name, numbered step, error message) → deep-interview.
Can be bypassed with the `force:` prefix.

### Task Flow
```
Request → specificity signals? → none → deep-interview → classify
  ├─ simple (1~2 steps) → orchestrator executes directly → self-check → done
  └─ complex (3+ steps) → plan mode
       brainstorming → writing-plans → execution → verification → done
```

### Orchestration Presets
| Preset | Pipeline |
|---|---|
| feature | brainstorming → **ux-ui-design (if UI)** → writing-plans → executor → testing → code-review → verification |
| bugfix | deep-interview(lite) → executor → testing → verification |
| refactor | brainstorming → writing-plans → executor → code-review → verification |
| security | code-review(security) → executor → verification |

### Agent Role Separation
| Agent | Model | Role | Writes Code |
|---|---|---|---|
| main-orchestrator | opus | conversation, judgment, classification, simple task execution | Yes (simple) |
| executor-agent | sonnet | dedicated sub-agent for complex task code writing | Yes (complex) |
| quality-agent | sonnet | read-only review. Write/Edit forbidden. | No |

### Branching Criteria
- **Simple (1~2 steps)**: orchestrator executes directly. When executor call overhead exceeds the work involved.
- **Complex (3+ steps)**: brainstorming → writing-plans → executor → verification pipeline.
- When criteria are ambiguous, classify as complex (overestimating is safer than underestimating).

### Gate Conditions
| Phase | Entry | Exit |
|---|---|---|
| brainstorming | complex classification | user design approval |
| writing-plans | brainstorming exit | includes concrete code + commands + expected output |
| execution | writing-plans exit | all steps complete or 3 failures → STOP |
| verification | execution exit | verification passed based on execution evidence |

### Built-in Rules
- brainstorming: must compare 2~3 alternatives with different lenses. Counter-narrative mandatory.
- ux-ui-design: **hard gate** if the work produces UI. No UI code until Steps 1–7 approved by user.
- writing-plans: no abstract expressions. Include actual code. Banned: "add tests", "refactor as needed".
- execution: 3-failure circuit breaker → revisit architecture. Use git worktree for risky changes.
- verification: "should work", "probably fine" forbidden. Evidence only. Red Team 5Q after gate pass.

## Skill Trigger System (body loaded via Read when triggered)

### Trigger Types
| Type | How it fires | Example |
|---|---|---|
| Keyword | Request contains listed keywords | "test", "review", "commit" |
| Intent | Inferred user goal | "add feature" → brainstorming, "fix bug" → deep-interview(lite) |
| File path | Changed/mentioned file matches pattern | `*.test.*` → testing, `*.md` → skip lint |
| Code pattern | Code contains risky patterns | external input handling → security review |

When triggered: report trigger reason + loaded skill(s) (max 3) in one line.

### Skill Keyword Table

| Keyword | Skill | Path |
|---|---|---|
| review, PR, quality, merge check, post-completion | code-review | .claude/skills/code-review/SKILL.md |
| test, TDD, unit test, integration test | testing | .claude/skills/testing/SKILL.md |
| commit, git, save changes | git-commit | .claude/skills/git-commit/SKILL.md |
| diagnose, doctor, health check, status | project-doctor | .claude/skills/project-doctor/SKILL.md |
| design, brainstorming, architecture, new feature | brainstorming | .claude/skills/brainstorming/SKILL.md |
| plan, implementation plan, step design | writing-plans | .claude/skills/writing-plans/SKILL.md |
| verify, done check, proof, self-check | verification | .claude/skills/verification/SKILL.md |
| interview, requirements, clarify, ambiguous | deep-interview | .claude/skills/deep-interview/SKILL.md |
| self-audit, compliance, harness check, 자기점검 | self-audit | .claude/skills/self-audit/SKILL.md |
| ui, ux, screen, wireframe, frontend, design system, 화면, 디자인 | ux-ui-design | .claude/skills/ux-ui-design/SKILL.md |

> On skill trigger: update `last_used` + `count` in docs/memory-map.md Skill Usage table.

## Model Routing
| Task Type | Model | Rationale |
|---|---|---|
| file search, keyword lookup, simple transformation | haiku | mechanical, no judgment needed |
| code writing, bug fixing, testing | sonnet | implementation capability required |
| architecture design, planning, review synthesis | opus | complex judgment + context understanding |

## Memory System (3 layers)

### Layer 1: Project Knowledge (docs/) — what we know
- Long-term memory. No decay. Permanently preserved.
- Keyword index (memory-map.md) → category → file. Load only what is needed.
- Max 50 lines per file (exception: `type: archive` files). Frontmatter: title, keywords, related, created, last_used.

### Layer 2: Behavioral Rules (tasks/lessons.md) — what to do / not do
- Failure/success table → promoted to rule after 2 repetitions.
- Must be read at session start.

### Layer 3: Session Restore (tasks/sessions/) — ephemeral snapshots
- What Worked / What Did NOT Work / Decisions / Next Step.
- Only the most recent snapshot is valid. Older ones are promoted to docs/ or deleted.

### Memory Usage Protocol
1. Task start: scan memory-map.md keyword table.
2. If a relevant keyword exists, Read only that file.
3. If none, skip (token savings).
4. Task complete: new learnings → save to docs/{category}/ + update index.

## Autonomous Bug Fix
- Bug report received → investigate and fix without waiting for instructions.
- Still follows the pipeline: classify → execute → verify. Autonomy applies to initiation, not to skipping gates.

## Context Management
- Consider /compact at logical transition points: research → planning, debug → feature.
- Write a handoff to tasks/handoffs/ before compacting.
- Do not start complex tasks in the last 20% of the context window.
- **Context recovery**: on session break or compact, re-read plan.md + lessons.md + latest session snapshot → produce 3-line summary → resume from there.

### Sub-agent Isolation
- NEVER pass session history to sub-agents.
- Extract only the necessary context from the handoff document and pass that.
- 1 sub-agent = 1 task = minimum context.
- After sub-agent completes: receive results only. Discard internal process.

## Automation Hooks (.claude/hooks/)
- **SessionStart**: auto-load plan.md + lessons.md + most recent session.
- **PreCompact**: auto-generate handoff skeleton + reminder.
- **PreToolUse(Bash|Write|Edit)**: input-stage guardrail. Block destructive patterns + denied paths before tool runs.
- **PostToolUse(Edit|Write)**: debug statement + credential leak detection.
- **SessionEnd**: auto-save session snapshot + instinct harvest (pattern extraction from session).

## Failure Handling (JIT)
On any tool failure, parse error, or unexpected state → Read `docs/patterns/error-handling.md` (Error Taxonomy + Output Parsing Recovery). Never "try again harder" without classification. State Checkpoint protocol lives in `.claude/agents/executor-agent.md`.

## Automatic Memory Harvesting (Instinct Pattern)
- On task completion **or when a reusable judgment/analysis emerges in conversation**, assess: "Was anything new learned?"
- If yes → save to docs/{category}/ + update memory-map.md.
- If no → skip (prevent unnecessary memory bloat).
- **Instinct categories**: error resolutions, user corrections, framework workarounds, conventions established, approaches confirmed.
- **Skip**: trivial patterns (typos, one-off fixes). Only save if it helps a future session.
- **Dedup**: if pattern already exists in lessons.md, increment count (2+ repetitions → rule promotion). Do not create duplicates.
- **Cascade Update**: on save, check memory-map.md for existing files sharing keywords. If found, review for contradiction/overlap → update or flag. A single new insight may touch multiple files.

## Quality Checks
- Record every change in change_log.md.
- After completion, run lint/static analysis. Fix 0~3 errors immediately; 4+ errors → quality-agent.
- Self-check: error handling + security on the 2 most recently modified files.

## Project Management
- At start, read plan + lessons (SessionStart hook injects automatically). Checklist via manual Read.
- Before proceeding with changes, update plan and checklist.
- On feature completion, archive to tasks/log/.

## Language Protocol
- User-facing output (reports, task logs) → Korean.
- Internal (agent comms, handoffs, docs/, skills, code, commits) → English.
- English is ~2-3x more token-efficient for same information.

## Token Efficiency
- Do not re-read files already read in the current session unless the file may have changed.
- Do not restate the user's question. Execute immediately.
- Do not touch code outside the scope of the request.
- When the user corrects a fact, the correction becomes session ground truth. Do not revert.

## Principles
- **Default is no-action.** Do not act without evidence. Unverified conclusions are void.
- Simplicity first. Minimum impact.
- Solve root causes. No workarounds.
- **Prohibition > instruction.** Explicit bans are stronger than vague guidance. When defining behavior, state what is forbidden before what is desired.
- **No filler.** Ban: sycophantic openers ("Sure!", "Great question!", "Absolutely!"), hollow closings ("I hope this helps!", "Let me know if you need anything!"), "As an AI..." framing, repetition, padding adjectives, hedging phrases. Every sentence must carry information.
