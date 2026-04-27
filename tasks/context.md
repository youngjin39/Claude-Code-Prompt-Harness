# Context

## Project Purpose
mir-claude-starter — opinionated Claude Code starter. 3-axis design:
1. **Workflow** — pipeline from start to completion
2. **Memory efficiency** — keyword index, selective load, no decay
3. **Context efficiency** — lazy loading, model routing, handoff docs

## Key Decisions (9)

### 1. 3-axis restructure (v1→v2)
- v1 centered on "rule enforcement". Memory/context buried in Phase 3.
- → Every phase must contribute to all 3 axes.

### 2. Rules embedded in pipeline
- Separate phase for rules = disconnect from pipeline. Embed in each stage. (Superpowers)

### 3. Orchestrator/executor boundary
- Simple (1~2 steps): orchestrator executes directly. Avoids subagent overhead.
- Complex (3+ steps): delegate to executor-agent. Full pipeline.
- When ambiguous → classify as complex (safer). (OMC)

### 4. Memory: 4-layer → 3-layer
- `docs/` = project knowledge (what we know). Long-term, no decay.
- `tasks/lessons.md` = behavior rules (what to do/not do). Failure-first.
- `tasks/sessions/` = session restore (ephemeral). Only latest valid.
- ~~agent-memory/~~ merged into docs/.

### 5. Registry removed
- Trigger table (CLAUDE.md) + glob validation (project-doctor) is sufficient.
- Eliminates dual-sync burden.

### 6. Deep Interview: Lite vs Full
- Lite (Phase 1): 1~2 clarifying questions. No scoring.
- Full (Phase 2): ambiguity score (Goal 40% + Constraints 30% + Success 30%), challenge rounds.

### 7. Hooks = shell commands (Phase 3)
- SessionStart: `head -50` plan.md + lessons.md + latest session snapshot → context injection. ✅
- PostToolUse(Edit|Write): debug statement + credential detection via grep. ✅
- PreCompact: handoff reminder script. ✅
- Hooks cannot "auto-Read skills". Handled via CLAUDE.md instructions.

### 8. plan.md compact principle
- Full design archived in docs/decisions/master-plan-v2.md.
- plan.md = current phase + next action only. Target ≤50 lines.

### 9. Language protocol (token optimization)
- User reports, task logs → Korean.
- Agent communication, handoffs, plan/context, docs/, skills, code, commits → English.
- English is ~2-3x more token-efficient than Korean for same information.

## Technical Reference
- Repo analysis: docs/references/repo-analysis-summary.md
- Full design: docs/decisions/master-plan-v2.md
- macOS Darwin 25.3.0, ARM64

## Constraints
- User is cost-sensitive → model routing + lazy loading mandatory
- User prefers thorough planning → Hard Gate + Deep Interview
- User reports in Korean, internal in English
- Long-term memory has no decay → management/cleanup critical
