---
title: Claude Runtime Guide
keywords: [claude, runtime, workflow, hooks, memory, operations]
related: [operations/codex-runtime.md, operations/hook-contract.md, operations/harness-application.md, operations/starter-maintenance-mode.md, integrations/claude-to-codex-derivation.md]
created: 2026-04-25
last_used: 2026-04-25
type: guide
---

# Claude Runtime Guide

## Startup
- Read `tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, and the latest session snapshot when present.
- Use `docs/memory-map.md` to load only relevant long-term docs.
- Before acting, identify runtime=`Claude`, the active mode, the hook-backed enforcement path, and the required completion gates from the startup docs.
- Prefer direct execution for 1~2-step work; use the full pipeline for 3+ steps.

## Pipeline Detail
- Ambiguous request: run `deep-interview`.
- Design work or unresolved forks: run `brainstorming` before code.
- Concrete multi-step work with clear design: run `writing-plans` directly.
- Complex execution: hand off to `executor-agent`.
- Completion claim: run `verification`.
- 4+ issues or review request: invoke `quality-agent`.
- Do an inline self-review before escalating to heavier review/delegation loops unless risk or scope already justifies the heavier path.

## Memory Rules
- `docs/` is durable project memory.
- `tasks/lessons.md` stores behavioral rules promoted from repeated wins/failures.
- `tasks/sessions/` stores temporary restore points; only the latest snapshot is active.
- Save new reusable knowledge only when it will help a future session.

## Hooks
- SessionStart: load active context (`plan`, `lessons`, `memory-map`, latest session).
- PreCompact: create and review a handoff skeleton before context reduction; this is advisory rather than a hard block.
- PreToolUse: block destructive `rm`, protected-branch force push, hook/signing bypass flags, shared-ref history rewrite, piped remote install, `sudo`, writes outside the project, writes to secret material, and writes into `.git` internals.
- TddGuard: require related tests before editing existing implementation files.
- PostToolUse: inspect edits for debug leftovers and secrets.
- SessionEnd: save session restore notes.
- Hook-by-hook event contract lives in `docs/operations/hook-contract.md`.

## Harness Application
- Claude gets hook-backed enforcement directly.
- Cross-harness application rules and parity boundaries live in `docs/operations/harness-application.md`.

## Starter Maintenance Mode
- When modifying starter contracts, verifiers, hooks, generated artifacts, or AI-facing runtime docs, enter Starter Maintenance Mode.
- Mode classification and completion rules live in `docs/operations/starter-maintenance-mode.md`.

## Failure Handling
- Classify failures as `transient`, `model-fixable`, `interrupt`, or `unknown`.
- Never retry blindly after parse or tool failure.
- Three failures on the same issue triggers a stop and re-evaluation.

## Quality And Scope
- Record changes in `tasks/change_log.md`.
- Keep changes surgical; no adjacent cleanup unless requested.
- Validate the most recently changed files for security and error handling.
