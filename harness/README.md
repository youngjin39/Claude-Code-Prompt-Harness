# Harness Runtime

## Purpose
- `execute.py` manages phase presets, checkpoints, incident tracking, commit policy, and rollback metadata.
- `harness/state/` stores local runtime state. Treat it as generated operational data.

## Commands
- `python3 execute.py presets`
- `python3 execute.py start <phase> <goal> [--preset implementation] [--commit-policy checkpoint]`
- `python3 execute.py checkpoint "<message>" --files path/to/file --commit`
- `python3 execute.py complete "<summary>" --commit`
- `python3 execute.py fail "<reason>" [--commit]`
- `python3 execute.py status`
- `python3 execute.py rollback-metadata`
- `python3 scripts/verify_starter_integrity.py`
- `python3 scripts/verify_codex_sync.py`

## Commit Policy
- `manual` — commit only when `--commit` is passed.
- `never` — never auto-commit.
- `checkpoint` — auto-commit on `checkpoint`.
- `complete` — auto-commit on `complete`.
- `always` — auto-commit on `checkpoint`, `complete`, and `fail`.

## Rollback Metadata
- Task start captures the base git head, dirty files, and tracked files.
- Later commits are appended to rollback metadata with `head_before` and `head_after`.
- `rollback-metadata` is reporting only. It does not run destructive git commands.

## Incident Tracking
- Hooks call `execute.py record-incident` to detect repeated failures.
- Default circuit breaker window: 60 seconds.
- Default threshold: 5 repeated incidents with the same key.
- This is Claude-hook-driven by default. Codex sessions do not record incidents automatically; treat `harness/state/incidents.json` as Claude state unless a Codex workflow explicitly calls `execute.py record-incident`.

## TDD Guard
- `tdd-guard.sh` blocks edits to existing implementation files when no related test file exists.
- New implementation files are allowed so a test can be created first or alongside the code.
- Standard test location for starter scripts: `tests/test_<name>.py`. Tests are written as standalone runners so `python3 tests/<file>.py` is the canonical execution path; a project-level test framework is not required.

## State Files
- `harness/state/current-task.json` — active task snapshot
- `harness/state/history.jsonl` — append-only state history
- `harness/state/incidents.json` — recent hook incidents for circuit breaking

## Codex Sync Verification
- `scripts/verify_codex_sync.py` checks `.codex-sync/manifest.json`, generated target coverage, generated-file markers, active-profile skill-set drift, startup-state parity, blocked-intent mirror coverage, mode-classification coverage, generated-section coverage, config fallback policy, and dead-reference regressions.
- Run it after `bash scripts/generate_codex_derivatives.sh` when Claude source or Codex derived files change.

## Starter Integrity Verification
- `scripts/verify_starter_integrity.py` checks required starter files/directories, core agents/skills/hooks, CLAUDE runtime sections, required-read references, memory-map links, plan compactness, selected source agent/skill contract markers, and then runs `verify_codex_sync.py`.
- Use it as the top-level health check before running `self-audit` or after broader starter maintenance.
- Plan compactness rule: `tasks/plan.md` must stay within 50 lines. This is the verifier-enforced cap for the compact working plan; the full design lives in `docs/decisions/master-plan-v2.md`.
