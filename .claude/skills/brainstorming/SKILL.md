---
name: brainstorming
description: "Design enforcement. Hard gate before coding.\n\nTrigger: design, brainstorming, architecture, new feature"
---

# Brainstorming

<HARD-GATE>
No code without passing this stage.
Implementation without design approval is forbidden.
</HARD-GATE>

## Procedure
1. Analyze request: what must be achieved?
2. Explore existing code: related files/patterns/dependencies.
3. **Present 2~3 alternatives** (each with deliberately different lens/perspective):
   - Each: approach + pros/cons + risks + blast radius.
   - Alternatives must differ in philosophy, not just implementation detail.
4. **Counter-narrative attack**: identify the most attractive wrong approach, build its strongest case, then demolish it with evidence. This prevents confirmation bias toward the first plausible option.
5. Mark recommendation + rationale.
6. Wait for user approval.

## Exit Condition
- User approves design → proceed to writing-plans.

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
