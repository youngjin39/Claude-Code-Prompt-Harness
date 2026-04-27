#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Set


ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / ".codex-sync" / "manifest.json"
CLAUDE_PATH = ROOT / "CLAUDE.md"
AGENTS_PATH = ROOT / "AGENTS.md"
SYNC_README_PATH = ROOT / ".codex-sync" / "README.md"
GENERATOR_PATH = ROOT / "scripts" / "generate_codex_derivatives.sh"
HARNESS_README_PATH = ROOT / "harness" / "README.md"
README_PATH = ROOT / "README.md"
README_KO_PATH = ROOT / "README.ko.md"
CODEX_CONFIG_PATH = ROOT / ".codex" / "config.toml"
GENERATED_MARKERS = ("GENERATED FILE:", "# GENERATED FILE:")
STARTUP_SNIPPET = "latest session snapshot when present"
BLOCKED_INTENT_SNIPPET = "destructive `rm`, protected-branch force push, hook/signing bypass flags, shared-ref history rewrite, piped remote install, `sudo`, writes outside the project, writes to secret material, and writes into `.git` internals"
MANUAL_COMPLIANCE_SNIPPET = "manual compliance + verifier-checked contract drift, not native pre-execution blocking or behavioral parity"
SELF_RECOGNITION_SNIPPET = "AI-facing contract text must let the agent identify its current runtime, active mode, enforcement path, and completion gate before acting."
PRECOMPACT_MIRROR_SNIPPET = "before invoking compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract,"
CODEX_INCIDENT_LIMITATION_SNIPPET = "do not claim hook-driven incident counting for Codex-only sessions unless a Codex workflow explicitly records incidents; otherwise `harness/state/incidents.json` remains Claude-hook state rather than a Codex parity guarantee,"
SESSIONEND_MIRROR_SNIPPET = "at session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract,"
README_SELF_RECOGNITION_SNIPPET = "The core contract is optimized for AI self-recognition: the always-read docs tell the agent which runtime it is in, which mode is active, what enforces policy, and what proves completion."
README_KO_SELF_RECOGNITION_SNIPPET = "핵심 계약은 AI 자기인식에 맞춰져 있습니다. 항상 읽는 문서만으로도 에이전트가 지금 어떤 런타임에 있는지, 어떤 모드인지, 무엇이 정책을 강제하는지, 무엇이 완료 증거인지 파악할 수 있어야 합니다."
CUSTOM_HARNESS_RULES_HEADING = "## Custom Harness Rules"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_manifest_sources(source_field: str) -> List[Path]:
    parts = [part.strip() for part in source_field.split("+")]
    return [ROOT / part for part in parts if part]


def parse_core_skills_from_generator(text: str) -> List[str]:
    match = re.search(r"CORE_SKILLS=\(\n(?P<body>.*?)\n\)", text, re.S)
    if not match:
        raise ValueError("CORE_SKILLS block not found in generator")
    return [line.strip() for line in match.group("body").splitlines() if line.strip()]


def parse_full_skills_from_generator(text: str) -> List[str]:
    match = re.search(r"FULL_SKILLS=\(\n(?P<body>.*?)\n\)", text, re.S)
    if not match:
        raise ValueError("FULL_SKILLS block not found in generator")
    return [line.strip() for line in match.group("body").splitlines() if line.strip()]


def parse_core_skills_from_claude(text: str) -> List[str]:
    for line in text.splitlines():
        if not line.startswith("Core default = "):
            continue
        skills = re.findall(r"`([^`]+)`", line)
        if skills:
            return [item.strip() for item in skills]
    raise ValueError("Core default line not found in CLAUDE.md")


def parse_codex_skills_from_agents(text: str) -> List[str]:
    match = re.search(r"- Skills: `([^`]+)`", text)
    if not match:
        raise ValueError("Skills line not found in AGENTS.md")
    return [item.strip() for item in match.group(1).split(",")]


def parse_skill_names_from_sync_readme(text: str) -> Set[str]:
    match = re.search(r"\.agents/skills/\{([^}]+)\}", text)
    if not match:
        raise ValueError("Checked-in pack skill set not found in .codex-sync/README.md")
    return {item.strip() for item in match.group(1).split(",") if item.strip()}


