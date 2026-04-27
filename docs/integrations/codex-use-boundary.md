---
title: Prompt Starter Codex Use Boundary
keywords: [codex, use, boundary, starter, derivation, verifier, bootstrap]
created: 2026-04-27
last_used: 2026-04-27
type: integration
---

# Prompt Starter Codex Use Boundary

- Status: `bootstrap only`, `Codex bootstrap active`, `local use boundary documented`.
- Primary use: starter contract review, verifier maintenance, derivation-layer updates, harness docs maintenance.
- Safe review scope: `CLAUDE.md`, `.claude/`, `scripts/`, `tests/`, `docs/`, `execute.py`, `harness/`, `tasks/`.
- Safe implementation scope: source-first changes to starter contracts, hooks parity docs, verifiers, and generation tooling.
- Escalation scope: hand-editing generated `AGENTS.md`, `.codex/`, `.agents/`, bypassing verifier gates, or destructive changes to cross-harness contracts without source updates.
- Mir migration remains superseded here. Codex use is allowed as part of starter maintenance, but only through the Claude-source derivation flow.
