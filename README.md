# Claude Code Prompt Harness

A project management harness that turns Claude Code into a structured, gate-enforced development system with agents, skills, memory, and quality controls.

> **[한국어 README](README.ko.md)**

## Why This Exists

Claude Code without structure operates at 30%. With a harness — agents, skills, hooks, memory — it operates at 100%. This project provides that harness as a one-command installer for any new project.

The design philosophy follows three stages of AI engineering:
1. **Prompt Engineering** — asking better questions
2. **Context Engineering** — feeding better data
3. **Harness Engineering** — enforcing safe, consistent execution

## Quick Start

```bash
# Run in an empty project directory
bash <(curl -fsSL https://raw.githubusercontent.com/youngjin39/Claude-Code-Prompt-Harness/main/setup.sh)
```

The installer walks you through:

| Step | What it does |
|---|---|
| Project info | Name, language/framework, package manager |
| Language | User-facing output language (Korean, English, Japanese, Chinese, custom) |
| Module selection | Choose optional skills and MCP servers |
| Permission level | Strict / Standard / Permissive tool access |

After setup, start Claude Code with `claude` and the harness takes over.

### Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI
- `git`
- `jq` (pre-installed on macOS; `apt-get install jq` on Linux)

## Architecture

### 3-Axis Design

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

### Workflow Pipeline

```
Request → specificity signals? → none → deep-interview → classify
  ├─ Simple (1–2 steps) → orchestrator executes directly → self-check → done
  └─ Complex (3+ steps) → plan mode
       brainstorming → writing-plans → execution → verification → done
```

### Orchestration Presets

| Preset | Pipeline |
|---|---|
| feature | brainstorming → writing-plans → executor → testing → code-review → verification |
| bugfix | deep-interview(lite) → executor → testing → verification |
| refactor | brainstorming → writing-plans → executor → code-review → verification |
| security | code-review(security) → executor → verification |

## Components

### Agents (3)

| Agent | Model | Role |
|---|---|---|
| main-orchestrator | opus | Conversation, judgment, task classification, simple task execution |
| executor-agent | sonnet | Dedicated code writing for complex tasks |
| quality-agent | sonnet | Read-only adversarial review (Write/Edit forbidden) |

The quality-agent uses an **adversarial lens**: its job is to find what the executor missed, not to confirm the work.

### Skills (6 core + 2 optional)

**Core** (always installed):

| Skill | Trigger | Key Feature |
|---|---|---|
| brainstorming | design, architecture, new feature | Hard Gate. 2–3 alternatives with different lenses. Counter-narrative attack. Synthesis option. |
| writing-plans | plan, implementation plan | Bite-sized steps with concrete code. Banned: "add tests", "refactor as needed". |
| verification | verify, done check, proof | 6-stage gate + Red Team 6Q self-attack + hidden premise interrogation. |
| deep-interview | interview, requirements, clarify | Ambiguity scoring + bottleneck diagnosis (fact/logic/bias/execution). |
| git-commit | commit, git, save changes | Structured commit rules + trailers. |
| project-doctor | diagnose, doctor, health check | Structure + memory + context diagnostics. |

**Optional** (selected during setup):

| Skill | Trigger | Why Optional |
|---|---|---|
| code-review | review, PR, quality | Not all projects need formal PR review. |
| testing | test, TDD, unit test | Some projects handle testing externally. |

### MCP Servers

| Server | Role | Core/Optional |
|---|---|---|
| fetch | Web access | Core |
| Context7 | Latest library docs auto-injection | Optional |
| Sequential Thinking | Structured reasoning chains | Optional |

### Hooks (3)

| Hook | Event | Action |
|---|---|---|
| session-start.sh | SessionStart | Auto-inject plan.md + lessons.md + latest session |
| pre-compact.sh | PreCompact | Remind to write handoff before /compact |
| post-edit-check.sh | PostToolUse (Edit\|Write) | Debug statement + credential leak detection |

### 4-Type Skill Trigger System

| Type | How it fires | Example |
|---|---|---|
| Keyword | Request contains listed keywords | "test" → testing skill |
| Intent | Inferred user goal | "add feature" → brainstorming |
| File path | Changed file matches pattern | `*.test.*` → testing |
| Code pattern | Code contains risky patterns | external input → security review |

## Memory System (3 Layers)

| Layer | Location | Purpose | Lifecycle |
|---|---|---|---|
| Project Knowledge | `docs/` | Long-term memory, no decay | Permanent. Keyword-indexed. Max 50 lines/file. |
| Behavioral Rules | `tasks/lessons.md` | Failures/successes → rules | Promoted to rule after 2 repetitions. |
| Session Restore | `tasks/sessions/` | Ephemeral snapshots | Latest only. Older promoted or deleted. |

