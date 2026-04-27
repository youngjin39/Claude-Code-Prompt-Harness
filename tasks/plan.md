# Plan (compact — full design: docs/decisions/master-plan-v2.md)

## 3-Axis Design
1. **Workflow** — direct execution for simple work, skill pipeline for multi-step work
2. **Memory** — keyword-indexed docs plus lessons and session snapshots
3. **Context** — compact startup state, handoffs, and verifier-backed continuity

## Current Capability Snapshot
- 3 agents: `main-orchestrator`, `executor-agent`, `quality-agent`
- 10 core skills: `brainstorming`, `code-review`, `deep-interview`, `git-commit`, `project-doctor`, `self-audit`, `testing`, `ux-ui-design`, `verification`, `writing-plans`
- 6 hooks: `SessionStart`, `PreCompact`, `PreToolUse`, `TddGuard`, `PostToolUse`, `SessionEnd`
- Codex derivation layer: `AGENTS.md`, `.codex/`, `.agents/`, `.codex-sync/manifest.json`
- Runtime docs: `claude-runtime`, `codex-runtime`, `hook-contract`, `harness-application`, `starter-maintenance-mode`
- Verifier gates: `scripts/verify_starter_integrity.py` and `scripts/verify_codex_sync.py`
- State artifacts: `tasks/plan.md`, `tasks/handoffs/`, `tasks/sessions/`, `harness/state/*`

## Current Contract Focus
- Self-recognition first: identify runtime, mode, enforcement path, and completion gate before acting.
- Claude/Codex parity is intent-level and verifier-backed, not native runtime equivalence.
- Generated Codex artifacts must be regenerated after source changes and proven clean by verifiers.

## Next Action
1. Keep startup files and runtime docs synchronized with actual harness behavior.
2. Expand verifier coverage only for real contract-owned wording and generated drift.
3. Add new domain skills only after the core starter contract stays stable.
