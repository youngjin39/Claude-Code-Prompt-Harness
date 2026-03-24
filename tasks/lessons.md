# Lessons

## What Did NOT Work
| Date | Task | Attempt | Why Failed | Correct Approach |
|---|---|---|---|---|
| 2026-03-20 | v1 plan | Rule enforcement as Phase 1 focus | Memory/context buried in Phase 3. Misaligned with user priorities. | 3-axis redesign (workflow/memory/context) |
| 2026-03-20 | Memory design | 4 layers (docs + lessons + agent-memory + sessions) | Role boundaries unclear. "Where to store?" undecidable. | 3 layers. Merge agent-memory into docs/. |
| 2026-03-20 | plan.md | 507-line full design in plan.md | Self-contradiction of context efficiency principle. ~2000 tokens per session. | Full design → docs/decisions/, plan.md stays compact. |

## What Worked
| Date | Task | Method | Why Effective |
|---|---|---|---|
| 2026-03-20 | Repo analysis | 4 repos via parallel sub-agents | Independent tasks → parallel efficiency maximized. ~100s each. |

## Promoted Rules
(Promoted from table above after 2+ repetitions)
- Planning docs must stay compact. Separate archive from active plan.
