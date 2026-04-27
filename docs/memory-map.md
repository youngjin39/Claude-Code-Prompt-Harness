---
title: Neuron Memory Map — Keyword Index
keywords: [memory, index, keyword, search, storage]
created: 2026-03-20
last_used: 2026-03-24
type: index
---

# Memory Map

> Load only what you need. Never read an entire category at once.
> Memory files: ≤50 lines, YAML frontmatter required. 100+ files → consider SQLite.

## Skill Usage Tracking
Manual snapshot only. Do not classify a skill as dormant from zero counts alone.

### Core Skills
| Skill | Last Used | Count |
|---|---|---|
| brainstorming | — | 0 |
| code-review | — | 0 |
| deep-interview | — | 0 |
| git-commit | — | 0 |
| project-doctor | 2026-03-24 | 1 |
| self-audit | — | 0 |
| testing | — | 0 |
| ux-ui-design | — | 0 |
| verification | — | 0 |
| writing-plans | — | 0 |

### Optional Skills
| Skill | Last Used | Count |
|---|---|---|
| browser-automation | — | 0 |
| code-review-graph | — | 0 |
| knowledge-ingest | — | 0 |
| knowledge-lint | — | 0 |

## Keyword → File Mapping
| Keywords | Category | File |
|---|---|---|
| superpowers, TDD, hard-gate, cli-anything, omc, harness, everything-claude-code | references | [Repo Analysis](references/repo-analysis-summary.md) |
| 3-axis, pipeline, master-plan, workflow, memory, context | decisions | [Master Plan v2](decisions/master-plan-v2.md) |
| audit, optimization, refactoring, stabilization, integrity | decisions | [Optimization Log](decisions/optimization-log.md) |
| computer-use, gui, screenshot, e2e, simulator, ui-testing | integrations | [Computer Use GUI Testing](integrations/computer-use-gui-testing.md) |
| blueprint, module, analysis, reassemble, code-analysis | patterns | [Module Blueprint System](patterns/module-blueprint-system.md) |
| codex, external-review, github-pr, openai | integrations | [Codex Code Review](integrations/codex-code-review.md) |
| claude, codex, derivation, one-way-sync, migration, rollout | integrations | [Claude-to-Codex Derivation](integrations/claude-to-codex-derivation.md) |
| project, family, classification, bootstrap, migrate, survey, startup | integrations | [Project Family Classification](integrations/project-family-classification.md) |
| codex, boundary, bootstrap, starter, verifier, derivation | integrations | [Prompt Starter Codex Use Boundary](integrations/codex-use-boundary.md) |
| claude, runtime, workflow, hooks, memory, operations | architecture | [Claude Runtime Guide](operations/claude-runtime.md) |
| codex, runtime, generated, agents, skills, default-model | architecture | [Codex Runtime Guide](operations/codex-runtime.md) |
| hooks, contract, sessionstart, pretooluse, posttooluse, precompact, sessionend, tdd | architecture | [Hook Contract Guide](operations/hook-contract.md) |
| harness, claude, codex, parity, hooks, state, self-review, validation, workflow | architecture | [Harness Application Guide](operations/harness-application.md) |
| starter, maintenance, mode, classification, parity, integrity, regeneration, verification | architecture | [Starter Maintenance Mode](operations/starter-maintenance-mode.md) |
| reporting, progress, result, discussion, readability, user-facing | architecture | [User Reporting Format](operations/user-reporting-format.md) |
| error, failure, parse, retry, taxonomy, recovery, unknown, transient | patterns | [Error Handling](patterns/error-handling.md) |
| sync, manifest, change-detection, generated-files, stale, drift | patterns | [One-Way Sync Manifest](patterns/one-way-sync-manifest.md) |
| context-budget, token, overhead, MCP cost, session overhead, bloat | references | [ECC Context Budget Thresholds](references/ecc-context-budget.md) |
| mempalace, temporal, knowledge-graph, time-aware, decision-tracking | references | [MemPalace Temporal KG](references/mempalace-temporal-kg.md) |

## Category Index
| Category | Files | Description |
|---|---|---|
| architecture | [Claude Runtime Guide](operations/claude-runtime.md), [Codex Runtime Guide](operations/codex-runtime.md), [Hook Contract Guide](operations/hook-contract.md), [Harness Application Guide](operations/harness-application.md), [Starter Maintenance Mode](operations/starter-maintenance-mode.md), [User Reporting Format](operations/user-reporting-format.md) | System structure, design patterns |
| decisions | [Master Plan v2](decisions/master-plan-v2.md), [Optimization Log](decisions/optimization-log.md) | ADR + full design archive |
| patterns | [Module Blueprint System](patterns/module-blueprint-system.md), [One-Way Sync Manifest](patterns/one-way-sync-manifest.md) | Reusable code/workflow patterns |
| domain | (none) | Domain knowledge, business rules |
| risks | (none) | Known risks, vulnerabilities |
| integrations | [Computer Use GUI Testing](integrations/computer-use-gui-testing.md), [Codex Code Review](integrations/codex-code-review.md), [Claude-to-Codex Derivation](integrations/claude-to-codex-derivation.md), [Project Family Classification](integrations/project-family-classification.md), [Prompt Starter Codex Use Boundary](integrations/codex-use-boundary.md) | External system APIs |
| references | [Repo Analysis](references/repo-analysis-summary.md), [ECC Context Budget](references/ecc-context-budget.md), [MemPalace Temporal KG](references/mempalace-temporal-kg.md) | Reference repo analysis |

## Protocols
- **Search**: Scan keyword table → Read matched file only → If file has `related` field, consider loading related files too → Skip if no match.
- **Store**: Create `docs/{category}/{topic}.md` with frontmatter (title, keywords, related, created, last_used) → Add keyword row here.
- **Cascade**: On store, check keyword table for existing files sharing keywords. Review for contradiction/overlap → update affected files + their `last_used`. A single insight may touch multiple files.
- **Promote**: 2+ repetitions → lessons.md rule. Cross-project → ~/.claude/global-memory/.
