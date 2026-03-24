# claude-code-harness

A project management harness for orchestrating Claude Code agents with structured workflows, memory systems, and quality gates.

> Extensible beyond coding — supports OS-level automation and non-coding workflows through an agent + skill + hook architecture.

## 3-Axis Design

```
                    ┌─────────────────────┐
                    │   Workflow           │
                    │  (how work is done)  │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                                  │
   ┌──────────▼──────────┐           ┌──────────▼──────────┐
   │  Memory Efficiency   │           │  Context Efficiency  │
   │  (what to remember)  │           │  (what to load)      │
   └─────────────────────┘           └─────────────────────┘
```

- **Workflow**: Ambiguity gate → classify → brainstorming → plans → execution → verification
- **Memory**: Neuron-style long-term memory (keyword index, no decay, 3-layer separation)
- **Context**: Lazy loading, model routing, sub-agent isolation, handoff documents

## Structure

```
.
├── CLAUDE.md                    # Root configuration
├── .mcp.json                    # MCP servers (fetch + sequential-thinking)
├── .claude/
│   ├── settings.local.json      # Permissions + hook configuration
│   ├── hooks/                   # Automation hook scripts
│   │   ├── session-start.sh     # Inject context at session start
│   │   ├── pre-compact.sh       # Handoff reminder before /compact
│   │   └── post-edit-check.sh   # Warn on debug statements after edits
│   ├── agents/                  # 3 agents
│   │   ├── main-orchestrator.md # Orchestration, judgment, routing (opus)
│   │   ├── executor-agent.md    # Code writing sub-agent (sonnet)
│   │   └── quality-agent.md     # Read-only review, no Write/Edit (sonnet)
│   └── skills/                  # 8 skills
│       ├── brainstorming/       # Design enforcement (Hard Gate)
│       ├── writing-plans/       # Concrete implementation plans
│       ├── verification/        # 6-stage verification gate
│       ├── deep-interview/      # Ambiguity gating
│       ├── code-review/         # Quality inspection
│       ├── testing/             # Test writing and execution
│       ├── git-commit/          # Commit rules + structured trailers
│       └── project-doctor/      # Health diagnostics
├── tasks/                       # Working memory
│   ├── plan.md                  # Current plan (compact)
│   ├── context.md               # Decision rationale
│   ├── checklist.md             # Progress tracking
│   ├── change_log.md            # Change history
│   ├── lessons.md               # Failures/successes → rules
│   ├── cost-log.md              # Cost tracking
│   ├── handoffs/                # Inter-phase handoff documents
│   ├── sessions/                # Session snapshots
│   └── log/                     # Completed task archive
└── docs/                        # Neuron long-term memory
    ├── memory-map.md            # Keyword index
    ├── decisions/               # ADR + full design archive
    ├── references/              # Reference repo analysis
    ├── architecture/
    ├── patterns/
    ├── domain/
    ├── risks/
    └── integrations/
```

## Agents

| Agent | Model | Role | Code Writing |
|---|---|---|---|
| main-orchestrator | opus | Conversation, judgment, classification, simple task execution | Yes (simple) |
| executor-agent | sonnet | Dedicated code writing for complex tasks | Yes (complex) |
| quality-agent | sonnet | Read-only review — Write/Edit prohibited | No |

## Skills

| Skill | Trigger Keywords | Role |
|---|---|---|
| brainstorming | design, brainstorm | Hard Gate. Requires comparison of 2–3 alternatives. |
| writing-plans | plan, implementation plan | Bite-sized steps. Must include concrete code. |
| verification | done check, verify | 6-stage gate + circuit breaker. |
| deep-interview | interview, ambiguous, requirements | Ambiguity scoring + challenge round. |
| code-review | review, PR, quality | Quality inspection (forked read-only). |
| testing | test, TDD | Test writing and execution. |
| git-commit | commit, git | Commit rules + structured trailers. |
| project-doctor | diagnose, health check | Structure + memory + context diagnostics. |

## Workflow Pipeline

