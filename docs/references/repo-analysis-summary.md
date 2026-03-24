---
title: Reference Repo Analysis Summary
keywords: [superpowers, cli-anything, omc, everything-claude-code, TDD, harness]
created: 2026-03-20
last_used: 2026-03-24
type: archive
---

# Reference Repo Analysis Summary (2026-03-20)

## 1. Superpowers (obra) — TDD + Plan Enforcement Framework

### Core Patterns
- **Iron Law + Rationalization Table**: Stating rules alone allows AI to circumvent them. Must include a list of common excuses (e.g., "too simple to need tests") alongside rebuttals for rules to take effect.
- **Hard Gate**: brainstorming → writing-plans → executing-plans. Skipping stages is not allowed.
- **Bite-sized Steps**: Plans must include actual code + exact commands + expected output. Not "add tests" but concrete code.
- **Verification = Ethics**: Framing unverified completion claims as "lying". Words like "should" and "probably" are prohibited.
- **No Sycophancy**: Performative agreement such as "Great!" and "You're absolutely right!" is prohibited.
- **Subagent Isolation**: Session history must not be passed to subagents. Only the exact necessary context should be assembled.
- **Review Loop Cap**: Maximum 3 automatic review rounds → escalate to human.
- **Session Start Hook**: Bootstrap skill is automatically injected at SessionStart.

### Skill Pipeline
brainstorming → writing-plans → subagent-driven-development → finishing-a-development-branch

---

## 2. CLI-Anything (HKUDS) — OS-Level Agent Harness

### Core Patterns
- **Single SOP Document (HARNESS.md)**: A 763-line methodology document referenced by all commands. Prevents duplication.
- **Slash Commands = Independent Markdown Files**: /cli-anything, /cli-anything:refine, /cli-anything:validate, etc.
- **Registry Pattern**: Centralized management of all tools and skills via registry.json.
- **Validation Command**: 52 checks × 8 categories. Automated compliance verification.
- **Dual Output**: --json (machine-readable) + colored output (human-readable). Essential for agent workflows.
- **Probe-before-mutate**: Check state (info, list, status) before making changes. Enables safe automation.
- **Namespace Packages**: Independently installable module structure.

### 7-Step SOP
Codebase Analysis → CLI Design → Implementation → Test Planning → Test Implementation → SKILL.md Generation → Publishing

---

## 3. oh-my-claudecode (Yeachan-Heo) — Risk Management + Workflow Customization

### Core Patterns
- **Write/Review Separation**: architect, critic, and security-reviewer cannot use Write/Edit tools. Prevents self-approval.
- **Mathematical Ambiguity Gating**: Weighted score of goal (40%) + constraints (30%) + success criteria (30%). Execution only when ambiguity is below 20%.
- **Deep Interview**: One question at a time, targeting the weakest dimension; explore the codebase before asking questions.
- **Challenge Agent**: Round 4 (contrarian), Round 6 (simplifier), Round 8 (existentialist).
- **Structured Commit Trailers**: Preserves decision rationale in commits using Constraint:, Rejected:, Directive:, Not-tested:, etc.
- **Ambiguous Request Gate**: Blocked unless a file path, function name, or numbered step is provided. Bypassable with the `force:` prefix.
- **Hierarchical Workflow**: ultrawork → ralph → autopilot → team. Each layer adds one capability.
- **Stage Handoff Documents**: Decisions, alternatives, and risks recorded in .omc/handoffs/<stage>.md. Survives context compression.
- **Failure Mode Documentation**: <Failure_Modes_To_Avoid> section in agent prompts. More effective than success criteria alone.
- **3-Failure Circuit Breaker**: 3 consecutive fix failures → architecture review.

### Pipeline
deep-interview → ralplan (consensus) → autopilot (execution)

---

## 4. everything-claude-code (affaan-m) — Token Optimization + Learning + Verification

### Core Patterns
- **Session Persistence + Failure Memory**: "What Did NOT Work (and why)" section. Prevents retrying failed approaches.
- **Hook-based Observation > Skill-based**: v1 (skills, ~50-80% trigger rate) → v2 (hooks, 100% trigger rate). A critical difference.
- **Project-scoped Instinct**: Learning patterns isolated per project. Promoted to global scope when confidence ≥ 0.8 across 2+ projects.
- **Strategic Compaction**: Suggest /compact after 50 tool calls. At logical transition points (research → planning, debug → feature).
- **Structured Handoff**: Context, Findings, Files Modified, Open Questions, Recommendations.
- **Model Routing**: Haiku (mechanical) / Sonnet (implementation) / Opus (architecture). 30-50% token savings.
- **Trigger Table Lazy Loading**: Keyword-to-path mapping at session start instead of loading all skills upfront. 50%+ baseline savings.
- **Cost Tracker**: Stop hook records per-response token count + USD estimate to costs.jsonl.
- **Quality Gate Hook**: PostToolUse(Edit/Write) → automatic language-specific format/type checks.
- **Loop Operator**: Autonomous loop monitoring. Detects stagnation (2 checkpoints), retry storms, and cost deviation.

### Orchestration Presets
- feature: planner → tdd-guide → code-reviewer → security-reviewer
- bugfix: planner → tdd-guide → code-reviewer
- refactor: architect → code-reviewer → tdd-guide
- security: security-reviewer → code-reviewer → architect
