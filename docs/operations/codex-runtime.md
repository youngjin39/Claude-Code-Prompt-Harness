---
title: Codex Runtime Guide
keywords: [codex, runtime, generated, agents, skills, default-model]
related: [operations/claude-runtime.md, operations/hook-contract.md, operations/harness-application.md, operations/starter-maintenance-mode.md, integrations/claude-to-codex-derivation.md]
created: 2026-04-25
last_used: 2026-04-25
type: guide
---

# Codex Runtime Guide

## Scope
- Codex artifacts are derived from `Claude` source files.
- `AGENTS.md` is the primary Codex entry point.
- `.codex/agents/*` and `.agents/skills/*` are generated support files.
- Generated agent files should stay narrowly scoped to agent behavior and point back to `AGENTS.md` for shared runtime policy.
- They may restate minimal runtime-critical mirrors when an agent needs local execution guidance, but `AGENTS.md` remains the shared contract.

## Model Policy
- Do not pin a Codex model in generated config or agent files unless a repository explicitly requires it.
- Let Codex use its current default model selection.
- Keep reasoning effort explicit only when useful.

## Generated Pack
- `AGENTS.md`
- `.codex/config.toml`
- `.codex/agents/*.toml`
- `.agents/skills/*/SKILL.md`
- `.codex-sync/manifest.json`

## Core Profile Expectation
- The default Codex profile must include every workflow skill referenced as default runtime behavior in `CLAUDE.md`.
- Minimum core set: `brainstorming`, `deep-interview`, `writing-plans`, `verification`, `testing`, `code-review`, `ux-ui-design`, `git-commit`, `project-doctor`, `self-audit`.
- If `AGENTS.md` says "use generated Codex skills first", missing derived skills are a runtime failure, not a documentation gap.

## Runtime Rules
- Start from `AGENTS.md`, then load generated skills as needed.
- Read `tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, and the latest session snapshot when present before relying on recalled context.
- Before acting, identify runtime=`Codex`, the active mode, the instruction-backed enforcement path, and the verifier-backed completion gates from `AGENTS.md` and runtime docs.
- Treat SessionStart guidance as a truncated startup snapshot, not a guarantee that the full file contents were injected.
- For policy changes, edit Claude source files and regenerate.
- Treat direct edits to generated Codex files as temporary at most; regenerate immediately after source correction.
- Mirror the Claude hook contract in generated docs because Codex does not execute those hooks itself.
- Mirror agent-level tool restrictions in generated Codex agent instructions even when sandboxing already provides a stronger guard.
- Before compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract.
- Mirror the same blocked-intent set explicitly: destructive `rm`, protected-branch force push, hook/signing bypass flags, shared-ref history rewrite, piped remote install, `sudo`, writes outside the project, writes to secret material, and writes into `.git` internals.
- Do not claim hook-driven incident counting for Codex-only sessions unless the active Codex workflow explicitly records incidents.
- In Codex-only sessions, `harness/state/incidents.json` remains Claude-hook state rather than a Codex parity guarantee.
- At session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.
- Describe Codex tool-safety parity as manual compliance + verifier-checked contract drift, not native pre-execution blocking or behavioral parity.
- Use verifier commands as completion gates because Codex lacks Claude-style native hook parity.

## Harness Application
- Codex uses instruction-backed parity, shared state artifacts, and verification commands instead of hook execution.
- Cross-harness application rules and parity boundaries live in `docs/operations/harness-application.md`.

## Starter Maintenance Mode
- When modifying starter contracts, verifier rules, or generated Codex artifacts, enter Starter Maintenance Mode.
- Mode classification and completion rules live in `docs/operations/starter-maintenance-mode.md`.

## Profiles
- `core`: compact Codex pack for routine use
- `full`: broader portable skill set for migration or deeper parity checks

## Validation
- Regenerate after every Claude policy or skill change.
- Diff generated outputs against the checked-in Codex pack.
- Treat stale generated files as a failure, not a warning.
