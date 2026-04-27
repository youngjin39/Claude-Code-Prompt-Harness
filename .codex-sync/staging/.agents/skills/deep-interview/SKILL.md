<!-- GENERATED FILE: edit .claude/skills/deep-interview/SKILL.md and rerun scripts/generate_codex_derivatives.sh -->
---
name: deep-interview
description: "Requirements clarification. Ambiguity gating.\n\nTrigger: interview, requirements, clarify, ambiguous"
user-invocable: true
---

# Deep Interview

## Purpose
Convert ambiguous requests into concrete requirements. Proceed only when ambiguity ≤ 20%.

## Ambiguity Score (weighted)
| Dimension | Weight | Measures |
|---|---|---|
| Goal | 40% | What must be achieved? |
| Constraints | 30% | What must NOT happen? Tech limits? Scope? |
| Success Criteria | 30% | How do we know it's done? |

Each dimension: 0~100% (0=fully clear, 100=fully ambiguous).
Weighted average ≤ 20% → proceed to next stage.

## Bottleneck Diagnosis
Before questioning, classify the request's primary bottleneck:
| Bottleneck | Symptom | Focus |
|---|---|---|
| A. Fact gap | Missing data, unverified claims | Gather evidence first |
| B. Logic gap | Single-path reasoning, no alternatives | Force multi-path exploration |
| C. Bias risk | Narrow framing, anchoring on first idea | Challenge assumptions |
| D. Execution gap | Vague deliverables, no success criteria | Define concrete outputs |

Tag the bottleneck in the ambiguity report. This guides which skills to invoke next.

## Procedure

### 1. Codebase First
- Explore related files/patterns/dependencies **before** asking the user.
- Don't waste user's time on questions the code can answer (save tokens).

### 2. Question Protocol
- **One question at a time**. No batch questions.
- Target the weakest dimension (most ambiguous).
- Report current ambiguity score before each question:
  ```
  [Ambiguity] Goal: 60% | Constraints: 40% | Success: 80% → Weighted: 62%
  → Targeting: Success dimension.
  Question: "What specific condition would mean this feature is complete?"
  ```

### 3. Challenge Rounds
| Round | Role | Question |
|---|---|---|
| 4 | Contrarian | "What if the opposite were true?" |
| 6 | Simplifier | "What's the simplest possible version?" |

Each challenge fires once. Purpose: shift perspective.

### 4. Convergence
- Ambiguity ≤ 20% → present summary → user confirms → next stage.
- After 8 rounds still > 20% → present current state + delegate decision to user.

## Output Format
```
## Requirements Summary
- **Goal**: {goal}
- **Constraints**: {constraints}
- **Success Criteria**: {criteria}
- **Ambiguity**: Goal {N}% | Constraints {N}% | Success {N}% → Weighted {N}%

→ Next: brainstorming / direct execution
```
