# Lessons

## What Did NOT Work
| Date | Task | Attempt | Why Failed | Correct Approach |
|---|---|---|---|---|
| 2026-03-20 | v1 plan | Rule enforcement as Phase 1 focus | Memory/context buried in Phase 3. Misaligned with user priorities. | 3-axis redesign (workflow/memory/context) |
| 2026-03-20 | Memory design | 4 layers (docs + lessons + agent-memory + sessions) | Role boundaries unclear. "Where to store?" undecidable. | 3 layers. Merge agent-memory into docs/. |
| 2026-03-20 | plan.md | 507-line full design in plan.md | Self-contradiction of context efficiency principle. ~2000 tokens per session. | Full design → docs/decisions/, plan.md stays compact. |
| 2026-03-24 | Hook field name | Used `.tool_input.file_path` only in post-edit-check.sh | Edit tool uses `.path`, Write uses `.file_path`. Edit events silently skipped. | Use jq fallback: `.file_path // .path // empty` |
| 2026-03-24 | Skill name consistency | Used abbreviated "plans" in presets/gates | 4+ locations drifted from canonical name "writing-plans". Repeated across rounds. | Always use canonical skill name. Never abbreviate in config files. |
| 2026-03-24 | README sync | Updated CLAUDE.md without syncing README | README drifted 5+ times across audit rounds. Secondary copies always lag. | After CLAUDE.md changes, always check README for matching sections. |
| 2026-03-24 | Keyword index | Added keywords to memory-map.md without checking file frontmatter | Bidirectional mismatch: index had keywords file didn't, and vice versa. | Always sync both directions: index ↔ file frontmatter. |

## What Worked
| Date | Task | Method | Why Effective |
|---|---|---|---|
| 2026-03-20 | Repo analysis | 4 repos via parallel sub-agents | Independent tasks → parallel efficiency maximized. ~100s each. |
| 2026-03-24 | Presets dedup | Replaced orchestrator presets table with "See CLAUDE.md" pointer | Eliminated recurring sync issue. Single source of truth enforced. |
| 2026-03-24 | Integrity audit | quality-agent (sonnet, fork) for 6-dimension read-only review | Consistent methodology. Fork context prevents accidental edits. 24 rounds stable. |
| 2026-03-24 | Credential detection | jq fallback + POSIX `[[:space:]]` + hyphen in char class | Cross-platform + cross-tool compatibility. Handles sk-proj-*, sk-ant-*, Edit+Write. |

## Promoted Rules
(Promoted from table above after 2+ repetitions)
- Planning docs must stay compact. Separate archive from active plan.
- After changing CLAUDE.md, always verify README for matching sections. (README drift: 5+ occurrences)
- Use canonical skill names in all config files. Never abbreviate. ("plans" drift: 4+ occurrences)
- Keyword indexes require bidirectional sync: index → file AND file → index. (3+ occurrences)
- Deduplicate cross-file tables with "See X" pointers. Copies always drift. (presets: 2+ occurrences)
- User-facing updates must be scannable: report progress, result, and discussion explicitly, but keep them in short labeled blocks. No wall-of-text progress logs.
