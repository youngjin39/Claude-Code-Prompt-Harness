---
title: ECC Context Budget Thresholds
keywords: [context-budget, token, overhead, MCP, session, bloat, estimation]
related: [patterns/error-handling.md]
created: 2026-04-12
last_used: 2026-04-12
---

# Context Budget Thresholds

Source: everything-claude-code (ECC) context-budget skill analysis.
Applied to our harness via project-doctor Context Budget Audit section.

## Token Estimation Heuristics
- Prose content: word count × 1.3
- Code-heavy content: char count / 4
- MCP tool schema: ~500 tokens per tool (biggest single lever)

## Component Thresholds
| Component | Healthy | Warning | Critical |
|---|---|---|---|
| CLAUDE.md | <200 lines | 200-300 | >300 |
| Single skill | <200 lines | 200-400 | >400 |
| Single agent | <100 lines | 100-200 | >200 |
| MCP tools total | <10 | 10-20 | >20 |
| Session overhead | <5% of 200K | 5-10% | >10% |

## Key Insight
MCP is the biggest token cost lever. A 30-tool MCP server costs more tokens than all skills combined.
Always-loaded content (CLAUDE.md, agent descriptions) should be minimized; use JIT loading for conditional content.
