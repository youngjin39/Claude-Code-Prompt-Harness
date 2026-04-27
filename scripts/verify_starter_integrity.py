#!/usr/bin/env python3

import io
import os
import re
import sys
from pathlib import Path
from contextlib import redirect_stdout
from typing import Iterable, List, Sequence, Tuple

import verify_codex_sync


ROOT = Path(__file__).resolve().parent.parent
CLAUDE_PATH = ROOT / "CLAUDE.md"
MEMORY_MAP_PATH = ROOT / "docs" / "memory-map.md"
PRE_TOOL_USE_PATH = ROOT / ".claude" / "hooks" / "pre-tool-use.sh"
MAIN_ORCHESTRATOR_PATH = ROOT / ".claude" / "agents" / "main-orchestrator.md"
EXECUTOR_AGENT_PATH = ROOT / ".claude" / "agents" / "executor-agent.md"
QUALITY_AGENT_PATH = ROOT / ".claude" / "agents" / "quality-agent.md"
BRAINSTORMING_SKILL_PATH = ROOT / ".claude" / "skills" / "brainstorming" / "SKILL.md"
# These are conditional reads in CLAUDE.md rather than unconditional starter files.
OPTIONAL_REFERENCED_FILES = {"PRD.md", "UI_GUIDE.md", "harness/README.md"}

REQUIRED_FILES = [
    "CLAUDE.md",
    "AGENTS.md",
    "README.md",
    "README.ko.md",
    "ARCHITECTURE.md",
    "ADR.md",
    "execute.py",
    "tasks/plan.md",
    "tasks/context.md",
    "tasks/checklist.md",
    "tasks/change_log.md",
    "tasks/lessons.md",
    "tasks/cost-log.md",
    "docs/memory-map.md",
    "docs/operations/claude-runtime.md",
    "docs/operations/codex-runtime.md",
    "docs/operations/hook-contract.md",
    "docs/operations/harness-application.md",
    "docs/operations/starter-maintenance-mode.md",
    "docs/operations/user-reporting-format.md",
    "scripts/generate_codex_derivatives.sh",
    "scripts/verify_codex_sync.py",
]

REQUIRED_DIRS = [
    ".claude/agents",
    ".claude/hooks",
    ".claude/skills",
    ".codex",
    ".agents",
    ".codex-sync",
    "tasks/handoffs",
    "tasks/log",
    "tasks/sessions",
    "docs/architecture",
    "docs/decisions",
    "docs/domain",
    "docs/integrations",
    "docs/operations",
    "docs/patterns",
    "docs/references",
    "docs/risks",
]

REQUIRED_AGENTS = [
    ".claude/agents/main-orchestrator.md",
    ".claude/agents/executor-agent.md",
    ".claude/agents/quality-agent.md",
]

REQUIRED_HOOKS = [
    ".claude/hooks/session-start.sh",
    ".claude/hooks/pre-compact.sh",
    ".claude/hooks/pre-tool-use.sh",
    ".claude/hooks/tdd-guard.sh",
    ".claude/hooks/post-edit-check.sh",
    ".claude/hooks/session-end.sh",
]

REQUIRED_CORE_SKILLS = [
    ".claude/skills/brainstorming/SKILL.md",
    ".claude/skills/code-review/SKILL.md",
    ".claude/skills/deep-interview/SKILL.md",
    ".claude/skills/git-commit/SKILL.md",
    ".claude/skills/project-doctor/SKILL.md",
    ".claude/skills/testing/SKILL.md",
    ".claude/skills/ux-ui-design/SKILL.md",
    ".claude/skills/verification/SKILL.md",
    ".claude/skills/writing-plans/SKILL.md",
    ".claude/skills/self-audit/SKILL.md",
]

CLAUDE_REQUIRED_SECTIONS = [
    "## Required Reads",
    "## Workflow",
    "## Mode Classification",
    "## Agent / Skill / Hook Contract",
    "## Harness Defaults",
    "## Custom Harness Rules",
    "## Codex Derivation Layer",
    "## Skill Trigger Table",
    "## Context Management",
    "## Language Protocol",
    "## Surgical Change Rules",
    "## Token Efficiency",
    "## Principles",
]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def ok(message: str) -> str:
    return f"OK: {message}"


def fail(message: str) -> str:
    return f"FAIL: {message}"


def check_paths(paths: Sequence[str], expect_dir: bool = False) -> List[str]:
    messages: List[str] = []
    for rel in paths:
        path = ROOT / rel
        if expect_dir and not path.is_dir():
            messages.append(fail(f"required directory missing: {rel}"))
        elif not expect_dir and not path.is_file():
            messages.append(fail(f"required file missing: {rel}"))
    return messages


