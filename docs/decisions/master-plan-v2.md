---
title: Master Plan v2 — Full Design Archive
keywords: [3-axis, pipeline, master-plan, workflow, memory, context]
created: 2026-03-20
last_used: 2026-03-24
type: archive
---

# Master Plan — prompt_DEV Harness (v2, Three-Axis Redesign)

> Core axes: **Development Workflow** / **Memory Efficiency** / **Context Efficiency**
> Foundation: Analysis of CLI-Anything, oh-my-claudecode, Superpowers, everything-claude-code

---

## Design Principles

```
                    ┌─────────────────────┐
                    │  Development         │  ← Pipeline through which work flows
                    │  Workflow            │
                    │  (How we work)       │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                                  │
   ┌──────────▼──────────┐           ┌──────────▼──────────┐
   │   Memory Efficiency  │           │  Context Efficiency  │
   │  (What we remember)  │           │  (What we load)      │
   └─────────────────────┘           └─────────────────────┘
```

- Workflow is the center. Memory and context are the two axes that support the workflow.
- Rule enforcement (Iron Laws, etc.) is **embedded** within each pipeline stage. Not a separate Phase.
- Every Phase must contribute to all three axes. No Phase that strengthens only one axis.

---

## Current State (v1 Complete)

| Category | Have | Missing |
|---|---|---|
| Workflow | 2 agents, 4 skills, basic CLAUDE.md | No pipeline design, no inter-stage gates |
| Memory | docs/memory-map.md (empty index), 5 files in tasks/ | Not searchable, categories not built, no failure memory |
| Context | (none) | No lazy loading, no compression strategy, no model routing |

---

## Phase 1 — Foundation

> Goal: Establish the **skeleton** of each of the three axes.

### 1.1 Workflow Pipeline Design

#### 1.1.1 Task Flow Definition
```
Request enters
  │
  ├─ Ambiguous? ──→ [Deep Interview Lite] ──→ Clarified
  │                                             │
  ▼                                             ▼
Classify (simple/complex)
  │
  ├─ Simple (1~2 steps) ──→ Direct execution ──→ Self-check ──→ Done
  │
  └─ Complex (3+ steps) ──→ [Plan Mode]
                              │
                              ▼
                        ┌─ brainstorming ─┐
                        │  Design +        │
                        │  Compare alts    │
                        └──────┬─────────┘
                               │ ✅ User approval
                               ▼
                        ┌─ writing-plans ──┐
                        │ Concrete step    │
                        │ plan             │
                        │ (code+cmd+output)│
                        └──────┬──────────┘
                               │ ✅ Plan approval
                               ▼
                        ┌─ execution ──────┐
                        │ Step-by-step     │
                        │ execution+verify │
                        │ (3 failures→STOP)│
                        └──────┬──────────┘
                               │
                               ▼
                        ┌─ verification ───┐
                        │ Evidence-based   │
                        │ verification     │
                        │ (no should/      │
                        │  probably)       │
                        └──────┬──────────┘
                               │ ✅ Verification passed
                               ▼
                           Done + Record
```

#### 1.1.2 Files to Create
| File | Role |
|---|---|
| `.claude/skills/brainstorming/SKILL.md` | Design enforcement. Hard Gate before coding. |
| `.claude/skills/writing-plans/SKILL.md` | Concrete implementation plan (Bite-sized Steps). |
| `.claude/skills/verification/SKILL.md` | Evidence-based verification. No unverified completion. |
| `.claude/agents/executor-agent.md` | Dedicated code writing. Write/Edit allowed. |

#### 1.1.3 Existing Files to Modify
| File | Change |
|---|---|
| `.claude/agents/quality-agent.md` | Add disallowedTools: Write, Edit (review-only) |
| `.claude/agents/main-orchestrator.md` | Replace with pipeline protocol + add failure modes section |
| `CLAUDE.md` | Replace workflow orchestration section with pipeline diagram |

#### 1.1.4 Gate Conditions for Each Stage
| Stage | Entry Condition | Exit Condition |
|---|---|---|
| brainstorming | Classified as complex task | User approves design |
| writing-plans | Exit brainstorming | Plan includes concrete code + commands + expected output |
| execution | Exit writing-plans | All steps complete or 3 failures → STOP |
| verification | Exit execution | Verification passed based on evidence (execution results) |

