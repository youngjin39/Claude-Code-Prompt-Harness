"""Unit tests for scripts/verify_codex_sync.py.

Standalone runner: `python3 tests/test_verify_codex_sync.py`
"""

import io
import json
import shutil
import tempfile
import sys
from contextlib import redirect_stdout
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

import verify_codex_sync as vcs


def test_run_passes_on_current_state():
    buf = io.StringIO()
    with redirect_stdout(buf):
        exit_code = vcs.run()
    assert exit_code == 0, f"verifier failed: {buf.getvalue()}"


def test_parse_core_skills_from_generator_returns_known_set():
    skills = vcs.parse_core_skills_from_generator(vcs.read_text(vcs.GENERATOR_PATH))
    assert "brainstorming" in skills
    assert "verification" in skills
    assert "writing-plans" in skills


def test_detect_active_profile_matches_manifest_skill_targets():
    profile, skills = vcs.detect_active_profile()
    manifest = json.loads(vcs.read_text(vcs.MANIFEST_PATH))
    manifest_skill_targets = {
        Path(target).parts[-2]
        for target in vcs.mapped_targets(manifest)
        if target.startswith(".agents/skills/")
    }
    assert profile in {"core", "full"}
    assert manifest_skill_targets == skills


def test_compare_generated_outputs_uses_active_profile():
    profile, _ = vcs.detect_active_profile()
    original_run = vcs.subprocess.run
    original_targets = vcs.actual_generated_targets
    captured = {}

    def fake_run(cmd, cwd, env, capture_output, text):
        captured["profile"] = env.get("CODEX_DERIVATION_PROFILE")
        out_root = Path(env["CODEX_DERIVATION_OUTPUT_ROOT"])
        (out_root / ".codex-sync").mkdir(parents=True, exist_ok=True)
        shutil.copy2(vcs.MANIFEST_PATH, out_root / ".codex-sync" / "manifest.json")

        class Result:
            returncode = 0
            stdout = ""
            stderr = ""

        return Result()

    vcs.subprocess.run = fake_run
    vcs.actual_generated_targets = lambda: set()
    try:
        messages = []
        vcs.compare_generated_outputs(messages)
    finally:
        vcs.subprocess.run = original_run
        vcs.actual_generated_targets = original_targets

    assert captured["profile"] == profile
    assert messages == [], messages


def main() -> int:
    tests = [
        test_run_passes_on_current_state,
        test_parse_core_skills_from_generator_returns_known_set,
        test_detect_active_profile_matches_manifest_skill_targets,
        test_compare_generated_outputs_uses_active_profile,
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
