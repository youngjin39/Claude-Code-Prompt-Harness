<!-- GENERATED FILE: edit .claude/skills/self-audit/SKILL.md and rerun scripts/generate_codex_derivatives.sh -->
---
name: self-audit
description: "Starter compliance self-check. Validates current CLAUDE.md runtime sections, .claude/ components, docs/ structure, and tasks/ files against the active starter contract.\n\nTrigger: self-audit, compliance, starter check, self-check, 자기점검"
user-invocable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash
---

# Self-Audit — Starter Compliance Check

Run this skill periodically to verify the project follows the starter baseline.
Unlike project-doctor (build/security/memory integrity), this skill checks **structural compliance** with the current starter contract.

## Procedure

### Phase 0: Starter Integrity Gate
Run:
```bash
python3 scripts/verify_starter_integrity.py
python3 scripts/verify_codex_sync.py
```

- If `verify_starter_integrity.py` fails, report those failures first.
- Do not duplicate the same findings manually unless the script output is incomplete.
- Treat script output as the fast-path integrity baseline for starter structure + manifest/doc/generated drift.

### Phase 1: CLAUDE.md Section Scan (16 items)
Read CLAUDE.md and check for presence of each required section.
Mark each as ✅ present, ⚠️ partial (exists but incomplete), ❌ missing.

| # | Required Section | Search Pattern | Pass Criteria |
|---|---|---|---|
| 1 | Development Environment | `## Development Environment` or `## Dev Environment` | Table with OS, Language/Framework, Package Manager rows |
| 2 | Build & Run | `## Build & Run` or `## Build` or `## Commands` | At least 1 runnable command |
| 3 | Project Structure | `## Project Structure` or `## Structure` | Tree diagram or structured listing |
| 4 | Required Reads | `## Required Reads` | Startup + conditional reference docs present |
| 5 | Workflow | `## Workflow` | 0-signal, simple, and complex routing present |
| 6 | Mode Classification | `## Mode Classification` | Starter Maintenance + Cross-Harness rules present |
| 7 | Agent / Skill / Hook Contract | `## Agent / Skill / Hook Contract` | Agent roles + hook mirror contract present |
| 8 | Harness Defaults | `## Harness Defaults` | default runtime + opt-in scope present |
| 9 | Custom Harness Rules | `## Custom Harness Rules` | current hard-rule policy present |
| 10 | Codex Derivation Layer | `## Codex Derivation Layer` | source-of-truth + regenerate rule present |
| 11 | Skill Trigger Table | `## Skill Trigger Table` | core default list + skill path table present |
| 12 | Context Management | `## Context Management` | handoff + compact timing rules present |
| 13 | Language Protocol | `## Language Protocol` | Korean/English split + scannable reports present |
| 14 | Surgical Change Rules | `## Surgical Change Rules` | minimum-change scope rules present |
| 15 | Token Efficiency | `## Token Efficiency` | no re-read + no restate + ground-truth rules present |
| 16 | Principles | `## Principles` | evidence-first + minimum-change + no-filler present |

### Phase 2: .claude/ Component Check
Glob for files and compare against baseline:

| Component | Required | Check |
|---|---|---|
| Core skills | brainstorming, code-review, deep-interview, git-commit, project-doctor, self-audit, testing, ux-ui-design, verification, writing-plans | `ls .claude/skills/*/SKILL.md` |
| Agents | main-orchestrator, executor-agent, quality-agent | `ls .claude/agents/*.md` |
| Hooks | session-start.sh, pre-compact.sh, pre-tool-use.sh, tdd-guard.sh, post-edit-check.sh, session-end.sh | `ls .claude/hooks/*.sh` |

Domain-specific skills/agents beyond baseline are noted but not flagged.

### Phase 3: docs/ Structure Check
| Required | Check |
|---|---|
| memory-map.md | Exists + has keyword entries (not empty template) |
| 7 subdirectories | architecture/, decisions/, patterns/, domain/, risks/, integrations/, references/ |
| operations docs | claude-runtime.md, codex-runtime.md, hook-contract.md, harness-application.md, starter-maintenance-mode.md |

### Phase 4: tasks/ File Check
| Required | Check |
|---|---|
| Core files | plan.md, context.md, checklist.md, change_log.md, lessons.md, cost-log.md |
| Directories | handoffs/, sessions/, log/ |
| plan.md size | ≤ 50 lines (warn if exceeded) |

### Phase 5: Cross-Validation
- Skill Keyword Table in CLAUDE.md lists paths → verify those paths exist
- memory-map.md file references → verify files exist
- Required hooks/skills/agents from verifier baseline → verify files exist
- Self-recognition contract stays aligned across `CLAUDE.md`, `AGENTS.md`, runtime docs, and README summary text
- Reuse `scripts/verify_starter_integrity.py` and `scripts/verify_codex_sync.py` output instead of re-deriving starter/doc drift manually

## Scoring
- ✅ = 1 point
- ⚠️ = 0.5 points
- ❌ = 0 points
- Score = points / 16 × 100%

## Grade Scale
| Grade | Score | Meaning |
|---|---|---|
| A | 90-100% | Fully compliant |
| B | 70-89% | Minor gaps — fix in current session |
| C | 50-69% | Significant gaps — schedule dedicated session |
| D | < 50% | Major overhaul needed |

## Output
```
## Self-Audit Report — Starter Compliance
Date: {YYYY-MM-DD}
Project: {project name from CLAUDE.md}

### CLAUDE.md Sections (16 items)
| # | Section | Status | Note |
|---|---|---|---|
| 1 | Development Environment | ✅/⚠️/❌ | {detail} |
| ... | ... | ... | ... |

### .claude/ Components
| Component | Expected | Found | Missing |
|---|---|---|---|
| Skills | 10 core | {N} | {list} |
| Agents | 3 | {N} | {list} |
| Hooks | 6 | {N} | {list} |

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
| Self-recognition contract aligned | ✅/❌ | {missing or drifted files} |

### Summary
- Score: {N}/16 ({%})
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
| **Usage** | Treat memory-map.md Skill Usage table as a manual signal only. If it is stale or all-zero, flag the tracker instead of marking the skill dormant. | Warn |
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
