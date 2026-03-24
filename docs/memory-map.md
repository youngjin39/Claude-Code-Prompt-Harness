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
| Skill | Last Used | Count |
|---|---|---|
| brainstorming | — | 0 |
| code-review | — | 0 |
| deep-interview | — | 0 |
| git-commit | — | 0 |
| project-doctor | 2026-03-24 | 1 |
| testing | — | 0 |
| verification | — | 0 |
| writing-plans | — | 0 |

## Keyword → File Mapping
| Keywords | Category | File |
|---|---|---|
| superpowers, TDD, hard-gate, cli-anything, omc | references | [Repo Analysis](references/repo-analysis-summary.md) |
| 3-axis, pipeline, master-plan, workflow, memory | decisions | [Master Plan v2](decisions/master-plan-v2.md) |

## Category Index
| Category | Files | Description |
|---|---|---|
| architecture | (none) | System structure, design patterns |
| decisions | [Master Plan v2](decisions/master-plan-v2.md) | ADR + full design archive |
| patterns | (none) | Reusable code/workflow patterns |
| domain | (none) | Domain knowledge, business rules |
| risks | (none) | Known risks, vulnerabilities |
| integrations | (none) | External system APIs |
| references | [Repo Analysis](references/repo-analysis-summary.md) | Reference repo analysis |

## Protocols
- **Search**: Scan keyword table → Read matched file only → Skip if no match.
- **Store**: Create `docs/{category}/{topic}.md` with frontmatter → Add keyword row here.
- **Promote**: 2+ repetitions → lessons.md rule. Cross-project → ~/.claude/global-memory/.
