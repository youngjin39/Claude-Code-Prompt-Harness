---
name: project-doctor
description: "Project health check + memory integrity.\n\nTrigger: diagnose, doctor, health check, status"
user-invocable: true
context: fork
allowed-tools: Read, Grep, Glob, Bash
---

# Project Doctor

## Structure Check
1. CLAUDE.md exists + ≤200 lines.
2. tasks/ required files exist (plan, context, checklist, change_log, lessons, cost-log).
3. settings.local.json permissions valid.
4. Skill folders match CLAUDE.md trigger table (glob → compare).
5. Agent files exist (orchestrator, executor, quality).
6. .env in .gitignore (if applicable).

## Build/Quality Check
7. Build runnable (if applicable).
8. Lint/type check runnable (if applicable).

## Memory Integrity Check
9. docs/memory-map.md exists.
10. All file paths in memory-map.md actually exist.
11. docs/ .md files have frontmatter (title, keywords). Index files (`type: index`) exempt from content rules.
12. No docs/ file exceeds 50 lines (exception: `type: archive` in frontmatter).

## Memory Lint Check
13. Orphan files: docs/ .md files not listed in memory-map.md Keyword table or Category Index.
14. Phantom entries: memory-map.md references files that don't exist on disk.
15. Contradiction scan: files sharing ≥2 keywords → skim for conflicting claims → warn.
16. Missing cross-refs: files sharing keywords but lacking `related` field pointing to each other.
17. Stale content: `last_used` > 90 days → warn (review, not delete).
18. Gap detection: scan CLAUDE.md + lessons.md for recurring concepts/terms that lack a corresponding docs/ page → suggest documentation.

## Context Efficiency Check
19. plan.md ≤ 50 lines.
20. CLAUDE.md has trigger table (no skill body inline).
21. tasks/handoffs/ and tasks/sessions/ directories exist.

## Skill Health Check
22. Each skill's referenced commands exist (e.g., `npm run lint` → package.json has lint script).
23. CLAUDE.md trigger table paths match actual SKILL.md files (no phantom entries).
24. Skills with `last_used` > 30 days in memory-map.md Skill Usage table → warn as stale. Skip skills with `—` (never used).

## Security Scan
25. No credential patterns in .md/.json/.yaml/.sh files (sk-, ghp_, gho_, AIza, xoxb-, AKIA, aws_secret_access_key).
26. No dangerous shell patterns in skill files (rm -rf /, curl|sh, eval).
27. .env files listed in .gitignore.

## Output
```
## Project Doctor Report
| # | Item | Result | Note |
|---|---|---|---|
| 1 | CLAUDE.md | ✅/⚠️/❌ | {line count} |
| 2 | tasks/ files | ✅/❌ | {missing files} |
| ... | ... | ... | ... |

### Summary
- ✅: {N}
- ⚠️: {N}
- ❌: {N}

### Fix Suggestions
(Concrete fix for each ❌ and ⚠️)
```
