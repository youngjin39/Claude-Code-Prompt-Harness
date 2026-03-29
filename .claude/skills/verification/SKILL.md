---
name: verification
description: "Evidence-based verification + 6-stage gate. No unverified completion.\n\nTrigger: verify, done check, proof, self-check"
---

# Verification

## Iron Law
Claiming completion without proof is lying.

## Banned Expressions
- "should work" / "probably fine"
- "looks correct" / "seems right"
- "I believe" / "I think"

## 6-Stage Gate
```
Build → Type Check → Lint → Test Suite → Security Scan → Diff Review
```

| Stage | Action | Pass Criteria |
|---|---|---|
| 1. Build | Run build command | Success |
| 2. Type Check | Run type checker (if applicable) | 0 errors |
| 3. Lint | Run linter | 0 errors (warnings: report) |
| 4. Test Suite | Run tests | All pass |
| 5. Security Scan | Check secrets, console.log, unused imports | 0 violations |
| 6. Diff Review | Read diff, confirm matches intent | Match |

### Execution Rules
- **Stop on first failure**. Do not run subsequent stages (save tokens).
- Skip unavailable stages with SKIP label (e.g., no type checker → Type Check = SKIP).
- READY verdict only when all stages PASS.

## Red Team 5Q (post-gate self-attack)
After all 6 stages PASS, answer these 5 questions before issuing READY:
1. "Does this change break any existing behavior not covered by tests?"
2. "Is there an edge case this implementation silently mishandles?"
3. "Would this design hold if input volume increases 10x?"
4. "Am I confident because of evidence, or because I wrote it?"
5. "What is the most likely way this fails in production?"

If any answer raises doubt → investigate before issuing READY.

## Circuit Breaker
- Same issue fails **3 times** → STOP.
- Instead of 4th attempt: re-examine architecture or escalate to user.

## Rationalization Prevention
| Excuse | Rebuttal |
|---|---|
| "Tests pass so it's done" | Did you verify the tests check the right thing? |
| "It compiles so it works" | Compilation ≠ correct behavior. Runtime verification needed. |
| "This is hard to test" | Hard to test = possibly bad design. |
| "Trivial change, no verification needed" | Trivial changes kill production most often. |

## Output Format
```
## Verification: {task summary}

### 6-Stage Gate
| Stage | Command | Result | Verdict |
|---|---|---|---|
| Build | {cmd} | {output} | PASS/FAIL/SKIP |
| Type Check | {cmd} | {output} | PASS/FAIL/SKIP |
| Lint | {cmd} | {output} | PASS/FAIL/SKIP |
| Test Suite | {cmd} | {output} | PASS/FAIL/SKIP |
| Security | (manual) | {findings} | PASS/FAIL |
| Diff Review | (manual) | {summary} | PASS/FAIL |

### Final Verdict: READY / NOT READY
(If NOT READY: failed stage + cause + next action)
```
