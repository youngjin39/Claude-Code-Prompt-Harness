---
title: Starter Maintenance Mode
keywords: [starter, maintenance, mode, classification, parity, integrity, regeneration, verification]
related: [operations/harness-application.md, operations/claude-runtime.md, operations/codex-runtime.md]
created: 2026-04-26
last_used: 2026-04-26
type: guide
---

# Starter Maintenance Mode

## Purpose
- Help the agent recognize when it is modifying the starter itself rather than an ordinary project feature.
- Make the required regeneration and verification steps explicit.
- Separate general starter maintenance from cross-harness parity work.
- Keep verifier-expected wording visible enough that contributors know some runtime-policy prose is machine-checked verbatim.

## Classification

### Enter Starter Maintenance Mode when the task touches any of:
- `CLAUDE.md`
- `AGENTS.md`
- `.claude/agents/*`
- `.claude/hooks/*`
- `.claude/skills/*`
- `.codex/*`
- `.agents/*`
- `.codex-sync/*`
- `scripts/generate_codex_derivatives.sh`
- `scripts/verify_*.py`
- `docs/operations/*`
- `tasks/plan.md`, `tasks/handoffs/*`, `tasks/sessions/*`, or `harness/state/*` when the change alters runtime-state contract, startup continuity, or completion evidence rather than ordinary task content
- `harness/README.md`

### Enter Cross-Harness Parity Mode when the task additionally changes:
- Claude vs Codex behavior boundaries
- hook/instruction mirroring rules
- startup-state mirroring rules
- blocked-intent mirroring rules
- source-of-truth vs generated artifact policy
- verifier expectations for Codex-derived outputs
- In practice, many starter-maintenance changes will also enter Cross-Harness Parity Mode. Treat this as normal, not exceptional.
- Use this narrower test: parity mode is required when the change alters behavior or wording that must stay aligned across Claude docs, Codex generated instructions, and verifier checks.
- Starter Maintenance Mode alone is usually enough for local starter edits that do not change mirrored behavior, such as runtime-contract `tasks/` updates, `docs/decisions/` notes, or project-specific docs that sit outside the derivation layer and verifier-owned wording set.
- Parity mode usually does apply to startup-state wording, blocked-intent lists, source-of-truth/generated-artifact boundaries, verifier-owned snippets, and any change that would require regenerating Codex instructions to keep the same contract.

## Required Behavior

### Starter Maintenance Mode
1. Treat source docs, generated artifacts, hooks, scripts, and runtime guides as one contract.
2. Update AI-facing docs first or in the same change.
3. Run `python3 scripts/verify_starter_integrity.py`.
4. If Codex-derived artifacts are affected, regenerate them.
5. Run `python3 scripts/verify_codex_sync.py` after regeneration-related work.

### Cross-Harness Parity Mode
1. Read `docs/operations/harness-application.md`.
2. Do not assume Claude and Codex support the same enforcement mechanisms.
3. For every Claude-only behavior, define the Codex mirror explicitly:
   - instruction contract,
   - verifier rule,
   - generated artifact,
   - or documented non-goal.
4. Keep startup-state rules and blocked-intent rules concrete enough for verifier coverage. Do not leave them at slogan level.
5. Do not claim parity unless both the runtime contract and verifier logic agree.
6. When a verifier depends on exact wording, update the wording and verifier in the same change instead of treating prose edits as purely editorial.

## Completion Criteria
- Starter maintenance is not complete if any AI-facing contract doc is stale.
- Cross-harness parity work is not complete if Claude behavior changed but Codex mirrors or verifier checks did not.
- Cross-harness parity work is not complete if startup-state rules or blocked-intent rules became ambiguous across docs, generated artifacts, and verifiers.
- Completion claims require passing verifier commands, not just a plausible diff.

## Exit Criteria
- Exit Starter Maintenance Mode only after AI-facing contract docs, generated artifacts, and verifier expectations all match the changed behavior.
- Exit Cross-Harness Parity Mode only after the Claude-side behavior, Codex instruction mirror, and verifier coverage all agree on the same boundary.
- If any required mirror is intentionally absent, keep the task in parity mode until the gap is documented as an explicit non-goal.
- The current explicit non-goal catalog is limited to the `## Non-Goals` sections in this file, `docs/operations/hook-contract.md`, `docs/operations/harness-application.md`, and `docs/integrations/claude-to-codex-derivation.md`. Do not invent ad-hoc non-goals silently.

## Verifier-Owned Wording
- `scripts/verify_codex_sync.py` checks selected runtime-policy snippets verbatim across `CLAUDE.md`, `AGENTS.md`, runtime docs, generator output, and generated artifacts.
- Treat those snippets as machine-checked contract text, not freeform prose.
- If wording must change, update the verifier in the same task and keep the wording synchronized across the affected files.

## Non-Goals
- No forcing full runtime equivalence between Claude and Codex.
- No README-driven enforcement as the primary source of truth.