#### 1.1.5 Embedded Rules (Not a separate Phase)
- **brainstorming**: Must compare 2~3 alternatives. Presenting only 1 option is prohibited.
- **writing-plans**: Abstract expressions like "add tests" are prohibited. Must include actual code.
- **execution**: 3-failure circuit breaker. Architecture review instead of a 4th attempt.
- **verification**: "should work", "probably fine" prohibited. Only execution evidence accepted.

---

### 1.2 Neuron Memory Structure Setup

#### 1.2.1 Directory Structure
```
docs/
├── memory-map.md              # Master index (category → keyword → file)
├── architecture/              # System structure, design patterns
├── decisions/                 # ADR (Architecture Decision Records)
├── patterns/                  # Recurring code/workflow patterns
├── domain/                    # Domain knowledge, business rules
├── risks/                     # Known risks, vulnerabilities
├── integrations/              # External system integrations
└── references/                # Reference repos, documents (already exists)
```

#### 1.2.2 memory-map.md Redesign (Keyword Index)
```markdown
# Neuron Memory Map

## Search Protocol
1. Keyword matching: scan the index below for relevant keywords
2. Enter category: check list of entries for matched category
3. Selective load: Read only the needed files
4. Never load everything: do not read an entire category at once

## Keyword → Category Mapping
| Keyword | Category | File |
|---|---|---|
| (accumulated as work progresses) | | |

## Entries by Category
### architecture
- (none)
...
```

#### 1.2.3 Memory Storage Rules
- Max 50 lines per file. Split if exceeded.
- Frontmatter required: `title`, `keywords`, `created`, `last_used`.
- Update `last_used` to track usage frequency (no decay, but used for priority assessment).
- Update memory-map.md keyword index simultaneously when saving.

#### 1.2.4 Failure Memory (lessons.md expansion)
```markdown
# Lessons

## Failed Approaches (What Did NOT Work)
| Date | Task | Approach Tried | Reason for Failure | Correct Approach |
|---|---|---|---|---|

## Success Patterns (What Worked)
| Date | Task | Approach | Why It Was Effective |
|---|---|---|---|

## Promoted Rules
(Promoted to rules when the above tables show 2+ repetitions)
```

#### 1.2.5 Files to Create
| File | Role |
|---|---|
| `docs/architecture/` (dir) | System structure memory |
| `docs/decisions/` (dir) | ADR repository |
| `docs/patterns/` (dir) | Recurring patterns |
| `docs/domain/` (dir) | Domain knowledge |
| `docs/risks/` (dir) | Risk records |
| `docs/integrations/` (dir) | External integrations |
| `docs/memory-map.md` (modify) | Redesign with keyword index approach |
| `tasks/lessons.md` (modify) | Failure/success tables + rule promotion |

---

### 1.3 Context Efficiency Basics

#### 1.3.1 Skill Lazy Loading
Current problem: CLAUDE.md lists all skills → all loaded into context at session start.

Solution:
- CLAUDE.md keeps only the **trigger table (keyword → skill name)**. No skill body text.
- Skill body is loaded via Read only when triggered.
- Loaded skill is released from context when that task ends (natural compression).

```markdown
## Skill Trigger Table (body loaded on trigger)
| Keyword | Skill | Path |
|---|---|---|
| review, PR, quality | code-review | .claude/skills/code-review/SKILL.md |
| test, TDD | testing | .claude/skills/testing/SKILL.md |
| commit, git | git-commit | .claude/skills/git-commit/SKILL.md |
| diagnose, health-check | project-doctor | .claude/skills/project-doctor/SKILL.md |
| design, brainstorming | brainstorming | .claude/skills/brainstorming/SKILL.md |
| plan, implementation plan | writing-plans | .claude/skills/writing-plans/SKILL.md |
| verify, completion check | verification | .claude/skills/verification/SKILL.md |
```

#### 1.3.2 Model Routing Table
```markdown
## Model Routing
| Task Type | Model | Rationale |
|---|---|---|
| File search, keyword lookup, simple transforms | haiku | Mechanical work, no judgment needed |
| Code writing, bug fixes, testing | sonnet | Implementation ability needed, no architectural judgment required |
| Architecture design, planning, review synthesis | opus | Complex judgment + context understanding required |
```

#### 1.3.3 Handoff Documents (Context compression survival)
```
tasks/handoffs/
├── {stage}-handoff.md          # Inter-stage transfer documents
```

