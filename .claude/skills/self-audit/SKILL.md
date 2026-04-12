---
name: self-audit
description: "Harness compliance self-check. Validates CLAUDE.md sections, .claude/ components, docs/ structure, and tasks/ files against the 21-element baseline.\n\nTrigger: self-audit, compliance, harness check, self-check, 자기점검"
user-invocable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash
---

# Self-Audit — Harness Compliance Check

Run this skill periodically to verify the project follows the harness baseline.
Unlike project-doctor (build/security/memory integrity), this skill checks **structural compliance** with the 21-element harness standard.

## Procedure

### Phase 1: CLAUDE.md Section Scan (21 items)
Read CLAUDE.md and check for presence of each required section.
Mark each as ✅ present, ⚠️ partial (exists but incomplete), ❌ missing.

| # | Required Section | Search Pattern | Pass Criteria |
|---|---|---|---|
| 1 | Development Environment | `## Development Environment` or `## Dev Environment` | Table with OS, Language/Framework, Package Manager rows |
| 2 | Build & Run | `## Build & Run` or `## Build` or `## Commands` | At least 1 runnable command |
| 3 | Project Structure | `## Project Structure` or `## Structure` | Tree diagram or structured listing |
| 4 | Workflow Pipeline | `## Workflow Pipeline` or `## Workflow` | Ambiguous Request Gate + Task Flow present |
| 5 | Agent Role Separation | `Agent Role Separation` or `### Agents` | Table with 3 agents (orchestrator, executor, quality) + Writes Code column |
| 6 | Branching Criteria | `Branching Criteria` | Simple (1~2) vs Complex (3+) distinction |
| 7 | Gate Conditions | `Gate Conditions` | Phase/Entry/Exit table with 4 rows |
| 8 | Built-in Rules | `Built-in Rules` | 4 rules: brainstorming alternatives, writing-plans concrete, execution circuit-breaker, verification evidence-only |
| 9 | Skill Trigger System | `Skill Trigger` or `Skill Keyword` | Keyword table with skill paths |
| 10 | Model Routing | `Model Routing` | Task-type → model table (haiku/sonnet/opus) |
| 11 | Memory System | `Memory System` | 3 layers described (docs, lessons, sessions) |
| 12 | Memory Usage Protocol | `Memory Usage Protocol` | 4-step: scan → read → skip → save |
| 13 | Autonomous Bug Fix | `Autonomous Bug Fix` | Section exists |
| 14 | Context Management | `Context Management` | compact + handoff + 20% rule + context recovery |
| 15 | Sub-agent Isolation | `Sub-agent Isolation` | 4 rules (no history, extract from handoff, 1=1, results only) |
| 16 | Automation Hooks | `Automation Hooks` | SessionStart + PreCompact + PostToolUse documented |
| 17 | Automatic Memory Harvesting | `Memory Harvesting` | Section exists |
| 18 | Quality Checks | `Quality Checks` | change_log + lint threshold + self-check |
| 19 | Project Management | `Project Management` | Start reading + update before changes + archive |
| 20 | Token Efficiency | `Token Efficiency` | 4 rules: no re-read, no restate, scope containment, session ground truth |
| 21 | Principles | `Principles` | no-action default + simplicity + root cause + prohibition>instruction + no filler (with specific bans) |

### Phase 2: .claude/ Component Check
Glob for files and compare against baseline:

| Component | Required | Check |
|---|---|---|
| Core skills | brainstorming, code-review, deep-interview, git-commit, project-doctor, self-audit, testing, verification, writing-plans | `ls .claude/skills/*/SKILL.md` |
| Agents | main-orchestrator, executor-agent, quality-agent | `ls .claude/agents/*.md` |
| Hooks | session-start.sh, pre-compact.sh, post-edit-check.sh | `ls .claude/hooks/*.sh` |

Domain-specific skills/agents beyond baseline are noted but not flagged.

### Phase 3: docs/ Structure Check
| Required | Check |
|---|---|
| memory-map.md | Exists + has keyword entries (not empty template) |
| 7 subdirectories | architecture/, decisions/, patterns/, domain/, risks/, integrations/, references/ |

