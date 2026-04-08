---
title: Error Handling & Output Parsing Recovery
keywords: [error, failure, parse, retry, taxonomy, recovery, unknown, transient]
related: [verification/SKILL.md, executor-agent.md]
created: 2026-04-08
last_used: 2026-04-08
---

## Error Taxonomy
Every failure must be classified into one of four types. Response is determined by type, not by the specific error message. No "try again harder" without classification.

| Class | Definition | Response |
|---|---|---|
| **transient** | Network timeout, rate limit, flaky I/O, lock contention. Retryable without change. | Exponential backoff: 1s → 4s → 10s. Max 3 retries. Then escalate to `unknown`. |
| **model-fixable** | Tool returned a structured error the model can act on (wrong arg, schema mismatch, file not found, syntax error, type error, test failure). | Feed the error back into the next turn as an observation. Do not retry identically. Revise the call/code. Max 3 attempts → circuit breaker. |
| **interrupt** | Requires human judgment: destructive action denied, ambiguous intent, scope expansion, permission escalation, conflicting instructions. | STOP. Report the decision point to the user. Do not guess. |
| **unknown** | Does not match the above. Crash, unexpected state, corrupted output, unreachable code path. | Log full context to lessons.md (What Did NOT Work) + STOP. Do not improvise. |

Rule: if the model cannot name the class within one sentence, treat as `unknown`.

## Output Parsing Recovery
When a tool result or model output cannot be parsed as expected:
1. Do NOT proceed as if successful. Do NOT silently retry the identical call.
2. Attempt partial extraction: take only the fields that validated, mark the rest missing.
3. If partial extraction covers the decision → continue with explicit note of what was dropped.
4. If not → feed the parse failure back as a `model-fixable` error (show expected schema + actual fragment) and request a corrected response.
5. After 2 parse-failure rounds → classify as `unknown` and STOP.
