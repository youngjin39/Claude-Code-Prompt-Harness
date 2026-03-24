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
├── .claude/
│   ├── settings.local.json
│   ├── agents/          # main-orchestrator, quality-agent, executor-agent
│   └── skills/          # 8 skills (see skill trigger table)
├── tasks/
│   ├── plan.md          # current phase summary (compact)
│   ├── context.md       # decision rationale
│   ├── checklist.md     # progress tracking
│   ├── change_log.md    # change history
│   ├── lessons.md       # failures/successes → rules
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
| feature | brainstorming → plans → executor → code-review → verification |
| bugfix | deep-interview(lite) → executor → testing → verification |
| refactor | brainstorming → plans → executor → code-review → verification |
| security | code-review(security) → executor → verification |

### Agent Role Separation
| Agent | Model | Role | Writes Code |
|---|---|---|---|
| main-orchestrator | opus | conversation, judgment, classification, simple task execution | Yes (simple) |
| executor-agent | sonnet | dedicated sub-agent for complex task code writing | Yes (complex) |
| quality-agent | sonnet | read-only review. Write/Edit forbidden. | No |

### Branching Criteria
- **Simple (1~2 steps)**: orchestrator executes directly. When executor call overhead exceeds the work involved.
- **Complex (3+ steps)**: brainstorming → plans → executor → verification pipeline.
- When criteria are ambiguous, classify as complex (overestimating is safer than underestimating).

### Gate Conditions
| Phase | Entry | Exit |
|---|---|---|
| brainstorming | complex classification | user design approval |
| writing-plans | brainstorming exit | includes concrete code + commands + expected output |
| execution | plans exit | all steps complete or 3 failures → STOP |
| verification | execution exit | verification passed based on execution evidence |

### Built-in Rules
- brainstorming: must compare 2~3 alternatives.
- writing-plans: no abstract expressions. Include actual code.
- execution: 3-failure circuit breaker → revisit architecture.
- verification: "should work", "probably fine" forbidden. Evidence only.

## Skill Trigger Table (body loaded via Read when triggered)

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
- Max 50 lines per file (exception: `type: archive` files). Frontmatter: title, keywords, created, last_used.

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

## Context Management
- Consider /compact at logical transition points: research → planning, debug → feature.
- Write a handoff to tasks/handoffs/ before compacting.
- Do not start complex tasks in the last 20% of the context window.

### Sub-agent Isolation
- NEVER pass session history to sub-agents.
- Extract only the necessary context from the handoff document and pass that.
- 1 sub-agent = 1 task = minimum context.
- After sub-agent completes: receive results only. Discard internal process.

## Automation Hooks (.claude/hooks/)
- **SessionStart**: auto-load plan.md + lessons.md + most recent session.
- **PreCompact**: auto-generate handoff skeleton + reminder.
- **PostToolUse(Edit|Write)**: debug statement + credential leak detection.

## Automatic Memory Harvesting
- On task completion, assess: "Was anything new learned?"
- If yes → save to docs/{category}/ + update memory-map.md.
- If no → skip (prevent unnecessary memory bloat).

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

## Principles
- Simplicity first. Minimum impact.
- Solve root causes. No workarounds.
