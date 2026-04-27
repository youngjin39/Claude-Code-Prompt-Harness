<!-- GENERATED FILE: edit .claude/skills/testing/SKILL.md and rerun scripts/generate_codex_derivatives.sh -->
---
name: testing
description: "Test writing and execution.\n\nTrigger: test, TDD, unit test, integration test"
context: fork
---

# Testing

## Procedure
1. Detect test framework (package.json scripts, config files).
2. Check if tests exist for changed files. Create if missing.
3. Follow existing test patterns. Add edge cases.
4. Run tests. On failure: root cause analysis → fix → re-run.

## Rules
- Test names: `should_return_X_when_Y`.
- Edge cases: null, empty, boundary, error, concurrent.
- No mocks for external services unless explicitly approved.

## GUI Testing (Computer Use)
When the project has GUI components and computer-use MCP is enabled:
1. Build and launch the app.
2. Execute UI flows: tap, scroll, navigate between screens.
3. Screenshot any visual anomalies or errors.
4. Report layout issues with screenshot evidence.

Ref: `docs/integrations/computer-use-gui-testing.md`

## Output
```
## Test Results
| File | Tests | Pass | Fail | Coverage |
|---|---|---|---|---|
| {file} | {N} | {N} | {N} | {%} |

### Failures (if any)
- {test_name}: {root cause} → {fix applied}
```
