# Mir Claude Starter

An opinionated Claude Code starter — a one-command installer that drops 3 agents, 14 skills, 6 hooks, a 3-layer memory system, an `execute.py` state engine, and a gate-enforced pipeline into any new project. Tuned by 24 rounds of integrity audit (30+ fixes).

> **[한국어 README](README.ko.md)**

## Positioning

This is a **starter**, not a full harness. A real harness enforces rules structurally — forbidden-path blockers, runtime state files (`state/current-task.json`), architecture tests that fail the build. This starter covers the first two engineering stages and partially the third:

| Stage | Coverage |
|---|---|
| 1. Prompt Engineering — better questions | ✅ skills + 4-type trigger system |
| 2. Context Engineering — better data feeding | ✅ 3-layer memory + JIT keyword index |
| 3. Harness Engineering — structural enforcement | ⚠️ partial (6 hooks, soft gates, state engine; full enforcement is roadmap) |

Full harness work is tracked separately. Use this starter to bootstrap a project with sensible defaults; graduate to a real harness when the project demands it.
The core contract is optimized for AI self-recognition: the always-read docs tell the agent which runtime it is in, which mode is active, what enforces policy, and what proves completion.

## Quick Start

```bash
# Run in an empty project directory
bash <(curl -fsSL https://raw.githubusercontent.com/youngjin39/mir-claude-starter/main/setup.sh)
```

The installer walks you through:

| Step | What it does |
|---|---|
| **Language** | Pick installer language first — English, Korean, Japanese, Chinese, or custom. All subsequent prompts appear in the chosen language. |
| Project info | Name, language/framework, package manager |
| Preset | Pick from 10 stack presets or Custom (auto-fills stack + modules + permissions) |
| Module selection | Choose optional skills and MCP servers, defaulting to core-only for Custom installs (skipped if preset chosen) |
| Permission level | Strict / Standard / Permissive tool access (skipped if preset chosen) |

### Project Presets

| # | Preset | Stack | Auto-config |
|---|---|---|---|
| 1 | Flutter Mobile App | Dart/Flutter, pub | testing+code-review, Context7 |
| 2 | Next.js Web App | TypeScript/Next.js, pnpm | testing+code-review, Context7+SeqThink |
| 3 | Node/TS Backend API | TypeScript/Node, npm | testing+code-review, SeqThink |
| 4 | Python Backend | Python/FastAPI, uv | testing+code-review, Context7 |
| 5 | Python Data/ML | Python, uv | testing, SeqThink |
| 6 | Rust Systems | Rust, cargo | testing+code-review, Strict perms |
| 7 | Go Service | Go, go mod | testing+code-review |
| 8 | Embedded C/C++ | C/C++, cmake | code-review only, Strict perms |
| 9 | Claude-only Agent | no code, content/judgment | no testing, SeqThink |
| 10 | Static Site / Docs | Astro or Hugo, npm | minimal modules |
| 11 | Custom | manual entry | (current behavior) |

After setup, start Claude Code with `claude` and the starter pipeline takes over.

### Project Family Setup

Before expanding the starter into a long-lived repo, classify the repository family first. Use [`docs/integrations/project-family-classification.md`](docs/integrations/project-family-classification.md) as the startup rubric.

| Question | Output |
|---|---|
| What kind of repo is this? | `app-product`, `director-pipeline`, `personal-knowledge`, `infra-runtime`, `starter-template`, or `sealed-migration` |
| How much existing harness/history does it already have? | `greenfield`, `active-custom`, or `high-context` |
| What rollout posture fits that risk? | `push/init`, `migrate`, `skip-migrate + profile`, `bootstrap only + boundary`, or `supersede` |

Recommended setup flow:

1. Run the starter installer in the target repository.
2. Classify the family with `docs/integrations/project-family-classification.md`.
3. Choose the rollout posture:
   - `push/init` for greenfield app repos
   - `migrate` for existing repos with custom `.claude/` assets worth preserving
   - `skip-migrate + profile` for high-context repos where Codex should be bounded first
   - `bootstrap only + boundary` for infra/runtime/template repos where Codex bootstrap is useful but Mir should not own the repo
   - `supersede` for transitional template/meta layers that should be absorbed, not migrated
4. Generate the Codex derivation layer only after the posture is clear:

```bash
python3 scripts/verify_starter_integrity.py
bash scripts/generate_codex_derivatives.sh
python3 scripts/verify_codex_sync.py
```

For existing repositories, do not normalize everything up front. Keep family-specific assets explicit:

- `migrate` repos need preserve artifacts and backup history
- `skip-migrate` repos need a local Codex use/review profile
- `bootstrap-only` repos need a local Codex use boundary

### Codex Derivation Layer

This starter now includes a checked-in `.codex-sync/` layer for teams that want to keep `Claude` as the source of truth and derive `Codex` artifacts in a one-way flow.