def check_hook_executable_bits() -> List[str]:
    messages: List[str] = []
    for rel in REQUIRED_HOOKS:
        path = ROOT / rel
        if path.is_file() and not os.access(path, os.X_OK):
            messages.append(fail(f"hook script is not executable: {rel}"))
    return messages


def check_claude_sections() -> List[str]:
    text = read_text(CLAUDE_PATH)
    messages: List[str] = []
    for heading in CLAUDE_REQUIRED_SECTIONS:
        if heading not in text:
            messages.append(fail(f"CLAUDE.md missing section: {heading}"))
    return messages


def check_required_reads_exist() -> List[str]:
    text = read_text(CLAUDE_PATH)
    messages: List[str] = []
    for rel in re.findall(r"`([^`]+\.(?:md|json|sh|py))`", text):
        if "/" not in rel and rel not in {"CLAUDE.md", "AGENTS.md", "README.md", "README.ko.md", "PRD.md", "ARCHITECTURE.md", "ADR.md", "UI_GUIDE.md"}:
            continue
        path = ROOT / rel
        if rel in OPTIONAL_REFERENCED_FILES and not path.exists():
            continue
        if not path.exists():
            messages.append(fail(f"CLAUDE.md references missing file: {rel}"))
    return messages


def check_memory_map_links() -> List[str]:
    text = read_text(MEMORY_MAP_PATH)
    messages: List[str] = []
    for rel in re.findall(r"\(([^)]+\.md)\)", text):
        path = (MEMORY_MAP_PATH.parent / rel).resolve()
        if not path.exists():
            try:
                shown = str(path.relative_to(ROOT))
            except ValueError:
                shown = str(path)
            messages.append(fail(f"memory-map references missing file: {shown}"))
    return messages


def check_plan_size() -> List[str]:
    path = ROOT / "tasks" / "plan.md"
    line_count = len(read_text(path).splitlines())
    if line_count > 50:
        return [fail(f"tasks/plan.md too large for compact working plan: {line_count} lines")]
    return []


def check_pre_tool_use_contract() -> List[str]:
    text = read_text(PRE_TOOL_USE_PATH)
    messages: List[str] = []
    required_snippets = [
        ("main|master|release|develop|production|prod|staging", "pre-tool-use protected-branch set"),
        ("--force-with-lease", "pre-tool-use force-with-lease guard"),
        ("--no-verify|--no-gpg-sign|-c[[:space:]]+commit\\.gpgsign=false", "pre-tool-use hook/signing bypass guard"),
        ("rm[[:space:]]+(-[rRfF]+", "pre-tool-use destructive rm guard"),
        ("git[[:space:]]+reset[[:space:]]+--hard", "pre-tool-use reset --hard shared-ref guard"),
        ("git[[:space:]]+rebase", "pre-tool-use rebase shared-ref guard"),
        ("git[[:space:]]+(filter-branch|filter-repo)", "pre-tool-use history-rewrite tooling guard"),
        ("HEAD~[0-9]+", "pre-tool-use HEAD~N rewrite guard"),
        ("(curl|wget)[^|]*\\|[[:space:]]*(bash|sh|zsh|python)", "pre-tool-use piped remote install guard"),
        ("(^|[[:space:]])sudo([[:space:]]|$)", "pre-tool-use sudo guard"),
        ("path_outside_project", "pre-tool-use project-root path normalization"),
        ('Path(sys.argv[2]).expanduser()', "pre-tool-use path resolution via pathlib"),
        ('Path.home()', "pre-tool-use home-anchored Claude memory exemption"),
        ('".claude" / "projects"', "pre-tool-use Claude memory root anchor"),
        (".env|.env.*|credentials|credentials.*|id_rsa|id_ed25519|*.pem|*.key|*.p12", "pre-tool-use secret file guard"),
        ("(^|/)\\.git/(config|hooks/|refs/|objects/)", "pre-tool-use git internals guard"),
    ]
    for snippet, label in required_snippets:
        if snippet not in text:
            messages.append(fail(f"missing {label} coverage in .claude/hooks/pre-tool-use.sh"))
    return messages