Format:
```markdown
# Handoff: {from_stage} → {to_stage}
- **Decisions**: (what was finalized in this stage)
- **Rejected Alternatives**: (what was considered but discarded + reasons)
- **Remaining Risks**: (what the next stage should watch for)
- **Next Action**: (exactly what needs to be done)
- **File List**: (files changed/created)
```

#### 1.3.4 Session Save/Restore Format
```
tasks/sessions/
├── {YYYY-MM-DD}-{short-id}.md  # Session snapshots
```

Format:
```markdown
# Session: {date} {task summary}
## What Worked (with evidence)
## What Did NOT Work (with reasons) ← most important
## Decisions Made
## Exact Next Step
## Files Modified
```

#### 1.3.5 Strategic Compression Guidelines (added to CLAUDE.md)
```markdown
## Context Management
- Consider /compact at logical transition points: research→plan, debug→feature, design→implementation.
- Write a handoff to tasks/handoffs/ before compressing.
- Do not start complex tasks in the last 20% of the context window.
- Never pass session history to sub-agents. Assemble only the necessary context.
```

#### 1.3.6 Files to Create
| File | Role |
|---|---|
| `tasks/handoffs/` (dir) | Handoff document storage |
| `tasks/sessions/` (dir) | Session snapshot storage |
| `CLAUDE.md` (modify) | Add trigger table, model routing, context management |

---

## Phase 2 — Deepening

> Goal: Increase the **precision** of each of the three axes.

### 2.1 Workflow Refinement