**Protocol**: At task start, scan keyword index → load only matching files → skip if no match (token savings). At task end, harvest new learnings.

## Principles

These govern all agent behavior at the highest level:

1. **Default is no-action.** Do not act without evidence. Unverified conclusions are void.
2. **Prohibition > instruction.** State what is forbidden before what is desired.
3. **No filler.** Every sentence must carry information. Ban repetition, hedging, padding.
4. **Simplicity first.** Minimum impact. Solve root causes.

## Built-in Prompt Techniques

The harness integrates proven prompt engineering techniques structurally, not as bolt-ons:

| Technique | Where Applied |
|---|---|
| Tree of Thoughts | brainstorming: 2–3 alternatives with different lenses |
| Graph of Thoughts | brainstorming: synthesis of best elements across options |
| Contrastive CoT | brainstorming: counter-narrative attack on attractive wrong choices |
| Maieutic Prompting | verification: hidden premise interrogation (Red Team Q6) |
| Self-Refinement | verification: Red Team 6Q self-attack after gate pass |
| Skeleton-of-Thought | All skills: structured Output Format templates |
| Plan-and-Solve | Pipeline architecture: preset-driven task flow |
| Reflexion | lessons.md: failure memory + 3-failure circuit breaker |
| Chain of Density | Principles: no-filler rule enforces information density |
| S2A (Fact-First) | "Read code before analysis" rule |

## Setup Options

### Permission Levels

| Level | What's auto-allowed | Best for |
|---|---|---|
| Strict | Nothing — asks for every tool | Maximum safety, learning Claude Code |
| Standard | Read, Glob, Grep, Agent, Skill | Daily development (recommended) |
| Permissive | All tools including Bash, Write, Edit | Experienced users, trusted environments |

### Module Selection

During setup, choose which optional modules to include:

```
Optional modules:
  [1] code-review skill  — PR/quality review
  [2] testing skill      — TDD enforcement
  [3] Context7 MCP       — latest library docs auto-injection
  [4] Sequential Thinking MCP — structured reasoning chains

Select [1-4, comma-separated, 'all', or 'none', default: all]:
```

Unselected modules are removed at setup time — no dead context, no wasted tokens.

## Project Structure

```
.
├── CLAUDE.md                    # Root configuration (AI constitution)
├── .mcp.json                    # MCP servers (dynamically generated)
├── setup.sh                     # Harness installer
├── .claude/
│   ├── settings.local.json      # Permissions + hooks
│   ├── agents/                  # 3 agents
│   ├── hooks/                   # 3 automation hooks
│   └── skills/                  # 6–8 skills (based on selection)
├── tasks/                       # Working memory (gitignored)
│   ├── plan.md                  # Current plan
│   ├── context.md               # Decision rationale
│   ├── checklist.md             # Progress tracking
│   ├── change_log.md            # Change history
│   ├── lessons.md               # Failure/success rules
│   ├── cost-log.md              # Token cost tracking
│   ├── handoffs/                # Phase handoff documents
│   ├── sessions/                # Session snapshots
│   └── log/                     # Completed task archive
└── docs/                        # Long-term memory (no decay)
    ├── memory-map.md            # Keyword index
    └── {category}/              # architecture, decisions, patterns, domain, risks, integrations, references
```

## Adding Domain Skills

Harness skills are universal. Domain skills are project-specific:

```bash
mkdir -p .claude/skills/my-domain-skill
cat > .claude/skills/my-domain-skill/SKILL.md << 'EOF'
---
name: my-domain-skill
description: "What it does. Trigger: keyword1, keyword2"
---
# My Domain Skill
## Procedure
1. ...
EOF
```

Then register in the Skill Keyword Table in `CLAUDE.md`.

## Acknowledgments

Designed with inspiration from:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD enforcement, Hard Gate pattern, verification philosophy.
- **[CLI-Anything](https://github.com/HKUDS/CLI-Anything)** — Agent harness structure, skill registry pattern.
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Write/Review separation, Deep Interview, circuit breaker.
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — Token optimization, lazy loading, model routing.

Prompt techniques informed by research on: ReAct, CoVE, Tree/Graph of Thoughts, Contrastive CoT, Maieutic Prompting, Self-Refinement, Chain of Density, Plan-and-Solve, Reflexion, Skeleton-of-Thought.

## License

MIT License.
