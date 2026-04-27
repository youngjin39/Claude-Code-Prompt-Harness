---
title: One-Way Sync Manifest Pattern
keywords: [sync, manifest, change-detection, codex, claude, generated-files]
related: [integrations/claude-to-codex-derivation.md]
created: 2026-04-25
last_used: 2026-04-25
type: pattern
---

# One-Way Sync Manifest Pattern

## Why
LLMs can read changed files, but they do not reliably know whether a changed file invalidates a derived artifact.

## Rule
Declare derivation explicitly in a checked-in manifest.

## Required Fields
- `source`: canonical Claude file
- `targets`: generated Codex files
- `change_scope`: `content`, `path`, or `config`
- `sync_policy`: usually `regenerate`
- `owner`: team or maintainer

## Required Workflow
1. Edit a Claude source file.
2. Locate its row in the manifest.
3. Regenerate all listed targets.
4. Mark sync as verified in the same change.

## Stale Signals
- Source changed but target did not.
- Target edited directly without corresponding source change.
- Path changed and manifest still points to the old location.
- Claude/Codex behavior diverges for the same workflow.

## Enforcement Advice
- Keep the manifest small and explicit.
- Prefer one source entry per row even if multiple targets are produced.
- Fail CI or local verification when any mapped target is missing.