def mapped_targets(manifest: dict) -> Set[str]:
    targets: Set[str] = set()
    for mapping in manifest.get("mappings", []):
        for target in mapping.get("targets", []):
            targets.add(target)
    return targets


def actual_generated_targets() -> Set[str]:
    targets = {"AGENTS.md", ".codex/config.toml"}
    targets.update(str(path.relative_to(ROOT)) for path in sorted((ROOT / ".codex" / "agents").glob("*.toml")))
    targets.update(str(path.relative_to(ROOT)) for path in sorted((ROOT / ".agents" / "skills").glob("*/SKILL.md")))
    return targets


def has_generated_marker(path: Path) -> bool:
    head = "\n".join(read_text(path).splitlines()[:5])
    return any(marker in head for marker in GENERATED_MARKERS)


def ensure_contains(path: Path, snippet: str, label: str, messages: List[str]) -> None:
    if snippet not in read_text(path):
        messages.append(f"FAIL: {label} missing from {path.relative_to(ROOT)}")


def ensure_not_contains(path: Path, snippet: str, label: str, messages: List[str]) -> None:
    if snippet in read_text(path):
        messages.append(f"FAIL: {label} should not appear in {path.relative_to(ROOT)}")


def compare_generated_outputs(messages: List[str]) -> None:
    active_profile, _ = detect_active_profile()
    with tempfile.TemporaryDirectory(prefix="codex-sync-verify-") as tmpdir:
        env = os.environ.copy()
        env["CODEX_DERIVATION_OUTPUT_ROOT"] = tmpdir
        env["CODEX_DERIVATION_PROFILE"] = active_profile
        result = subprocess.run(
            ["bash", str(GENERATOR_PATH)],
            cwd=ROOT,
            env=env,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            stderr = result.stderr.strip() or result.stdout.strip() or "generator failed without output"
            messages.append(f"FAIL: could not regenerate Codex outputs for drift check: {stderr}")
            return

        targets = sorted(actual_generated_targets() | {".codex-sync/manifest.json"})
        for rel in targets:
            expected = Path(tmpdir) / rel
            actual = ROOT / rel
            if not expected.exists():
                messages.append(f"FAIL: regenerated output missing during drift check: {rel}")
                continue
            if not actual.exists():
                messages.append(f"FAIL: checked-in generated output missing during drift check: {rel}")
                continue
            if expected.read_bytes() != actual.read_bytes():
                messages.append(f"FAIL: generated output drift detected: {rel}")


def check_approval_policy_mapping(messages: List[str]) -> None:
    settings_path = None
    primary = ROOT / ".claude" / "settings.local.json"
    fallback = ROOT / ".claude" / "settings.json"
    if primary.exists():
        settings_path = primary
    elif fallback.exists():
        settings_path = fallback
    expected = "on-request"
    if settings_path is not None:
        settings = json.loads(read_text(settings_path))
        mode = settings.get("permissions", {}).get("defaultMode")
        if mode == "bypassPermissions":
            expected = "never"

    config_text = read_text(CODEX_CONFIG_PATH)
    match = re.search(r'^approval_policy = "([^"]+)"$', config_text, re.M)
    if not match:
        messages.append("FAIL: approval_policy missing from .codex/config.toml")
        return
    actual = match.group(1)
    if actual != expected:
        messages.append(
            f'FAIL: approval_policy drift: expected "{expected}" from Claude settings source, found "{actual}" in .codex/config.toml'
        )


def detect_active_profile() -> tuple[str, Set[str]]:
    generator_text = read_text(GENERATOR_PATH)
    core_skills = set(parse_core_skills_from_generator(generator_text))
    try:
        full_skills = set(parse_full_skills_from_generator(generator_text))
    except ValueError:
        full_skills = core_skills

    manifest = json.loads(read_text(MANIFEST_PATH))
    manifest_skill_targets = {
        Path(target).parts[-2]
        for target in mapped_targets(manifest)
        if target.startswith(".agents/skills/")
    }
    if manifest_skill_targets == full_skills and full_skills != core_skills:
        return "full", full_skills
    return "core", core_skills


def validate_runtime_doc_contracts() -> List[str]:
    messages: List[str] = []
    required_snippets = [
        (
            CLAUDE_PATH,
            "3+ step task with concrete scope and no meaningful design fork → `writing-plans` → `executor-agent` → `verification`",
            "clear-scope complex workflow rule",
        ),
        (
            CLAUDE_PATH,
            "`SessionStart` loads startup context (`tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, latest session snapshot when present);",
            "SessionStart startup context contract",
        ),
        (
            CLAUDE_PATH,
            "10. `docs/operations/hook-contract.md` when hook behavior, enforcement boundaries, or Codex parity matters",
            "hook-contract required read",
        ),
        (
            CLAUDE_PATH,
            "11. `docs/operations/harness-application.md` when applying harness techniques across Claude and Codex",
            "harness-application required read",
        ),
        (
            CLAUDE_PATH,
            "12. `docs/operations/starter-maintenance-mode.md` when the task modifies starter contracts, verifiers, or cross-harness behavior",
            "starter-maintenance-mode required read",
        ),
        (
            CLAUDE_PATH,
            SELF_RECOGNITION_SNIPPET,
            "CLAUDE self-recognition contract rule",
        ),
        (
            CLAUDE_PATH,
            PRECOMPACT_MIRROR_SNIPPET,
            "CLAUDE PreCompact Codex mirror rule",
        ),
        (
            CLAUDE_PATH,
            CODEX_INCIDENT_LIMITATION_SNIPPET,
            "CLAUDE Codex incidents limitation rule",
        ),
        (
            CLAUDE_PATH,
            SESSIONEND_MIRROR_SNIPPET,
            "CLAUDE SessionEnd Codex mirror rule",
        ),
        (
            CLAUDE_PATH,
            "use verification commands as completion gates when hook enforcement is unavailable.",
            "Codex verification-gate mirror rule",
        ),
        (
            CLAUDE_PATH,
            "Starter contract / verifier / generated-artifact work → enter Starter Maintenance Mode",
            "starter mode classification rule",
        ),
        (
            CLAUDE_PATH,
            "Core default = `brainstorming`, `code-review`, `deep-interview`, `git-commit`, `project-doctor`, `self-audit`, `testing`, `ux-ui-design`, `verification`, `writing-plans`.",
            "CLAUDE self-audit core-default rule",
        ),
        (
            CLAUDE_PATH,
            "Claude/Codex boundary or mirroring change → enter Cross-Harness Parity Mode",
            "cross-harness parity mode classification rule",
        ),
        (
            CLAUDE_PATH,
            "classify Starter Maintenance Mode and Cross-Harness Parity Mode using the same entry criteria,",
            "Codex mode-classification mirror rule",
        ),
        (
            CLAUDE_PATH,
            f"name the same blocked-intent set in instruction form: {BLOCKED_INTENT_SNIPPET},",
            "Codex blocked-intent mirror rule",
        ),
        (
            CLAUDE_PATH,
            "describe this as manual compliance + verifier-checked contract drift, not native pre-execution blocking or behavioral parity.",
            "Codex manual-compliance boundary rule",
        ),
        (
            CLAUDE_PATH,
            "apply the same test-first rule for edits to existing implementation files when related tests are detectable,",
            "Codex test-first mirror rule",
        ),
        (
            CLAUDE_PATH,
            "treat post-edit inspection as mandatory review work for debug leftovers and credential leaks,",
            "Codex post-edit mirror rule",
        ),
        (
            AGENTS_PATH,
            SELF_RECOGNITION_SNIPPET,
            "Codex self-recognition contract rule",
        ),
        (
            AGENTS_PATH,
            "[Claude] `SessionStart` loads startup context (`tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, latest session snapshot when present); treat that context as authoritative, then read more only when the task requires it. [Codex] Read the same startup files manually before acting.",
            "Codex AGENTS SessionStart hook-clarification rule",
        ),
        (
            AGENTS_PATH,
            "[Claude] `PreCompact` creates a handoff skeleton before context reduction; review and complete it before compacting. This is advisory; the hook does not block compaction. [Codex] Before invoking compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract.",
            "Codex AGENTS PreCompact hook-clarification rule",
        ),
        (
            AGENTS_PATH,
            "[Claude] `SessionEnd` saves the latest session snapshot for continuity. This preserves state, not proof of completion. [Codex] At session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.",
            "Codex AGENTS SessionEnd hook-clarification rule",
        ),
        (
            AGENTS_PATH,
            "3+ step task with concrete scope and no meaningful design fork → `writing-plans` → `executor-agent` → `verification`",
            "Codex clear-scope complex workflow rule",
        ),
        (
            AGENTS_PATH,
            "`SessionStart` loads startup context (`tasks/plan.md`, `tasks/lessons.md`, `docs/memory-map.md`, latest session snapshot when present);",
            "Codex SessionStart startup context contract",
        ),
        (
            AGENTS_PATH,
            "9. `docs/operations/codex-runtime.md` when task flow, generated instructions, or memory behavior matters",
            "Codex runtime required read",
        ),
        (
            AGENTS_PATH,
            "10. `docs/operations/hook-contract.md` when hook behavior, enforcement boundaries, or Codex parity matters",
            "Codex hook-contract required read",
        ),
        (
            AGENTS_PATH,
            "11. `docs/operations/harness-application.md` when applying harness techniques across Claude and Codex",
            "Codex harness-application required read",
        ),
        (
            AGENTS_PATH,
            "12. `docs/operations/starter-maintenance-mode.md` when the task modifies starter contracts, verifiers, or cross-harness behavior",
            "Codex starter-maintenance-mode required read",
        ),
        (
            AGENTS_PATH,
            CUSTOM_HARNESS_RULES_HEADING,
            "Codex custom harness rules section",
        ),
        (
            AGENTS_PATH,
            "## Mode Classification",
            "Codex mode classification section",
        ),
        (
            AGENTS_PATH,
            "- Read the startup context files required by the SessionStart mirror rule before acting.",
            "Codex startup summary rule",
        ),
        (
            AGENTS_PATH,
            "- Skills: `brainstorming, code-review, deep-interview, git-commit, project-doctor, self-audit, testing, ux-ui-design, verification, writing-plans`",
            "Codex startup skill list includes self-audit",
        ),
        (
            AGENTS_PATH,
            "Starter contract / verifier / generated-artifact work → enter Starter Maintenance Mode",
            "Codex starter mode classification rule",
        ),
        (
            AGENTS_PATH,
            "Claude/Codex boundary or mirroring change → enter Cross-Harness Parity Mode",
            "Codex cross-harness parity mode classification rule",
        ),
        (
            AGENTS_PATH,
            f"name the same blocked-intent set in instruction form: {BLOCKED_INTENT_SNIPPET},",
            "Codex blocked-intent mirror rule in generated instructions",
        ),
        (
            AGENTS_PATH,
            CODEX_INCIDENT_LIMITATION_SNIPPET,
            "Codex incidents limitation rule in generated instructions",
        ),
        (
            AGENTS_PATH,
            "apply the same test-first rule for edits to existing implementation files when related tests are detectable,",
            "Codex test-first mirror rule in generated instructions",
        ),
        (
            AGENTS_PATH,
            "treat post-edit inspection as mandatory review work for debug leftovers and credential leaks,",
            "Codex post-edit mirror rule in generated instructions",
        ),
        (
            AGENTS_PATH,
            "describe this as manual compliance + verifier-checked contract drift, not native pre-execution blocking or behavioral parity.",
            "Codex manual-compliance boundary rule in generated instructions",
        ),
        (
            SYNC_README_PATH,
            "python3 scripts/verify_codex_sync.py",
            ".codex-sync README verification command",
        ),
        (
            README_PATH,
            README_SELF_RECOGNITION_SNIPPET,
            "README self-recognition summary rule",
        ),
        (
            README_KO_PATH,
            README_KO_SELF_RECOGNITION_SNIPPET,
            "README.ko self-recognition summary rule",
        ),
        (
            HARNESS_README_PATH,
            "`scripts/verify_codex_sync.py` checks `.codex-sync/manifest.json`, generated target coverage, generated-file markers, active-profile skill-set drift, startup-state parity, blocked-intent mirror coverage, mode-classification coverage, generated-section coverage, config fallback policy, and dead-reference regressions.",
            "harness README Codex sync verification description",
        ),
        (
            SYNC_README_PATH,
            "The verifier checks manifest coverage, generated target coverage, generated-file markers, active-profile skill-set drift, startup-state parity, blocked-intent mirror coverage, mode-classification coverage, generated-section coverage, config fallback policy, and dead-reference regressions across generator, docs, and generated files.",
            ".codex-sync README Codex sync verification description",
        ),
        (
            ROOT / "docs" / "operations" / "claude-runtime.md",
            "Before acting, identify runtime=`Claude`, the active mode, the hook-backed enforcement path, and the required completion gates from the startup docs.",
            "Claude runtime self-recognition startup rule",
        ),
        (
            ROOT / "docs" / "operations" / "claude-runtime.md",
            STARTUP_SNIPPET,
            "Claude runtime startup snapshot rule",
        ),
        (
            ROOT / "docs" / "operations" / "claude-runtime.md",
            BLOCKED_INTENT_SNIPPET,
            "Claude runtime concrete PreToolUse rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "Mirror agent-level tool restrictions in generated Codex agent instructions even when sandboxing already provides a stronger guard.",
            "Codex runtime agent-tool-restriction mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "Before compaction, manually create a handoff document in `tasks/handoffs/` mirroring the PreCompact contract.",
            "Codex runtime PreCompact mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "Before acting, identify runtime=`Codex`, the active mode, the instruction-backed enforcement path, and the verifier-backed completion gates from `AGENTS.md` and runtime docs.",
            "Codex runtime self-recognition startup rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            STARTUP_SNIPPET,
            "Codex runtime startup snapshot rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            BLOCKED_INTENT_SNIPPET,
            "Codex runtime blocked-intent rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "Do not claim hook-driven incident counting for Codex-only sessions unless the active Codex workflow explicitly records incidents.",
            "Codex runtime incidents limitation rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "In Codex-only sessions, `harness/state/incidents.json` remains Claude-hook state rather than a Codex parity guarantee.",
            "Codex runtime incidents state limitation rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            "At session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.",
            "Codex runtime SessionEnd mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "codex-runtime.md",
            MANUAL_COMPLIANCE_SNIPPET,
            "Codex runtime manual-compliance boundary rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            STARTUP_SNIPPET,
            "hook-contract startup snapshot rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            BLOCKED_INTENT_SNIPPET,
            "hook-contract blocked-intent mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            CODEX_INCIDENT_LIMITATION_SNIPPET,
            "hook-contract Codex incidents limitation rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            PRECOMPACT_MIRROR_SNIPPET,
            "hook-contract PreCompact mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            "at session end, manually create a session snapshot in `tasks/sessions/` mirroring the SessionEnd contract.",
            "hook-contract SessionEnd mirror rule",
        ),
        (
            ROOT / "docs" / "operations" / "hook-contract.md",
            "This mirror is instruction-backed, and selected contract snippets plus generated outputs are verifier-checked. It is not native pre-execution blocking or behavioral parity.",
            "hook-contract manual-compliance boundary rule",
        ),
        (
            ROOT / "docs" / "operations" / "harness-application.md",
            SELF_RECOGNITION_SNIPPET,
            "harness-application self-recognition contract rule",
        ),
        (
            ROOT / "docs" / "operations" / "harness-application.md",
            BLOCKED_INTENT_SNIPPET,
            "harness-application blocked-intent parity rule",
        ),
        (
            ROOT / "docs" / "operations" / "harness-application.md",
            "Continuity parity must cover handoff creation before compaction and session snapshots even when Codex performs them manually rather than through hooks.",
            "harness-application continuity parity rule",
        ),
        (
            ROOT / "docs" / "operations" / "harness-application.md",
            "Do not claim hook-driven repeated-incident stopping for Codex-only sessions unless a Codex workflow explicitly records incidents into shared state.",
            "harness-application incidents limitation rule",
        ),
        (
            ROOT / "docs" / "operations" / "harness-application.md",
            MANUAL_COMPLIANCE_SNIPPET,
            "harness-application manual-compliance boundary rule",
        ),
        (
            ROOT / "docs" / "operations" / "starter-maintenance-mode.md",
            "startup-state mirroring rules",
            "starter-maintenance-mode startup-state parity classification",
        ),
        (
            ROOT / "docs" / "operations" / "starter-maintenance-mode.md",
            "blocked-intent mirroring rules",
            "starter-maintenance-mode blocked-intent parity classification",
        ),
        (
            ROOT / "docs" / "operations" / "starter-maintenance-mode.md",
            "startup-state rules and blocked-intent rules concrete enough for verifier coverage.",
            "starter-maintenance-mode verifier-friendly parity rule",
        ),
        (
            CLAUDE_PATH,
            "`PreCompact` creates a handoff skeleton before context reduction; review and complete it before compacting.",
            "CLAUDE PreCompact mirror rule",
        ),
        (
            CLAUDE_PATH,
            "`SessionEnd` saves the latest session snapshot for continuity.",
            "CLAUDE SessionEnd mirror rule",
        ),
        (
            AGENTS_PATH,
            "`PreCompact` creates a handoff skeleton before context reduction; review and complete it before compacting.",
            "Codex PreCompact mirror rule in generated instructions",
        ),
        (
            AGENTS_PATH,
            "`SessionEnd` saves the latest session snapshot for continuity.",
            "Codex SessionEnd mirror rule in generated instructions",
        ),
    ]

    for path, snippet, label in required_snippets:
        ensure_contains(path, snippet, label, messages)

    ensure_contains(
        CODEX_CONFIG_PATH,
        'project_doc_fallback_filenames = ["AGENTS.md"]',
        "Codex config project-doc fallback policy",
        messages,
    )
    ensure_contains(
        ROOT / ".codex" / "agents" / "quality-agent.toml",
        'sandbox_mode = "read-only"',
        "Codex quality-agent read-only sandbox",
        messages,
    )
    ensure_contains(
        ROOT / ".codex" / "agents" / "main-orchestrator.toml",
        "Use `AGENTS.md` as the shared runtime contract for startup, workflow, mode classification, hook mirrors, and shared policy.",
        "generated agent AGENTS runtime-contract pointer",
        messages,
    )
    ensure_contains(
        ROOT / ".codex" / "agents" / "quality-agent.toml",
        "Do not use these tools in this generated Codex mirror: Write, Edit.",
        "generated quality-agent disallowed-tools mirror",
        messages,
    )
    ensure_contains(
        GENERATOR_PATH,
        '"## Custom Harness Rules"',
        "generator emits custom harness rules section",
        messages,
    )
    ensure_contains(
        GENERATOR_PATH,
        'echo "- Read the startup context files required by the SessionStart mirror rule before acting."',
        "generator emits Codex startup summary rule",
        messages,
    )
    ensure_contains(
        GENERATOR_PATH,
        "emit_codex_agent_skill_hook_contract CLAUDE.md",
        "generator emits Codex-specific hook contract transform",
        messages,
    )
    ensure_contains(
        GENERATOR_PATH,
        "emit_codex_required_reads CLAUDE.md",
        "generator emits Codex-specific required-reads transform",
        messages,
    )

    disallowed_snippets = [
        (ROOT / ".claude" / "agents" / "main-orchestrator.md", 'See CLAUDE.md "Orchestration Presets" table', "dead orchestration presets reference"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", 'See CLAUDE.md "Orchestration Presets" table', "generated dead orchestration presets reference"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", "auto-injected by hook", "false Codex auto-injected-by-hook claim"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", "## Required Reads", "generated agent duplicated shared runtime block"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", "## Startup Protocol", "generated main-orchestrator duplicated startup protocol"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", "## Starter Maintenance Protocol", "generated main-orchestrator duplicated starter-maintenance protocol"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", "## Shared Principles", "generated main-orchestrator duplicated shared principles"),
        (ROOT / ".codex" / "agents" / "executor-agent.toml", "## Starter Maintenance Rules", "generated executor-agent duplicated starter-maintenance rules"),
        (ROOT / ".codex" / "agents" / "executor-agent.toml", "## Shared Principles", "generated executor-agent duplicated shared principles"),
        (ROOT / ".codex" / "agents" / "quality-agent.toml", "## Shared Principles", "generated quality-agent duplicated shared principles"),
        (CODEX_CONFIG_PATH, 'model_reasoning_effort = "', "generated Codex config unexpected reasoning-effort pin"),
        (ROOT / ".codex" / "agents" / "main-orchestrator.toml", 'model_reasoning_effort = "', "generated main-orchestrator unexpected reasoning-effort pin"),
        (ROOT / ".codex" / "agents" / "executor-agent.toml", 'model_reasoning_effort = "', "generated executor-agent unexpected reasoning-effort pin"),
        (ROOT / ".codex" / "agents" / "quality-agent.toml", 'model_reasoning_effort = "', "generated quality-agent unexpected reasoning-effort pin"),
        (AGENTS_PATH, "9. `docs/operations/claude-runtime.md` when task flow, hooks, or memory behavior matters", "generated AGENTS false Claude runtime required read"),
    ]
    for path, snippet, label in disallowed_snippets:
        ensure_not_contains(path, snippet, label, messages)

    check_approval_policy_mapping(messages)
    compare_generated_outputs(messages)

    if not messages:
        messages.append("OK: selected runtime docs, generated docs, and verifier-owned contract snippets are synchronized")
    return messages


def run() -> int:
    messages: List[str] = []

    if not MANIFEST_PATH.exists():
        print(f"FAIL: missing manifest: {MANIFEST_PATH.relative_to(ROOT)}")
        return 1

    manifest = json.loads(read_text(MANIFEST_PATH))
    mappings = manifest.get("mappings", [])
    if not mappings:
        print("FAIL: manifest has no mappings")
        return 1

    required_keys = {"source", "targets", "change_scope", "sync_policy", "owner", "notes"}
    for index, mapping in enumerate(mappings, start=1):
        missing = required_keys - set(mapping)
        if missing:
            messages.append(f"FAIL: manifest mapping #{index} missing keys: {sorted(missing)}")
            continue

        for source_path in parse_manifest_sources(mapping["source"]):
            if not source_path.exists():
                messages.append(f"FAIL: manifest source missing: {source_path.relative_to(ROOT)}")

        for target in mapping["targets"]:
            target_path = ROOT / target
            if not target_path.exists():
                messages.append(f"FAIL: manifest target missing: {target}")
                continue
            if target_path.is_file() and not has_generated_marker(target_path):
                messages.append(f"FAIL: generated marker missing from target: {target}")

    mapped = mapped_targets(manifest)
    actual = actual_generated_targets()
    missing_from_manifest = sorted(actual - mapped)
    extra_in_manifest = sorted(mapped - actual)
    if missing_from_manifest:
        messages.append(f"FAIL: generated targets missing from manifest: {missing_from_manifest}")
    if extra_in_manifest:
        messages.append(f"FAIL: manifest targets missing on disk: {extra_in_manifest}")

    active_profile, active_skills = detect_active_profile()
    generator_text = read_text(GENERATOR_PATH)
    core_skills = set(parse_core_skills_from_generator(generator_text))
    claude_skills = set(parse_core_skills_from_claude(read_text(CLAUDE_PATH)))
    agents_skills = set(parse_codex_skills_from_agents(read_text(AGENTS_PATH)))
    sync_readme_skills = parse_skill_names_from_sync_readme(read_text(SYNC_README_PATH))
    manifest_skill_targets = {
        Path(target).parts[-2]
        for target in mapped
        if target.startswith(".agents/skills/")
    }

    # CLAUDE.md "Core default" line always describes the core profile, regardless of active profile.
    if claude_skills != core_skills:
        messages.append(
            f"FAIL: CLAUDE core defaults drifted from generator core skill set. expected={sorted(core_skills)} observed={sorted(claude_skills)}"
        )

    # The generated and checked-in artifacts must match the active profile.
    active_comparisons = [
        ("AGENTS skill list", agents_skills),
        (".codex-sync README checked-in pack", sync_readme_skills),
        ("manifest skill targets", manifest_skill_targets),
    ]
    for label, observed in active_comparisons:
        if observed != active_skills:
            messages.append(
                f"FAIL: {label} drifted from generator {active_profile} skill set. expected={sorted(active_skills)} observed={sorted(observed)}"
            )

    if not messages:
        messages.append("OK: manifest sources, targets, and generated markers are valid")
        messages.append("OK: manifest coverage matches generated Codex targets")
        messages.append("OK: core skill sets are synchronized across generator, docs, and manifest")

    messages.extend(validate_runtime_doc_contracts())

    for message in messages:
        print(message)

    return 1 if any(message.startswith("FAIL:") for message in messages) else 0


if __name__ == "__main__":
    sys.exit(run())