| Asset | Purpose |
|---|---|
| `.codex-sync/manifest.template.json` | Source-to-target mapping for change detection |
| `.codex-sync/manifest.json` | Current repository mapping generated from Claude sources |
| `.codex-sync/rollout-checklist.md` | Repeatable rollout process across many repositories |
| `docs/integrations/claude-to-codex-derivation.md` | Operating strategy for one-way derivation |
| `docs/patterns/one-way-sync-manifest.md` | Drift detection and maintenance pattern |

This is intentionally not a bidirectional sync model. Edit Claude files first, regenerate Codex files second.
Codex parity in this starter is documented as manual compliance plus verifier-checked contract drift. It is not native pre-execution blocking or behavioral parity.

Generate the Codex layer with:

```bash
python3 scripts/verify_starter_integrity.py
bash scripts/generate_codex_derivatives.sh
python3 scripts/verify_codex_sync.py
```

The default derivation profile is `core`, which keeps Codex output compact and checks in only the main workflow skills. Generated Codex config and agent files intentionally do not pin a model, so Codex can use its current default selection. Use `CODEX_DERIVATION_PROFILE=full` when you want the broader portable skill set.

If your current tool session protects hidden target directories, generate into staging first:

```bash
CODEX_DERIVATION_OUTPUT_ROOT=.codex-sync/staging bash scripts/generate_codex_derivatives.sh
```

After broader starter maintenance, run `python3 scripts/verify_starter_integrity.py`. After regeneration, run `python3 scripts/verify_codex_sync.py` to catch missing manifest targets, stale checked-in skill sets, or drift between generator output and docs.

Runtime-level hook behavior is documented separately in `docs/operations/hook-contract.md` so startup/load rules, TDD blocking, and post-edit checks are not duplicated ad hoc across prompts.

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
  └─ Complex (3+ steps) → choose pipeline
       unresolved design / new feature / architecture change
         → brainstorming → writing-plans → executor-agent → verification → done
       concrete scoped execution / obvious path
         → writing-plans → executor-agent → verification → done
```

## Components

### Agents (3)

| Agent | Model | Role |
|---|---|---|
| main-orchestrator | opus | Conversation, judgment, task classification, simple task execution, starter-maintenance coordination |
| executor-agent | sonnet | Dedicated code writing for complex tasks and starter contract updates |
| quality-agent | sonnet | Read-only adversarial review, including starter drift checks (Write/Edit forbidden) |

The quality-agent uses an **adversarial lens**: its job is to find what the executor missed, not to confirm the work.

When you change the starter itself, treat agents, hooks, skills, scripts, generated Codex artifacts, and user-facing docs as one contract. Run `python3 scripts/verify_starter_integrity.py` before claiming the starter is updated.
The contract is not only for humans. It is written so the agent can classify its runtime and gates from the files it reads first.

### Skills (10 core + optional add-ons)

**Core** (always installed):

| Skill | Trigger | Key Feature |
|---|---|---|
| brainstorming | design, architecture, new feature | Hard Gate. 2–3 alternatives with different lenses. Counter-narrative attack. Synthesis option. |
| writing-plans | plan, implementation plan | Bite-sized steps with concrete code. Banned: "add tests", "refactor as needed". |
| verification | verify, done check, proof | 6-stage gate + Red Team 6Q self-attack + hidden premise interrogation. |
| deep-interview | interview, requirements, clarify | Ambiguity scoring + bottleneck diagnosis (fact/logic/bias/execution). |
| testing | test, TDD, unit test | Test discovery, test creation, execution, and edge-case checks. |
| code-review | review, PR, quality | Structured severity-based review with exact evidence. |
| ux-ui-design | ui, ux, screen, frontend | UI hard gate: flow + wireframe + component spec before implementation. |
| git-commit | commit, git, save changes | Structured commit rules + trailers. |
| project-doctor | diagnose, doctor, health check | Structure + memory + context diagnostics. |
| self-audit | audit, integrity, drift | Starter compliance and drift audit. Core because starter verification depends on it. |

**Optional** (opt-in during setup, default is none for Custom installs):

| Skill | Trigger | Why Optional |
|---|---|---|
| knowledge-ingest / knowledge-lint | wiki, source ingest | Useful only when a project wants an LLM-maintained wiki. |
| browser-automation | browser, GUI, screenshots | Useful only for UI/browser-heavy projects. |
| code-review-graph | blast radius, graph review | Useful only when local graph tooling is installed. |

### MCP Servers

| Server | Role | Core/Optional |
|---|---|---|
| Context7 | Latest library docs auto-injection | Optional |
| Sequential Thinking | Structured reasoning chains | Optional |

### Hooks (6)

| Hook | Event | Action |
|---|---|---|
| session-start.sh | SessionStart | Auto-inject plan.md + lessons.md + memory-map.md + latest session |
| pre-compact.sh | PreCompact | Auto-create a handoff skeleton before /compact (advisory; the agent must complete it) |
| pre-tool-use.sh | PreToolUse (Bash\|Edit\|Write) | Input-stage guardrail: block destructive patterns + denied paths |
| tdd-guard.sh | PreToolUse (Edit\|Write) | Block edits to existing implementation files with no related tests |
| post-edit-check.sh | PostToolUse (Edit\|Write) | Debug statement + credential leak detection |
| session-end.sh | SessionEnd | Auto-save session snapshot + memory harvesting reminder |

Repeated guard failures are tracked through `execute.py record-incident`, giving you a built-in 60-second / 5-hit circuit breaker warning without requiring a separate daemon.

### Error Taxonomy + Output Parsing Recovery

Every failure is classified into one of four classes — response is determined by class, not by the error message:

| Class | Response |
|---|---|
| transient | Exponential backoff (1s → 4s → 10s), max 3 retries |
| model-fixable | Feed error back as observation, revise call, max 3 attempts |
| interrupt | STOP, escalate to user (destructive/ambiguous/scope expansion) |
| unknown | Log to lessons.md, STOP, no improvisation |

Output parsing failures go through partial-extract → feedback round → unknown escalation. "Assume default on missing field" and "retry with same prompt" are explicitly banned.

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

The starter integrates proven prompt engineering techniques structurally, not as bolt-ons:

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

Select [1-4, comma-separated, 'all', or 'none', default: none]:
```

