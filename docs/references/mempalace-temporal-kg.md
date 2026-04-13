---
title: MemPalace — Temporal Knowledge Graph Reference
keywords: [mempalace, temporal, knowledge-graph, contradiction, memory, time-aware]
related: [patterns/error-handling.md]
created: 2026-04-13
last_used: 2026-04-13
---

# MemPalace — Temporal Knowledge Graph

Source: https://github.com/MemPalace/mempalace (MIT, 44K stars, 2026-04)
Status: Too new for production (8 days old at review time). Benchmark claims partially inflated.

## Relevant concept: Temporal Knowledge Graph

SQLite triple store with time-awareness:
```
(subject, predicate, object, valid_from, valid_to)
```

- Query by time: `query_entity(name, as_of="2026-01-15")` → only facts valid at that date
- Invalidation: `invalidate()` sets `valid_to` without deleting
- Tracks decision changes over time (not just latest state)

## Why we noted this

Our lessons.md and docs/ memory system overwrites facts without time tracking.
"Decided X in March → Changed to Y in June" is lost — only Y remains.
If project complexity grows, temporal triples could track decision evolution.

## Not applicable now because

- Current project scale doesn't justify SQLite dependency for memory
- Our keyword-based memory-map.md is sufficient for current 7-category structure
- MemPalace itself has open bugs (ARM64 segfault, shell injection)

## Applicable to

오픈클로 관리, 헤르메스 관리자 — deep knowledge management agents that track evolving facts about systems.

## Validated insight

"Raw verbatim storage + search > AI-extracted summaries" — MemPalace data shows full transcript storage with search beats LLM-curated summaries for recall accuracy. Our sessions/ full-preservation policy is correct.
