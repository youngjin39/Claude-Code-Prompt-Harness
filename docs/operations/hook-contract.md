---
title: Hook Contract Guide
keywords: [hooks, contract, sessionstart, pretooluse, posttooluse, precompact, sessionend, tdd]
related: [operations/claude-runtime.md, operations/codex-runtime.md]
created: 2026-04-26
last_used: 2026-04-26
type: guide
---

# Hook Contract Guide

## Purpose
- Define what each project hook is responsible for.
- Separate automatic enforcement from prompt-only policy.
- Give Codex a mirror contract even though Codex does not execute Claude hooks natively.

## Event Matrix
| Event | Script | Responsibility | Output/Effect |
|---|---|---|---|
| `SessionStart` | `.claude/hooks/session-start.sh` | Load startup context | Inject `plan.md`, `lessons.md`, `memory-map.md`, latest session |
| `PreCompact` | `.claude/hooks/pre-compact.sh` | Preserve handoff before context reduction | Auto-create handoff skeleton in `tasks/handoffs/` |
| `PreToolUse` | `.claude/hooks/pre-tool-use.sh` | Block destructive commands and denied paths | Exit `2` on blocked tool call |
| `PreToolUse` | `.claude/hooks/tdd-guard.sh` | Block edits to existing implementation files when `related-tests` marks them as source files and finds zero related tests | Exit `2` when the test-first boundary is violated |
| `PostToolUse` | `.claude/hooks/post-edit-check.sh` | Detect debug leftovers and credential leaks | Warning/critical message after edit/write |
| `SessionEnd` | `.claude/hooks/session-end.sh` | Preserve continuity | Save session snapshot and memory-harvest reminder |

## Input / Output Rules

### SessionStart
- Reads files only.
- Emits compact startup context to stdout.
- Current truncation caps are `head -50` for `plan.md`, `lessons.md`, and the latest session snapshot, plus `head -80` for `docs/memory-map.md`.
- Agents should treat this output as authoritative startup state, not as optional commentary.

### PreCompact
- Must never delete context or mutate source files.
- May create only `tasks/handoffs/auto-*.md`.
- Output is advisory and creates a handoff skeleton; it does not block compaction by itself. The handoff file is the durable artifact.

### PreToolUse
- Input comes from tool event JSON on stdin.
- Blocking path: write message to stderr and exit `2`.
- Non-blocking path: exit `0` silently.
- This hook owns destructive-command and denied-path enforcement. Prompt text should not try to re-implement shell parsing.
- The denied-path rule has one runtime-local exemption: writes to the Claude Code home auto-memory namespace `~/.claude/projects/<id>/memory/*.md` are allowed because that namespace is platform-managed and outside the project root. The exemption is Claude-only and does not weaken cross-runtime parity, since Codex has no auto-memory feature and applies the same blocked-intent set through its instruction contract.

### TDD Guard
- Runs only for `Edit|Write`.
- Applies only when `execute.py related-tests` marks the target as a source file and returns `count == 0`.
- New files are allowed.
- Blocking path uses the same exit `2` contract as `pre-tool-use.sh`.

### PostToolUse
- Runs only after `Edit|Write`.
- Reports findings; it does not revert files.
- Uses `execute.py record-incident` for repeated-warning circuit breaking.

### SessionEnd
- Writes a session snapshot to `tasks/sessions/`.
- Output is a reminder to complete the snapshot, not proof that continuity work is finished.

## Runtime Interpretation

### Claude Code
- Hooks are active enforcement and state management.
- If a hook blocks an action, the agent must change strategy instead of retrying blindly.

### Codex
- Codex does not run Claude hooks automatically.
- Therefore generated Codex docs must mirror hook expectations explicitly:
  - read the same startup files, including the latest session snapshot when present,
  - before invoking compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract,
  - use the same mode-classification entry rules for starter/parity work,
  - name the same blocked-intent set: destructive `rm`, protected-branch force push, hook/signing bypass flags, shared-ref history rewrite, piped remote install, `sudo`, writes outside the project, writes to secret material, and writes into `.git` internals,
  - respect the same test-first boundary for existing source files with zero detected related tests,
  - do not claim hook-driven incident counting for Codex-only sessions unless a Codex workflow explicitly records incidents; otherwise `harness/state/incidents.json` remains Claude-hook state rather than a Codex parity guarantee,
  - preserve the same post-edit review intent for debug leftovers and credential leaks,
  - treat hook-managed files as canonical artifacts.
  - at session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.
- This mirror is instruction-backed, and selected contract snippets plus generated outputs are verifier-checked. It is not native pre-execution blocking or behavioral parity.
- If Codex behavior diverges from hook policy, fix Claude source docs and regenerate. Do not patch generated files only.

## Non-Goals
- No hidden business logic in hooks.
- No duplicate policy tables across multiple always-read files.
- No assumption that warnings equal success criteria.
- No claim that Codex-only sessions inherit hook-driven incident counting without an explicit recording path.
