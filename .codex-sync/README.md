# Codex Sync Layer

This folder defines the one-way `Claude -> Codex` derivation workflow for repositories that start from this starter.

## Rules
- Claude files are the source of truth.
- Codex files are generated artifacts.
- Sync drift is treated as a maintenance failure.

## Files
- `manifest.template.json`: source-to-target mappings and sync policy
- `manifest.json`: current repository mappings generated from Claude source files
- `rollout-checklist.md`: per-repository adoption checklist for large rollouts

## Checked-in Pack
This repository checks in a core migration pack:
- `AGENTS.md`
- `.codex/config.toml`
- `.codex/agents/*`
- `.agents/skills/{brainstorming,code-review,deep-interview,git-commit,project-doctor,self-audit,testing,ux-ui-design,verification,writing-plans}`

Default generation profile is `core`. Generated Codex files intentionally inherit Codex's default model selection. Run with `CODEX_DERIVATION_PROFILE=full` to expand to the full portable skill set.

## Minimum Process
1. Update a Claude source file.
2. Update or validate the matching manifest entry.
3. Regenerate the Codex target files.
4. Verify the repository before using Codex.

## Generator
Run:

```bash
bash scripts/generate_codex_derivatives.sh
python3 scripts/verify_codex_sync.py
```

This refreshes `AGENTS.md`, `.codex/config.toml`, `.codex/agents/*`, `.agents/skills/*`, and `.codex-sync/manifest.json`.
The verifier checks manifest coverage, generated target coverage, generated-file markers, active-profile skill-set drift, startup-state parity, blocked-intent mirror coverage, mode-classification coverage, generated-section coverage, config fallback policy, and dead-reference regressions across generator, docs, and generated files.

Profile selection:

```bash
CODEX_DERIVATION_PROFILE=core bash scripts/generate_codex_derivatives.sh
CODEX_DERIVATION_PROFILE=full bash scripts/generate_codex_derivatives.sh
```

If your current agent session protects hidden target directories such as `.codex/` or `.agents/`, generate into a staging path first:

```bash
CODEX_DERIVATION_OUTPUT_ROOT=.codex-sync/staging bash scripts/generate_codex_derivatives.sh
```