### Phase 4: tasks/ File Check
| Required | Check |
|---|---|
| Core files | plan.md, context.md, checklist.md, change_log.md, lessons.md, cost-log.md |
| Directories | handoffs/, sessions/, log/ |
| plan.md size | ≤ 50 lines (warn if exceeded) |

### Phase 5: Cross-Validation
- Skill Keyword Table in CLAUDE.md lists paths → verify those paths exist
- memory-map.md file references → verify files exist
- Agent table in CLAUDE.md → verify agent .md files exist

## Scoring
- ✅ = 1 point
- ⚠️ = 0.5 points
- ❌ = 0 points
- Score = points / 21 × 100%

## Grade Scale
| Grade | Score | Meaning |
|---|---|---|
| A | 90-100% | Fully compliant |
| B | 70-89% | Minor gaps — fix in current session |
| C | 50-69% | Significant gaps — schedule dedicated session |
| D | < 50% | Major overhaul needed |

## Output
```
## Self-Audit Report — Harness Compliance
Date: {YYYY-MM-DD}
Project: {project name from CLAUDE.md}

### CLAUDE.md Sections (21 items)
| # | Section | Status | Note |
|---|---|---|---|
| 1 | Development Environment | ✅/⚠️/❌ | {detail} |
| ... | ... | ... | ... |

### .claude/ Components
| Component | Expected | Found | Missing |
|---|---|---|---|
| Skills | 9 core | {N} | {list} |
| Agents | 3 | {N} | {list} |
| Hooks | 3 | {N} | {list} |

### docs/ Structure
| Item | Status | Note |
|---|---|---|
| memory-map.md | ✅/❌ | {detail} |
| 7 subdirectories | {N}/7 | {missing list} |

### tasks/ Files
| Item | Status |
|---|---|
| {file} | ✅/❌ |

### Cross-Validation
| Check | Status | Note |
|---|---|---|
| Skill paths match | ✅/❌ | {phantom entries} |
| Memory-map refs valid | ✅/❌ | {broken refs} |

### Summary
- Score: {N}/21 ({%})
- Grade: {A/B/C/D}
- ✅: {N} / ⚠️: {N} / ❌: {N}

### Fix Priority (❌ items first, then ⚠️)
1. {item}: {concrete fix instruction}
2. ...
```

### Phase 6: Skill Stocktake (Quality Audit)
For each skill in `.claude/skills/*/SKILL.md`:

| Check | Method | Verdict |
|---|---|---|
| **Size** | Line count. >400 = oversized, >200 = heavy | Flag |
| **Usage** | memory-map.md Skill Usage table `count` column. 0 after 30+ days since creation = dormant | Warn |
| **Overlap** | Compare trigger keywords across all skills. >50% keyword overlap between two skills = potential merge candidate | Flag |
| **Freshness** | Check if skill references external tools/URLs → verify they still exist (quick WebFetch or which check) | Warn if broken |
| **Clarity** | Has clear Procedure section? Has explicit Output format? Has Hard Rules? | ⚠️ if missing any |

Verdicts per skill:
- **Keep** — healthy, actively used, no issues
- **Improve** — has quality gaps (missing procedure, unclear output, no hard rules)
- **Update** — references stale tools or outdated patterns
- **Retire** — dormant + overlaps with another skill (requires user confirmation)
- **Merge** — >50% keyword overlap with another skill (requires user confirmation)

Output table:
```
### Skill Stocktake
| Skill | Lines | Usage | Overlap | Freshness | Clarity | Verdict |
|---|---|---|---|---|---|---|
| {name} | {N} | {count} | {overlap target or —} | ✅/⚠️ | ✅/⚠️ | Keep/Improve/Update/Retire/Merge |
```

**Important**: Retire and Merge are suggestions only. Never auto-delete skills.

## Rules
- Run at least once per month or after major changes.
- Do not auto-fix — report only. User decides what to act on.
- Domain-specific additions (extra skills, custom docs dirs) are not violations — note them as extensions.
- Non-code projects may mark Build & Run as "N/A" — this counts as ✅ if explicitly stated.
