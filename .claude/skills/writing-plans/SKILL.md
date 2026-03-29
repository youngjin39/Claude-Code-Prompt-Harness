---
name: writing-plans
description: "Concrete implementation plan. Bite-sized steps.\n\nTrigger: plan, implementation plan, step design"
---

# Writing Plans

## Prerequisite
User approved design from brainstorming stage.

## Principles
- Each step: **2~5 minutes** of work.
- Abstract expressions like "add tests" or "refactor" are **forbidden**.
- Include actual code, exact commands, and expected output.

## Procedure
1. Map file structure based on approved design.
2. Decompose into steps (TDD cycle when applicable):
   - Step N-1: Write failing test (include code)
   - Step N-2: Run test, confirm failure (command + expected output)
   - Step N-3: Minimal implementation (include code)
   - Step N-4: Run test, confirm pass (command + expected output)
   - Step N-5: Commit (command)
3. Record current step in tasks/plan.md.

## Exit Condition
- All steps contain concrete code + commands + expected output.
- User approves plan.

## Banned Patterns
- "Add appropriate tests" — specify exact test names, inputs, expected outputs.
- "Refactor as needed" — specify which function, what change, why.
- "Handle edge cases" — list each edge case explicitly.
- Any step that cannot be executed by copy-pasting the provided code/command.

## Rationalization Prevention
| Excuse | Rebuttal |
|---|---|
| "Can't write all code upfront" | Direction and skeleton are writable. Concrete > vague. |
| "Too detailed = inflexible" | Detailed plans make change points explicit. |
| "This step is obvious" | "Obvious" = unverified assumption. Make it explicit. |

## Output Format
```
## Implementation Plan: {task summary}
Estimated steps: N | Estimated files: M

### Step 1: {title}
- File: {path}
- Code:
  ```{lang}
  (actual code)
  ```
- Run: `{command}`
- Expected: {output}

### Step 2: ...
```

## Next Step
→ execution (after user approval, delegate to executor-agent)
