---
name: code-review
description: "Code review and quality check.\n\nTrigger: review, PR, quality, merge check, post-completion"
context: fork
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review

## Procedure
1. Identify changed files (change_log.md or git diff).
2. Per file: error handling gaps, security risks, naming violations, duplication, unnecessary complexity.
3. Classify: CRITICAL / WARNING / INFO.
4. Structured report with evidence (cite exact lines).

## Checklist
- [ ] Error handling (missing try/catch, unhandled promises)
- [ ] Security (injection, auth, credential exposure)
- [ ] Naming conventions (consistent with project)
- [ ] No duplication (DRY violations)
- [ ] No over-engineering (YAGNI violations)

## Output
```
## Code Review
| File | Severity | Finding | Evidence |
|---|---|---|---|
| {file}:{line} | CRITICAL/WARNING/INFO | {issue} | {code snippet} |

### Summary
- CRITICAL: {N}
- WARNING: {N}
- INFO: {N}

### Verdict
APPROVE / REQUEST_CHANGES / BLOCK
```