```
Request → specificity signals? → none → deep-interview → classify
  ├─ Simple (1–2 steps) → orchestrator executes directly → self-check → done
  └─ Complex (3+ steps) → plan mode
       brainstorming → writing-plans → execution → verification → done
```

### Orchestration Presets

| Preset | Pipeline |
|---|---|
| feature | brainstorming → plans → executor → code-review → verification |
| bugfix | deep-interview (lite) → executor → testing → verification |
| refactor | brainstorming → plans → executor → code-review → verification |
| security | code-review (security) → executor → verification |

## Memory System

### 3-Layer Separation

- **Layer 1 — Project Knowledge (`docs/`)**: Long-term memory, no decay. Selective loading via keyword index. Files capped at 50 lines with required frontmatter (`title`, `keywords`, `created`, `last_used`).
- **Layer 2 — Behavioral Rules (`tasks/lessons.md`)**: Action rules derived from failures and successes. Patterns repeated twice are promoted to permanent rules.
- **Layer 3 — Session Restore (`tasks/sessions/`)**: Ephemeral snapshots. Only the most recent snapshot is valid. Older ones are promoted to `docs/` or deleted.

### Memory Protocol

1. At task start: scan `memory-map.md` keyword table.
2. If relevant keywords found: `Read` only those files.
3. If no match: skip (token savings).
4. At task end: store new knowledge in `docs/{category}/` and update the index.

## Context Efficiency

- **Lazy Loading**: `CLAUDE.md` holds only the trigger table. Skill bodies are loaded with `Read` on invocation.
- **Model Routing**: Haiku (file search, keyword lookup) / Sonnet (code writing, bug fixing) / Opus (architecture, planning, review synthesis).
- **Sub-agent Isolation**: Session history is never passed to sub-agents. Only handoff documents with extracted context are forwarded. One sub-agent = one task = minimum context.
- **Compact `plan.md`**: Full design is archived in `docs/`. `plan.md` stays under 50 lines.

## Automation Hooks

| Hook | Event | Action |
|---|---|---|
| session-start.sh | SessionStart | Auto-inject `plan.md` + `lessons.md` + latest session snapshot |
| pre-compact.sh | PreCompact | Remind to write a handoff document before compacting |
| post-edit-check.sh | PostToolUse (Edit\|Write) | Warn on debug statements (`console.log`, `print`, etc.) |

## Getting Started

### Quick Setup (Recommended)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/youngjin39/Claude-Code-Prompt-Harness/main/setup.sh)
```

This automatically clones the harness, sets up the directory structure, and configures hooks.

> **Note:** In new projects, `tasks/` files are local working memory (gitignored by default).

### Manual Setup

1. Clone or copy this repository into your project root.
2. Edit `CLAUDE.md` — update the **Development Environment** and **Build & Run** sections to match your project.
3. Add project-specific domain skills under `.claude/skills/`.
4. Initialize `tasks/` files (`plan.md`, `checklist.md`, `lessons.md`, `change_log.md`, `cost-log.md`).
5. Configure tool permissions in `.claude/settings.local.json`.
6. Start working — the orchestrator will guide the rest.

## Adding Domain Skills

Harness skills are universal; domain skills are project-specific. Keep them separate:

- **Harness skills** (`brainstorming`, `verification`, `git-commit`, etc.) — apply to every project, never modify.
- **Domain skills** (e.g., `api-design`, `security-audit`, `db-migration`) — add to `.claude/skills/` per project and register them in the trigger table in `CLAUDE.md`.

A skill is a directory containing a `SKILL.md` file. It is loaded on demand via the `Read` tool when its trigger keyword appears in a request.

## Acknowledgments

This harness was designed with inspiration from four open-source projects:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD enforcement, Hard Gate pattern, Iron Law, verification-as-morality philosophy, and rationalization prevention tables.
- **[CLI-Anything](https://github.com/HKUDS/CLI-Anything)** — Agent harness structure, SOP documents, skill registry pattern, and validation commands.
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Write/Review separation, Deep Interview skill, ambiguity gating, structured commit trailers, and circuit breaker pattern.
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — Token optimization, lazy loading, session persistence, failure memory, model routing, and cost tracking.

## License

MIT License.
