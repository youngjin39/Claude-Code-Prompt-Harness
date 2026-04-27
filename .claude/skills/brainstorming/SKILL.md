---
name: brainstorming
description: "Design exploration for real forks. Required before coding only when meaningful design choices exist.\n\nTrigger: design, brainstorming, architecture, new feature"
---

# Brainstorming

<HARD-GATE>
When this skill is triggered, no code without passing this stage.
If exploration shows there is no meaningful fork, mark direct-execution-safe and exit.
</HARD-GATE>

## Use When
- New feature, architecture change, or UI flow with real product/design choices
- User explicitly asks for options, tradeoffs, or recommendation first
- Multiple plausible approaches exist and blast radius differs materially

## Do Not Use When
- The task is a concrete, localized implementation with an obvious path
- The user already approved a design or handed over an implementation-ready plan
- The request is primarily execution, testing, or verification rather than option exploration

## Procedure
1. Analyze request: what must be achieved?
2. Explore existing code: related files/patterns/dependencies.
3. **Present 2~3 alternatives** (each with deliberately different lens/perspective):
   - Each: approach + pros/cons + risks + blast radius.
   - Alternatives must differ in philosophy, not just implementation detail.
4. **Counter-narrative attack**: identify the most attractive wrong approach, build its strongest case, then demolish it with evidence. This prevents confirmation bias toward the first plausible option.
5. **Synthesis check**: if strengths from multiple options can be combined without their weaknesses, present a hybrid option.
6. Mark recommendation + rationale.
7. Wait for user approval.

## Exit Condition
- User approves design → proceed to writing-plans.
- If exploration proves there is no meaningful design fork, mark direct-execution-safe and proceed without inventing fake alternatives.

## Banned Patterns
- Presenting alternatives that differ only in implementation detail (same philosophy = same option).
- Recommending without first attacking the recommendation (counter-narrative is mandatory).
- "This is the only way" — if you cannot imagine an alternative, you haven't explored enough.

## Rationalization Prevention
| Excuse | Rebuttal |
|---|---|
| "Too simple for design" | What looks simple is most dangerous. Always check blast radius. |
| "No time, just code" | Rework from bad design costs more than upfront planning. |
| "Did something similar before" | Similar ≠ identical. Explicitly confirm differences. |
| "Only one option exists" | No alternatives = insufficient exploration. |

## Output Format
```
## Design: {task summary}
### Option A: {name}
- Approach: ...
- Pros: ...
- Cons: ...
- Risk: ...

### Option B: {name}
(same structure)

### Counter-narrative
- Most attractive wrong choice: Option {Y}
- Strongest case for it: ...
- Why it fails: ...

### Recommendation: Option {X}
- Rationale: ...
```

## Next Step
→ writing-plans (after user approval)
