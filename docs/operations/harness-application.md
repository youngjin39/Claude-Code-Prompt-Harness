---
title: Harness Application Guide
keywords: [harness, claude, codex, parity, hooks, state, self-review, validation, workflow]
related: [operations/claude-runtime.md, operations/codex-runtime.md, operations/hook-contract.md, integrations/claude-to-codex-derivation.md]
created: 2026-04-26
last_used: 2026-04-26
type: guide
---

# Harness Application Guide

## Purpose
- Apply proven harness techniques to both Claude and Codex without pretending the runtimes are identical.
- Keep behavior aligned through explicit contracts, state artifacts, and validation commands.
- Strengthen what the AI reads first, not just human-facing marketing docs.
- Make the AI self-recognize its runtime, active mode, enforcement path, and completion gate before it acts.

## Adopted Techniques

### 1. Self-recognition-first contracts
- AI-facing contract text must let the agent identify its current runtime, active mode, enforcement path, and completion gate before acting.
- If the agent cannot answer those four questions from always-read files, the harness contract is underspecified even if the prose sounds reasonable to a human.
- This starter treats self-recognition as the bridge between skills, hooks, state artifacts, and verifier gates.

### 2. Hook-backed enforcement for Claude, instruction-backed mirror for Codex
- Claude can rely on runtime hooks for `SessionStart`, `PreCompact`, `PreToolUse`, `TddGuard`, `PostToolUse`, and `SessionEnd`, but not every hook is blocking enforcement. Some are advisory/state-management hooks.
- Codex cannot. Therefore Codex must read the same contract explicitly through `AGENTS.md`, generated agent files, and runtime docs.
- Do not describe the two runtimes as equivalent. Describe the parity boundary.
- Tool-safety parity must name the same blocked-intent set explicitly: destructive `rm`, protected-branch force push, hook/signing bypass flags, shared-ref history rewrite, piped remote install, `sudo`, writes outside the project, writes to secret material, and writes into `.git` internals.
- Continuity parity must cover handoff creation before compaction and session snapshots even when Codex performs them manually rather than through hooks.
- Do not claim hook-driven repeated-incident stopping for Codex-only sessions unless a Codex workflow explicitly records incidents into shared state.
- Codex parity here is manual compliance + verifier-checked contract drift, not native pre-execution blocking or behavioral parity.

### 3. State artifacts beat conversation memory
- `tasks/plan.md`, `tasks/handoffs/`, `tasks/sessions/`, and `harness/state/` are canonical state artifacts.
- Agents must externalize progress and recovery state there instead of relying on chat memory.
- Resume logic should start from files first, not from recalled context.

### 4. Validation gates are part of execution, not post-hoc decoration
- Starter work is incomplete until integrity verifiers run.
- Current baseline gates:
  - `python3 scripts/verify_starter_integrity.py`
  - `bash scripts/generate_codex_derivatives.sh` when generated Codex outputs are affected
  - `python3 scripts/verify_codex_sync.py` when derivation-layer behavior or generated files changed
- A claimed completion without these gates is only a draft.

### 5. Cross-harness parity needs explicit adapters, not wishful wording
- When one runtime lacks hooks or tools, document the fallback mechanism instead of silently dropping behavior.
- In this starter:
  - Claude: direct hook execution
  - Codex: generated instruction mirror + verification scripts
- Parity means equivalent intent and safeguards, not identical implementation.
- A parity claim is incomplete if the Codex mirror omits the concrete safeguarded behavior and keeps only a high-level slogan.

### 6. Inline self-review before expensive review loops
- Use a lightweight self-review checklist before escalating to heavier review/delegation loops.
- Spawn or invoke heavier review only when:
  - the task is risky,
  - the blast radius is broad,
  - the user asked for review,
  - or the initial self-review found uncertainty.
- This keeps the harness strict without paying unnecessary orchestration cost every time.

### 7. Core stays general; domain-specific workflow belongs outside core
- Core starter policy should remain cross-project and cross-runtime useful.
- Project-, domain-, or team-specific automation belongs in separate skills, docs, or plugins.
- When in doubt, prefer extension points over bloating the core contract.

### 8. Validation-friendly, machine-checkable text wins
- Important contracts should be expressed in stable wording that verifiers can check.
- If behavior matters, put it in:
  - `CLAUDE.md`
  - generated `AGENTS.md`
  - runtime guides
  - verifier scripts
- Avoid hiding critical policy in long prose that cannot be checked automatically.

## Runtime Mapping
| Concern | Claude | Codex |
|---|---|---|
| Startup context | Hook injection of `plan`, `lessons`, `memory-map`, latest session when present | Required reads + generated docs for the same startup set |
| Tool safety | Hook block on `PreToolUse` | Instruction contract + verifier checks over selected blocked-intent wording and generated drift |
| Edit inspection | `PostToolUse` hook | Manual/runtime-doc contract |
| Progress state | `tasks/*`, `harness/state/*` | Same files |
| Policy sync | Claude source docs | Regenerated Codex artifacts |
| Completion gate | Hooks + verifier commands | Verifier commands |

## Reference Pattern Mapping
| Reference | Imported pattern (subset) | Current starter application |
|---|---|---|
| `Yeachan-Heo/oh-my-claudecode` | Multi-agent coordination and Codex-aware extension as design inspiration, not 19-agent or tmux/runtime equivalence | `main-orchestrator` / `executor-agent` / `quality-agent`, plus one-way Claude -> Codex derivation |
| `affaan-m/everything-claude-code` | Skills + memory + security + research-first harness layering | Skill-trigger system, `docs/` memory, hook guardrails, verifier-backed runtime policy |
| `obra/superpowers` | Agent reads workflow contract first instead of jumping straight to code | `deep-interview` / `brainstorming` / `writing-plans` / `verification` pipeline and self-recognition-first rule |
| `coleam00/Archon` | Deterministic workflow framing and validation-gate emphasis, not YAML DAG/worktree/mechanism parity | `execute.py`, mode classification, regeneration rules, integrity verifiers, completion-gate policy |

These references are design inputs, not source-of-truth files. Unless a mechanism is named explicitly, treat the mapping as conceptual borrowing rather than implementation equivalence. The canonical contract still lives in `CLAUDE.md`, runtime docs, verifier scripts, and generated Codex artifacts.

## Non-Goals
- No claim of full runtime parity between Claude and Codex.
- No mandatory heavy multi-agent loop for every task.
- No domain-specific behavior in the core starter contract unless it generalizes.