def check_source_contract_alignment() -> List[str]:
    messages: List[str] = []

    main_text = read_text(MAIN_ORCHESTRATOR_PATH)
    main_required_snippets = [
        (
            "Follow `CLAUDE.md` `## Principles`, `## Workflow`, `## Mode Classification`, and `## Agent / Skill / Hook Contract` as the shared runtime policy.",
            "main-orchestrator shared runtime reference",
        ),
        (
            "Read `tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, and the latest file in `tasks/sessions/` when present.",
            "main-orchestrator startup read set",
        ),
        (
            "If the task touches starter-maintenance paths, run `python3 scripts/verify_starter_integrity.py` before claiming completion.",
            "main-orchestrator starter verification gate",
        ),
    ]
    for snippet, label in main_required_snippets:
        if snippet not in main_text:
            messages.append(fail(f"missing {label} in .claude/agents/main-orchestrator.md"))

    executor_text = read_text(EXECUTOR_AGENT_PATH)
    executor_required_snippets = [
        (
            "For starter work, keep source docs, generated artifacts, and verifier expectations aligned in the same task.",
            "executor-agent starter alignment guidance",
        ),
        (
            "For Claude/Codex boundary changes, follow `docs/operations/harness-application.md` and `docs/operations/starter-maintenance-mode.md`.",
            "executor-agent cross-harness parity guidance",
        ),
    ]
    for snippet, label in executor_required_snippets:
        if snippet not in executor_text:
            messages.append(fail(f"missing {label} in .claude/agents/executor-agent.md"))

    quality_text = read_text(QUALITY_AGENT_PATH)
    quality_required_snippets = [
        (
            "For starter or generated-runtime changes, review docs, generated artifacts, and verifier expectations as one contract.",
            "quality-agent starter contract review guidance",
        ),
        (
            "Cross-harness drift: does the change respect `docs/operations/harness-application.md`, especially where Claude has hooks and Codex does not?",
            "quality-agent cross-harness drift check",
        ),
        (
            "Mode drift: does `docs/operations/starter-maintenance-mode.md` still classify and gate this kind of task correctly?",
            "quality-agent mode drift check",
        ),
    ]
    for snippet, label in quality_required_snippets:
        if snippet not in quality_text:
            messages.append(fail(f"missing {label} in .claude/agents/quality-agent.md"))

    brainstorming_text = read_text(BRAINSTORMING_SKILL_PATH)
    required_brainstorming_snippets = [
        (
            "Required before coding only when meaningful design choices exist.",
            "brainstorming description conditional gate wording",
        ),
        (
            "When this skill is triggered, no code without passing this stage.",
            "brainstorming hard-gate conditional wording",
        ),
    ]
    for snippet, label in required_brainstorming_snippets:
        if snippet not in brainstorming_text:
            messages.append(fail(f"missing {label} in .claude/skills/brainstorming/SKILL.md"))

    return messages


def run_codex_sync_verifier() -> Tuple[List[str], int]:
    buffer = io.StringIO()
    with redirect_stdout(buffer):
        exit_code = verify_codex_sync.run()
    output_lines = [line for line in buffer.getvalue().splitlines() if line.strip()]
    if exit_code != 0 and not output_lines:
        output_lines = [fail("verify_codex_sync.py failed without output")]
    return output_lines, exit_code


def summarize_group(messages: Iterable[str], success_message: str) -> List[str]:
    items = list(messages)
    return items if items else [ok(success_message)]


def main() -> int:
    messages: List[str] = []

    messages.extend(summarize_group(check_paths(REQUIRED_FILES), "all required starter files exist"))
    messages.extend(summarize_group(check_paths(REQUIRED_DIRS, expect_dir=True), "all required starter directories exist"))
    messages.extend(summarize_group(check_paths(REQUIRED_AGENTS), "all required agent source files exist"))
    messages.extend(summarize_group(check_paths(REQUIRED_HOOKS), "all required hook scripts exist"))
    messages.extend(summarize_group(check_hook_executable_bits(), "all required hook scripts are executable"))
    messages.extend(summarize_group(check_paths(REQUIRED_CORE_SKILLS), "all required core skill files exist"))
    messages.extend(summarize_group(check_claude_sections(), "CLAUDE.md contains required runtime sections"))
    messages.extend(summarize_group(check_required_reads_exist(), "CLAUDE.md required-read references resolve"))
    messages.extend(summarize_group(check_memory_map_links(), "memory-map references resolve"))
    messages.extend(summarize_group(check_plan_size(), "tasks/plan.md remains compact"))
    messages.extend(summarize_group(check_pre_tool_use_contract(), "pre-tool-use hook covers the documented blocked-intent enforcement markers"))
    messages.extend(summarize_group(check_source_contract_alignment(), "selected source agent and skill contract markers align with the documented startup, parity, and brainstorming policy"))

    sync_messages, sync_code = run_codex_sync_verifier()
    messages.extend(sync_messages)

    for message in messages:
        print(message)

    failed = any(message.startswith("FAIL:") for message in messages) or sync_code != 0
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