Unselected modules are removed at setup time — no dead context, no wasted tokens.

## Custom Harness Docs

The starter ships four project-level harness docs. Fill these before substantial implementation work:

- `PRD.md` — scope, MVP boundaries, UX priorities, edge cases, error-handling expectations
- `ARCHITECTURE.md` — allowed patterns, wrappers, boundaries, failure modes, verification rules
- `ADR.md` — short decision log for why a major choice was made
- `UI_GUIDE.md` — visual direction, UX rules, accessibility, anti-patterns

Use them as hard constraints, not background notes. If your project requires "all API calls must go through our wrapper", "DB schema is frozen", or "no third-party state library", those rules belong here.

## Project Structure

```
.
├── CLAUDE.md                    # Slim always-read Claude runtime charter
├── AGENTS.md                    # Slim always-read Codex runtime charter
├── .mcp.json                    # MCP servers (dynamically generated)
├── execute.py                   # Harness state engine + optional auto-commit
├── harness/
│   ├── README.md                # Harness runtime guide
│   └── state/                   # Local runtime state (generated)
├── .codex-sync/                 # one-way Claude -> Codex derivation metadata
├── .codex/                      # generated Codex config + custom agents
├── .agents/                     # generated Codex skills
├── PRD.md                       # product scope, MVP, UX priorities, edge cases
├── ARCHITECTURE.md              # boundaries, wrappers, data flow, failure modes
├── ADR.md                       # short architecture decision log
├── UI_GUIDE.md                  # visual system, UX rules, anti-patterns
├── scripts/
│   └── generate_codex_derivatives.sh
├── setup.sh                     # Starter installer
├── .claude/
│   ├── settings.local.json      # Permissions + hooks
│   ├── agents/                  # 3 agents
│   ├── hooks/                   # 6 automation hooks
│   └── skills/                  # 10 core + opt-in extensions
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
    ├── operations/              # runtime guides split out of always-read files
    └── {category}/              # architecture, decisions, patterns, domain, risks, integrations, references
```

## Adding Domain Skills

Starter skills are universal. Domain skills are project-specific:

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

## Multi-Repo Codex Migration

If you need the same `Claude -> Codex` strategy across many repositories or agent packs, copy `.codex-sync/` into each repository and keep the manifest schema identical. The source-of-truth model should stay the same everywhere: Claude files are edited, Codex files are regenerated, stale targets are treated as failures.

Then register it in the compact trigger table in `CLAUDE.md`.

## Acknowledgments

Designed with inspiration from:

- **[Superpowers](https://github.com/obra/superpowers)** — TDD enforcement, Hard Gate pattern, verification philosophy.
- **[Archon](https://github.com/coleam00/Archon)** — Deterministic workflow engine, explicit validation gates, execution state discipline.
- **[CLI-Anything](https://github.com/HKUDS/CLI-Anything)** — Agent harness structure, skill registry pattern.
- **[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode)** — Write/Review separation, Deep Interview, circuit breaker.
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** — Token optimization, lazy loading, model routing.
- **[ByteRover CLI](https://github.com/campfirein/byterover-cli)** — Context Tree architecture analysis: cascade update, cross-reference (`related` field), memory lint patterns.
- **[LLM Wiki (Karpathy)](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** — Persistent compounding knowledge base pattern: cascade update on ingest, contradiction detection, wiki lint.
- **[Obsidian Mind](https://github.com/breferrari/obsidian-mind)** — SessionEnd hook pattern for auto-saving session snapshots on exit.

Prompt techniques informed by research on: ReAct, CoVE, Tree/Graph of Thoughts, Contrastive CoT, Maieutic Prompting, Self-Refinement, Chain of Density, Plan-and-Solve, Reflexion, Skeleton-of-Thought.

## License

MIT License.
