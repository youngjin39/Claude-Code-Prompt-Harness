"""Unit tests for scripts/verify_starter_integrity.py.

Standalone runner: `python3 tests/test_verify_starter_integrity.py`
"""

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import verify_starter_integrity as vsi


def test_check_pre_tool_use_contract_passes():
    failures = vsi.check_pre_tool_use_contract()
    assert failures == [], f"hook missing required snippets: {failures}"


def test_check_pre_tool_use_contract_detects_missing():
    original = vsi.PRE_TOOL_USE_PATH
    empty = ROOT / "tests" / "_empty_hook_fixture.sh"
    try:
        empty.write_text("#!/bin/bash\nexit 0\n", encoding="utf-8")
        vsi.PRE_TOOL_USE_PATH = empty
        failures = vsi.check_pre_tool_use_contract()
        assert failures, "verifier must report failures on empty hook"
        labels = " ".join(failures)
        assert "piped remote install guard" in labels
        assert "secret file guard" in labels
        assert "git internals guard" in labels
    finally:
        vsi.PRE_TOOL_USE_PATH = original
        if empty.exists():
            empty.unlink()


def test_check_plan_size_within_cap():
    failures = vsi.check_plan_size()
    assert failures == [], f"plan.md exceeds 50-line compact cap: {failures}"


def test_pre_tool_use_allows_only_home_claude_memory_namespace():
    project = str(ROOT)
    allowed = str(Path.home() / ".claude" / "projects" / "demo" / "memory" / "note.md")
    blocked = "/tmp/.claude/projects/demo/memory/note.md"

    def run_hook(path: str) -> subprocess.CompletedProcess[str]:
        payload = f'{{"tool_name":"Edit","tool_input":{{"file_path":"{path}"}}}}'
        return subprocess.run(
            ["bash", str(vsi.PRE_TOOL_USE_PATH)],
            input=payload,
            cwd=ROOT,
            env={**os.environ, "CLAUDE_PROJECT_DIR": project},
            capture_output=True,
            text=True,
        )

    allowed_result = run_hook(allowed)
    blocked_result = run_hook(blocked)

    assert allowed_result.returncode == 0, allowed_result.stderr
    assert blocked_result.returncode == 2, blocked_result.stderr
    assert "Write outside project root" in blocked_result.stderr


def main() -> int:
    tests = [
        test_check_pre_tool_use_contract_passes,
        test_check_pre_tool_use_contract_detects_missing,
        test_check_plan_size_within_cap,
        test_pre_tool_use_allows_only_home_claude_memory_namespace,
    ]
    failed = 0
    for test in tests:
        try:
            test()
            print(f"PASS: {test.__name__}")
        except AssertionError as exc:
            failed += 1
            print(f"FAIL: {test.__name__}: {exc}")
    print(f"{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