#### 2.1.1 Deep Interview Skill (full version)
- Ambiguity score: Goal (40%) + Constraints (30%) + Success criteria (30%).
- One question at a time. Target the weakest dimension.
- Explore codebase first, then ask questions (avoid unnecessary questions = token savings).
- Challenge rounds: 4 (devil's advocate), 6 (simplification advocate).
- Proceed to next stage only when ambiguity is below 20%.

#### 2.1.2 Ambiguous Request Gate
- On main-orchestrator entry: if none of file path, function name, or numbered steps present → redirect to Deep Interview.
- Can bypass with `force:` prefix.

#### 2.1.3 Orchestration Presets
| Preset | Pipeline | Model Distribution |
|---|---|---|
| feature | brainstorming → writing-plans → executor → code-review → verification | opus→opus→sonnet→sonnet→sonnet |
| bugfix | deep-interview-lite → executor → testing → verification | sonnet→sonnet→sonnet→sonnet |
| refactor | brainstorming → writing-plans → executor → code-review | opus→opus→sonnet→sonnet |
| security | code-review(security-focus) → executor → verification | opus→sonnet→sonnet |

#### 2.1.4 Structured Commit Trailers
Add to git-commit skill:
```
Constraint: (constraints of this change)
Rejected: (alternatives considered but discarded)
Directive: (the directive this change follows)
Not-tested: (scenarios not tested)
```

#### 2.1.5 Files to Create/Modify
| File | Action |
|---|---|
| `.claude/skills/deep-interview/SKILL.md` | new |
| `.claude/agents/main-orchestrator.md` | Add ambiguous request gate |
| `.claude/skills/git-commit/SKILL.md` | Add commit trailers |
| `CLAUDE.md` | Add orchestration preset table |

---

### 2.2 Memory Search Enhancement

#### 2.2.1 Keyword Index Auto-Update
- Automatically add keyword rows to memory-map.md when saving memory.
- Keyword extraction rule: from `keywords` field in file frontmatter.
- Duplicate keywords → add file to same row (1:N mapping).

#### 2.2.2 Memory Utilization Protocol (added to CLAUDE.md)
```
1. At task start: scan memory-map.md keyword table (Read, table only)
2. Relevant keyword found: Read only that file
3. No relevant keyword: skip memory load (token savings)
4. At task completion: new learnings → save to docs/{category}/ + update index
```

#### 2.2.3 Memory Promotion Pipeline
```
Project-local (docs/{category}/)
    │
    ├─ Same pattern observed 2+ times → promote to rule (lessons.md)
    │
    └─ confidence≥0.8 across 2+ projects → global promotion (~/.claude/global-memory/)
```

#### 2.2.4 Registry Pattern
`.claude/registry.json`:
```json
{
  "agents": [
    {"name": "main-orchestrator", "model": "opus", "role": "orchestration", "path": ".claude/agents/main-orchestrator.md"},
    ...
  ],
  "skills": [
    {"name": "code-review", "triggers": ["review","PR","quality"], "path": ".claude/skills/code-review/SKILL.md"},
    ...
  ],
  "memory_categories": ["architecture","decisions","patterns","domain","risks","integrations","references"]
}
```
- project-doctor validates registry vs actual file consistency.

#### 2.2.5 Files to Create/Modify
| File | Action |
|---|---|
| `docs/memory-map.md` | Add keyword auto-update rules |
| `.claude/registry.json` | new — central manifest |
| `.claude/skills/project-doctor/SKILL.md` | Add registry validation |
| `CLAUDE.md` | Add memory utilization protocol |

---

### 2.3 Precise Context Management

#### 2.3.1 Verification Loop 6-Stage Gate
```
Build → Type Check → Lint → Test Suite → Security Scan → Diff Review
```
- Structured PASS/FAIL reporting at each stage.
- Overall READY/NOT READY verdict.
- Immediate stop on per-stage failure (saves tokens on unnecessary subsequent stages).

#### 2.3.2 Sub-agent Context Isolation
- **Never** pass session history to sub-agents.
- Extract only necessary context from handoff documents and pass that.
- 1 sub-agent = 1 task = minimum context.

#### 2.3.3 Cost Tracking Basics
- tasks/cost-log.md: record approximate token usage per session.
- Format: `| Date | Task | Model | Estimated Tokens | Notes |`
- Start with manual recording, not automated. Automate in Phase 3.

#### 2.3.4 Files to Create/Modify
| File | Action |
|---|---|
| `.claude/skills/verification/SKILL.md` | Detail the 6-stage gate |
| `tasks/cost-log.md` | new — cost tracking |
| `CLAUDE.md` | Add sub-agent isolation rules |

---

## Phase 3 — Automation

> Goal: **Automate** manual processes and secure scalability.

### 3.1 Workflow Automation

#### 3.1.1 SessionStart Hook
- Automatically executed at session start:
  1. Read tasks/plan.md, context.md, checklist.md, lessons.md.
  2. Check recent session snapshot (tasks/sessions/).
  3. Output 3-line summary → resume work.
- Implemented via `.claude/settings.local.json` hooks configuration.

#### 3.1.2 Post-Done Auto Verification
- Automatically on task completion mark:
  1. Verify change_log.md is recorded.
  2. Output list of changed files.
  3. Trigger verification skill.

#### 3.1.3 Loop Operator (Watchdog)
- Detect stagnation in autonomous loops (no progress across 2 checkpoints).
- Detect retry storms (same error 3 times).
- On detection: STOP → escalate to user.

#### 3.1.4 Files to Create/Modify
| File | Action |
|---|---|
| `.claude/settings.local.json` | Add hooks section |
| `.claude/skills/session-bootstrap/SKILL.md` | new — session start auto-load |

---

### 3.2 Memory Automation

#### 3.2.1 Memory Auto-Harvest
- Automatic judgment at task completion: "Was anything new learned from this task?"
- If yes → save to docs/{category}/ + update memory-map.md.
- If no → skip (prevent unnecessary memory).

#### 3.2.2 Memory Consistency Check (project-doctor extension)
- Verify all file paths in memory-map.md actually exist.
- Check for files exceeding 50 lines.
- Warn on entries with last_used not updated for 6+ months.

#### 3.2.3 Large-Scale Transition Criteria
- 100+ memory files → consider introducing SQLite index.
- memory-map.md exceeds 200 lines → split into per-category sub-indices.
- State judgment criteria at the top of docs/memory-map.md.

#### 3.2.4 Files to Create/Modify
| File | Action |
|---|---|
| `.claude/skills/project-doctor/SKILL.md` | Add memory consistency check |
| `docs/memory-map.md` | State large-scale transition criteria |

---

### 3.3 Context Automation

#### 3.3.1 Strategic Compression Auto-Suggestion
- Tool call counter: suggest /compact at 50 calls.
- Detect logical transition points: suggest on research→plan, debug→feature transitions.
- Auto-write handoff before compression.

#### 3.3.2 Cost Tracking Automation
- Automatically record per-session token estimates in Stop hook.
- Token price table by model.
- Weekly summary (included in project-doctor).

#### 3.3.3 Quality Gate Hook
- Automatically on PostToolUse(Edit/Write):
  - Language detection → run corresponding formatter.
  - Type check (TS/Go, etc.).
  - Warn on console.log / print debug statements.

#### 3.3.4 Files to Create/Modify
| File | Action |
|---|---|
| `.claude/settings.local.json` | Add PostToolUse hook |
| `tasks/cost-log.md` | Convert to auto-recording format |

---

## Phase Deliverables Summary

| Phase | Workflow | Memory | Context | New Files | Modified Files |
|---|---|---|---|---|---|
| **1 Foundation** | 4-stage pipeline + 3 agents + 3 skills | 7 categories + keyword index + failure memory | Lazy loading + model routing + handoffs + sessions | ~10 | ~5 |
| **2 Deepening** | Deep Interview + 4 presets + commit trailers | Auto-update + promotion pipeline + registry | 6-stage verification + sub-agent isolation + cost tracking | ~5 | ~6 |
| **3 Automation** | SessionStart hook + Post-Done + loop watchdog | Auto-harvest + consistency check + large-scale transition | Auto compress suggest + cost automation + quality hook | ~2 | ~4 |

---

## Architecture Decisions (Updated)

| Decision | Rationale | Source |
|---|---|---|
| Three-axis centered design | Workflow/memory/context are independent axes. Strengthening only one axis creates imbalance. | User feedback |
| Rules = embedded in pipeline | Separating into a distinct Phase creates a disconnect. Must be baked into each stage to be effective. | Superpowers |
| Memory search = keyword index | Flat list is not searchable. Keyword→file mapping enables 0.1s lookup. | User requirement |
| Lazy loading | Pre-loading all skills = wasted tokens. Load body text only on trigger. | everything-claude-code |
| Handoff documents | Decision context is lost during context compression/session transitions. Preserve with lightweight documents. | OMC |
| Failure memory first | Remembering failures is more token-efficient than successes. | everything-claude-code |

---

## Execution Order

Phase 1 → User review → Phase 2 → User review → Phase 3 → User review
Verify with project-doctor after each Phase completes.

---

## Appendix: v2.1 Amendments (7 items, 2026-03-20)

### Amendment 1: plan.md compacted (#7)
- Full design → moved to this file (docs/decisions/master-plan-v2.md).
- tasks/plan.md is current Phase + next actions only. Max 50 lines.

### Amendment 2: Deep Interview Lite definition (#2)
- **Lite (Phase 1)**: 1~2 clarifying questions when ambiguous. No scoring.
- **Full (Phase 2)**: Ambiguity score (Goal 40% + Constraints 30% + Success criteria 30%), challenge rounds.

### Amendment 3: executor/orchestrator branch criteria (#3)
- Simple (1~2 steps): orchestrator executes directly. Avoid sub-agent call overhead.
- Complex (3+ steps): delegate to executor-agent. Apply pipeline.
- When ambiguous, classify as complex (over-estimation is safer than under-estimation).

### Amendment 4: Memory 4-layer → 3-layer reduction (#4)
- `docs/` = project knowledge (what we know)
- `tasks/lessons.md` = behavioral rules (what to do/not do)
- `tasks/sessions/` = session restoration (ephemeral)
- ~~.claude/agent-memory/~~ → merged into docs/. Separate layer removed.

### Amendment 5: registry.json removed (#5)
- Trigger table (CLAUDE.md) + glob validation (project-doctor) is sufficient.
- Eliminates the burden of keeping two locations in sync.

### Amendment 6: Hook feasibility verification (#6)
- Claude Code hooks = shell command based. Confirmed capabilities:
  - SessionStart: `cat` → stdout injected into context. ✅
  - PostToolUse(Edit|Write): `jq + linter`. ✅
  - PreCompact: handoff script execution. ✅
- "Auto Read skill" via hook is not possible. Handle via CLAUDE.md instructions.

### Amendment 7: CLAUDE.md v2 synchronization (#1)
- Reflected pipeline diagram, trigger table (lazy loading), model routing, agent role separation, memory 3-layer, context management guidelines.

### Post-Amendment Architecture Decisions (additions)
| Decision | Rationale | Source |
|---|---|---|
| orchestrator = judgment + simple execution, executor = complex-dedicated | Avoid sub-agent overhead for simple tasks | Practical judgment |
| Memory 3-layer (docs/lessons/sessions) | 4-layer has ambiguous roles. 3-layer enables instant answer to "where to store?" | Review feedback |
| registry unnecessary | Trigger table + glob is sufficient. Only adds duplicate management burden at small scale | CLI-Anything is for 16-harness use |
| plan.md ≤ 50 lines | 507-line plan is self-contradictory. Per-session reload cost | Context efficiency principle |
| hooks = cat/jq/script | Confirmed actual Claude Code hook implementation. Shell commands only. | hooks documentation verification |
