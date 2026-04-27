<!-- GENERATED FILE: edit .claude/skills/git-commit/SKILL.md and rerun scripts/generate_codex_derivatives.sh -->
---
name: git-commit
description: "Git commit rules + structured trailers.\n\nTrigger: commit, git, save changes"
---

# Git Commit

## Format
```
type(scope): summary

body (optional)

Constraint: (constraints on this change)
Rejected: (alternatives considered + why rejected)
Directive: (requirement/instruction this follows)
Not-tested: (scenarios not covered by tests)
```

## Types
type: feat|fix|refactor|docs|test|chore|style|perf
summary: English, present tense, ≤50 chars, lowercase start.

## Trailer Rules
- **Constraint**: always include. `none` if none.
- **Rejected**: when alternatives were discarded in brainstorming. Omit otherwise.
- **Directive**: user instruction or requirement ID. Omit if none.
- **Not-tested**: scenarios outside test coverage. `none` if fully covered.

## Procedure
1. git status.
2. Stage logical units (related changes only).
3. Write message + trailers.
4. Pre-commit check:
   - .env, secrets, build artifacts must not be included.
   - Debug code (console.log, print) must not be included.
5. Commit.

## Example
```
feat(auth): add JWT refresh token rotation

Implement automatic token refresh when access token
expires within 5 minutes of request.

Constraint: must be backward-compatible with existing sessions
Rejected: cookie-based refresh — XSS risk in current SPA architecture
Directive: USER-REQ-042
Not-tested: concurrent refresh from multiple tabs
```
