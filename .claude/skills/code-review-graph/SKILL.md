---
name: code-review-graph
description: Local code knowledge graph with blast-radius analysis. MCP-native (22 tools). Tree-sitter AST → SQLite graph → bidirectional BFS impact tracking. 8.2x average token reduction for code review.
triggers: [code graph, blast radius, impact analysis, code review graph, dependency tracking, 코드 그래프, 영향 분석]
---

# Code Review Graph

External tool: https://github.com/tirth8205/code-review-graph (MIT). Tree-sitter based code structure graph with blast-radius analysis for AI-driven code review.

## When to fire
- PR review: "what does this change affect?" → blast-radius analysis
- Codebase onboarding: "what is this system?" → architecture overview
- Refactor planning: "what breaks if I change X?" → dependency tracking
- Debug: "where is this function called from?" → caller/callee graph query

## Skip when
- Repo has <50 files (overhead not worth it)
- Non-code project (docs-only, design-only)
- One-off script changes with no dependencies

## Prerequisites
- `pip install code-review-graph` (Python 3.10+)
- `code-review-graph install` (auto-detects Claude Code, Cursor, Windsurf, Zed — writes .mcp.json)
- Graph built: `code-review-graph build` (initial ~10s for 500 files)

## Architecture
```
Source files → Tree-sitter AST → SQLite graph (nodes + edges + flows + communities)
                                       ↓
                              MCP Server (22 tools) → Claude Code
```

Storage: `.code-review-graph/graph.db` (SQLite, WAL mode, FTS5 full-text search)

Node kinds: File, Class, Function, Test, Type
Edge kinds: CALLS, IMPORTS_FROM, INHERITS, IMPLEMENTS, CONTAINS, TESTED_BY, DEPENDS_ON

## Key MCP tools

| Tool | Purpose |
|---|---|
| `build_or_update_graph_tool` | Build or incrementally update the graph |
| `get_impact_radius_tool` | **Blast-radius**: bidirectional BFS from changed nodes (default 2-hop) → callers + dependents + tests |
| `get_review_context_tool` | Optimal file set for reviewing a change |
| `query_graph_tool` | Callers/callees of a specific function |
| `semantic_search_nodes_tool` | FTS5 + optional vector search across codebase |
| `detect_changes_tool` | Risk-scored change detection |
| `get_architecture_overview_tool` | Community structure + cross-module dependencies |
| `list_flows_tool` / `get_flow_tool` | Execution path analysis |
| `generate_wiki_tool` | Auto-generate code documentation |
| `cross_repo_search_tool` | Multi-repo registry search |

## Procedure

### For PR review (primary use case)
1. Ensure graph is current: `build_or_update_graph_tool` (incremental, <2s for 5 changed files in 2900-file repo)
2. `detect_changes_tool` → list of changed files with risk scores
3. `get_impact_radius_tool` → blast-radius: all callers, dependents, and tests affected
4. `get_review_context_tool` → minimal file set to read for complete review
5. Read only those files. Synthesize review.

### For architecture understanding
1. `get_architecture_overview_tool` → community structure
2. `list_flows_tool` → execution paths through the system
3. Query specific nodes as needed

### Incremental updates
- Git hook or `--watch` mode detects file changes
- SHA-256 per-file hash comparison — only changed + dependent files re-parsed
- <2 seconds for typical incremental update

## Relationship to other modules

### vs knowledge-wiki
- code-review-graph: **code structure** (AST-level, functions/classes/imports)
- knowledge-wiki: **domain knowledge** (human-curated concepts, business rules)
- No overlap. Different data, different purpose.

### vs code-review skill
- code-review skill: review procedure + quality checklist (what to look for)
- code-review-graph: review infrastructure (which files to read, what's affected)
- Complementary. Graph provides data, skill provides judgment framework.

## Hard rules
- **Never** edit `.code-review-graph/graph.db` directly. It's rebuilt by the tool.
- **Never** trust blast-radius as exhaustive for dynamic languages (reflection, eval, monkey-patching). It tracks static dependencies only.
- If `code-review-graph` is not installed → hand back install command, do not auto-install.
- Add `.code-review-graph/` to `.gitignore` (local index, not shared).
- Re-build graph after major refactors or when queries return stale results (renamed/removed symbols).

## Supported languages
19 languages via Tree-sitter: Python, TypeScript, JavaScript, Go, Rust, Java, Kotlin, C, C++, C#, Ruby, PHP, Swift, Scala, Dart, Lua, Haskell, OCaml, Elixir. Plus Jupyter and Databricks notebooks.

## Output format
When using blast-radius for review:
```
GRAPH: impact_radius({changed_files}) → affected=[{list}] tests=[{list}]
Review scope: {N} files (vs {total} in repo = {reduction}x reduction)
```
