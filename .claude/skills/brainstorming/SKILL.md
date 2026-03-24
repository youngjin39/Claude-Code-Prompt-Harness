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
3. **Present 2~3 alternatives** (single option forbidden):
   - Each: approach + pros/cons + risks + blast radius.
4. Mark recommendation + rationale.
5. Wait for user approval.

## Exit Condition
- User approves design → proceed to writing-plans.

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

### Recommendation: Option {X}
- Rationale: ...
```

## Next Step
→ writing-plans (after user approval)
