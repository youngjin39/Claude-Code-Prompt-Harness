# 13-Repository Rollout Checklist

Use this checklist when applying the same Claude-to-Codex derivation strategy to many repositories.

## Per Repository
- Confirm the repository still treats Claude files as the only source of truth.
- Copy `.codex-sync/` into the repository root.
- Fill in every source-to-target mapping in `manifest.template.json`.
- Mark unsupported Claude-only features explicitly instead of omitting them silently.
- Create or regenerate all Codex target files.
- Verify Claude and Codex can each summarize the intended operating rules.
- Check that no direct edits were made only in Codex target files.

## Fleet Consistency
- Keep the same field schema in all 13 manifests.
- Reuse the same target path conventions in all 13 repositories.
- Store repository-specific exceptions in `notes`, not by changing the schema.
- Review drift repository-by-repository; do not batch-approve stale targets.
