#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple


ROOT = Path(__file__).resolve().parent
STATE_DIR = ROOT / "harness" / "state"
CURRENT_TASK = STATE_DIR / "current-task.json"
HISTORY_LOG = STATE_DIR / "history.jsonl"
INCIDENTS = STATE_DIR / "incidents.json"
CHANGE_LOG = ROOT / "tasks" / "change_log.md"
SKIP_DIRS = {
    ".git",
    ".codex",
    ".codex-sync",
    ".agents",
    ".claude",
    "node_modules",
    "dist",
    "build",
    "coverage",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".next",
    ".turbo",
}
SOURCE_EXTENSIONS = {
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".py",
    ".go",
    ".rs",
    ".rb",
    ".java",
    ".kt",
    ".swift",
    ".php",
    ".c",
    ".cc",
    ".cpp",
    ".h",
    ".hpp",
    ".cs",
}
CONFIG_BASENAMES = {
    "setup.py",
    "manage.py",
    "conftest.py",
}
COMMIT_POLICIES = {"manual", "never", "checkpoint", "complete", "always"}
PHASE_PRESETS: Dict[str, Dict[str, Any]] = {
    "discovery": {
        "phase": "discovery",
        "description": "Read, diagnose, and gather evidence before edits.",
        "commit_policy": "never",
        "rollback_scope": "none",
    },
    "planning": {
        "phase": "planning",
        "description": "Define concrete implementation steps before execution.",
        "commit_policy": "manual",
        "rollback_scope": "metadata",
    },
    "implementation": {
        "phase": "implementation",
        "description": "Make code changes with checkpoint-level commits.",
        "commit_policy": "checkpoint",
        "rollback_scope": "git-head",
    },
    "verification": {
        "phase": "verification",
        "description": "Validate behavior and capture evidence without auto-commit.",
        "commit_policy": "manual",
        "rollback_scope": "metadata",
    },
    "release": {
        "phase": "release",
        "description": "Finalize delivery with a completion commit.",
        "commit_policy": "complete",
        "rollback_scope": "git-head",
    },
}


def now_iso() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def ensure_state_dir() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    return json.loads(path.read_text())


def save_json(path: Path, data: Any) -> None:
    ensure_state_dir()
    path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n")


def append_history(event: Dict[str, Any]) -> None:
    ensure_state_dir()
    with HISTORY_LOG.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=True) + "\n")


def load_current_task() -> Dict[str, Any]:
    return load_json(CURRENT_TASK, {})


def save_current_task(task: Dict[str, Any]) -> None:
    save_json(CURRENT_TASK, task)


def git_available() -> bool:
    return (ROOT / ".git").exists()


def git_head() -> Optional[str]:
    if not git_available():
        return None
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def git_dirty_files() -> List[str]:
    if not git_available():
        return []
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return []
    files: List[str] = []
    for line in result.stdout.splitlines():
        if len(line) < 4:
            continue
        files.append(line[3:])
    return sorted(dict.fromkeys(files))


def normalize_files(files: List[str]) -> List[str]:
    normalized = []
    for item in files:
        try:
            normalized.append(str(Path(item).resolve().relative_to(ROOT)))
        except ValueError:
            normalized.append(item)
    return sorted(dict.fromkeys(normalized))


def append_change_log(change: str, reason: str, files: List[str]) -> None:
    if not CHANGE_LOG.exists():
        return
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    file_label = ", ".join(files) if files else "(none)"
    row = f"| {stamp} | {file_label} | {change} | {reason} |\n"
    with CHANGE_LOG.open("a", encoding="utf-8") as handle:
        handle.write(row)


def git_dirty() -> bool:
    return bool(git_dirty_files())


def git_commit(message: str) -> Dict[str, Any]:
    if not git_available():
        return {"committed": False, "reason": "no-git-repo"}
    if not git_dirty():
        return {"committed": False, "reason": "clean-worktree"}
    before_head = git_head()
    add_result = subprocess.run(
        ["git", "add", "-A"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if add_result.returncode != 0:
        return {"committed": False, "reason": add_result.stderr.strip() or "git add failed"}
    commit_result = subprocess.run(
        ["git", "commit", "-m", message],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    after_head = git_head()
    return {
        "committed": commit_result.returncode == 0,
        "reason": commit_result.stderr.strip() or commit_result.stdout.strip(),
        "head_before": before_head,
        "head_after": after_head,
        "message": message,
    }


def resolve_phase_preset(name: Optional[str]) -> Dict[str, Any]:
    if not name:
        return {}
    return dict(PHASE_PRESETS.get(name, {}))


def resolve_phase_and_preset(
    phase: str, preset_name: Optional[str]
) -> Tuple[str, Dict[str, Any], Optional[str]]:
    if preset_name:
        preset = resolve_phase_preset(preset_name)
        if not preset:
            raise ValueError(f"Unknown preset: {preset_name}")
        return preset.get("phase", phase), preset, preset_name
    preset = resolve_phase_preset(phase)
    if preset:
        return preset.get("phase", phase), preset, phase
    return phase, {}, None


def default_commit_policy(phase: str, preset: Dict[str, Any]) -> str:
    policy = preset.get("commit_policy")
    if policy in COMMIT_POLICIES:
        return policy
    return "manual"


def resolve_commit_policy(current_task: Dict[str, Any], args: argparse.Namespace) -> str:
    policy = getattr(args, "commit_policy", None) or current_task.get("commit_policy") or "manual"
    if policy not in COMMIT_POLICIES:
        raise ValueError(f"Unsupported commit policy: {policy}")
    return policy


def should_auto_commit(policy: str, action: str) -> bool:
    if policy in {"manual", "never"}:
        return False
    if policy == "always":
        return action in {"checkpoint", "complete", "fail"}
    return policy == action


def capture_rollback_metadata(task: Dict[str, Any], rollback_scope: str) -> Dict[str, Any]:
    base_files = normalize_files(task.get("files", []))
    metadata = {
        "scope": rollback_scope,
        "git_available": git_available(),
        "base_head": git_head(),
        "base_dirty_files": git_dirty_files(),
        "tracked_files": base_files,
        "created_commits": [],
        "last_commit": None,
    }
    metadata["strategy"] = "git-reset-to-base-head" if metadata["base_head"] else "file-level-manual-restore"
    return metadata


def update_rollback_metadata(task: Dict[str, Any], git_result: Optional[Dict[str, Any]] = None) -> None:
    rollback = task.setdefault("rollback", {})
    rollback["tracked_files"] = normalize_files(task.get("files", []))
    rollback["workspace_dirty_files"] = git_dirty_files()
    rollback["current_head"] = git_head()
    if git_result and git_result.get("committed"):
        record = {
            "message": git_result.get("message"),
            "head_before": git_result.get("head_before"),
            "head_after": git_result.get("head_after"),
            "time": now_iso(),
        }
        rollback["last_commit"] = record
        commits = rollback.setdefault("created_commits", [])
        commits.append(record)


def maybe_commit(
    task: Dict[str, Any], args: argparse.Namespace, action: str, message: str
) -> Optional[Dict[str, Any]]:
    if getattr(args, "no_commit", False):
        return {"committed": False, "reason": "no-commit-flag"}
    if getattr(args, "commit", False):
        git_result = git_commit(message)
        update_rollback_metadata(task, git_result)
        return git_result

    policy = resolve_commit_policy(task, args)
    if not should_auto_commit(policy, action):
        update_rollback_metadata(task)
        return None

    git_result = git_commit(message)
    update_rollback_metadata(task, git_result)
    return git_result


def rollback_report(task: Dict[str, Any]) -> Dict[str, Any]:
    rollback = dict(task.get("rollback") or {})
    if not rollback:
        return {"available": False}
    warnings: List[str] = []
    if rollback.get("base_dirty_files"):
        warnings.append("workspace was already dirty at task start")
    if rollback.get("workspace_dirty_files"):
        warnings.append("workspace is currently dirty")
    return {
        "available": True,
        "task_id": task.get("task_id"),
        "status": task.get("status"),
        "phase": task.get("phase"),
        "rollback": rollback,
        "suggested_target": rollback.get("base_head"),
        "warnings": warnings,
    }


def command_start(args: argparse.Namespace) -> int:
    task = load_current_task()
    started = now_iso()
    phase, preset, preset_name = resolve_phase_and_preset(args.phase, args.preset)
    commit_policy = args.commit_policy or default_commit_policy(phase, preset)
    rollback_scope = args.rollback_scope or preset.get("rollback_scope", "metadata")
    task.update(
        {
            "task_id": task.get("task_id") or f"task-{datetime.now().strftime('%Y%m%d-%H%M%S')}",
            "phase": phase,
            "phase_preset": preset_name,
            "goal": args.goal,
            "status": "in_progress",
            "started_at": task.get("started_at") or started,
            "updated_at": started,
            "notes": args.notes or "",
            "commit_policy": commit_policy,
            "files": normalize_files(args.files),
            "checkpoints": task.get("checkpoints", []),
        }
    )
    task["rollback"] = capture_rollback_metadata(task, rollback_scope)
    save_current_task(task)
    append_history(
        {
            "time": started,
            "event": "start",
            "phase": phase,
            "goal": args.goal,
            "preset": preset_name,
            "commit_policy": commit_policy,
        }
    )
    append_change_log(f"start phase `{phase}`", args.goal, task["files"])
    print(json.dumps(task, indent=2))
    return 0


def command_checkpoint(args: argparse.Namespace) -> int:
    task = load_current_task()
    if not task:
        print("No active task. Run `execute.py start ...` first.", file=sys.stderr)
        return 1
    timestamp = now_iso()
    checkpoint = {
        "time": timestamp,
        "message": args.message,
        "phase": args.phase or task.get("phase"),
        "files": normalize_files(args.files),
    }
    task.setdefault("checkpoints", []).append(checkpoint)
    task["updated_at"] = timestamp
    if checkpoint["files"]:
        combined = set(task.get("files", []))
        combined.update(checkpoint["files"])
        task["files"] = sorted(combined)
    save_current_task(task)
    append_history({"time": timestamp, "event": "checkpoint", **checkpoint})
    append_change_log(f"checkpoint `{checkpoint['phase']}`", args.message, checkpoint["files"])
    result = {"task": task, "checkpoint": checkpoint}
    git_result = maybe_commit(
        task,
        args,
        "checkpoint",
        f"chore(harness): checkpoint {checkpoint['phase']} - {args.message}",
    )
    save_current_task(task)
    if git_result is not None:
        result["git"] = git_result
    print(json.dumps(result, indent=2))
    return 0


def command_complete(args: argparse.Namespace) -> int:
    task = load_current_task()
    if not task:
        print("No active task.", file=sys.stderr)
        return 1
    timestamp = now_iso()
    phase = args.phase or task.get("phase")
    task["status"] = "completed"
    task["phase"] = phase
    task["summary"] = args.summary
    task["completed_at"] = timestamp
    task["updated_at"] = timestamp
    append_history({"time": timestamp, "event": "complete", "phase": phase, "summary": args.summary})
    append_change_log(f"complete phase `{phase}`", args.summary, normalize_files(args.files))
    result = {"task": task}
    git_result = maybe_commit(
        task,
        args,
        "complete",
        f"chore(harness): complete {phase} - {args.summary}",
    )
    save_current_task(task)
    if git_result is not None:
        result["git"] = git_result
    print(json.dumps(result, indent=2))
    return 0


def command_fail(args: argparse.Namespace) -> int:
    task = load_current_task()
    if not task:
        print("No active task.", file=sys.stderr)
        return 1
    timestamp = now_iso()
    phase = args.phase or task.get("phase")
    task["status"] = "failed"
    task["phase"] = phase
    task["failure_reason"] = args.reason
    task["updated_at"] = timestamp
    append_history({"time": timestamp, "event": "fail", "phase": phase, "reason": args.reason})
    append_change_log(f"fail phase `{phase}`", args.reason, normalize_files(args.files))
    result = {"task": task}
    git_result = maybe_commit(
        task,
        args,
        "fail",
        f"chore(harness): fail {phase} - {args.reason}",
    )
    save_current_task(task)
    if git_result is not None:
        result["git"] = git_result
    print(json.dumps(result, indent=2))
    return 0


def command_status(_: argparse.Namespace) -> int:
    task = load_current_task()
    if not task:
        print("{}")
        return 0
    print(json.dumps(task, indent=2))
    return 0


def command_presets(_: argparse.Namespace) -> int:
    print(json.dumps(PHASE_PRESETS, indent=2))
    return 0


def command_rollback_metadata(_: argparse.Namespace) -> int:
    task = load_current_task()
    if not task:
        print(json.dumps({"available": False}, indent=2))
        return 0
    print(json.dumps(rollback_report(task), indent=2))
    return 0


def scan_files() -> List[Path]:
    files: List[Path] = []
    for root, dirs, filenames in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        root_path = Path(root)
        for name in filenames:
            files.append(root_path / name)
    return files


def is_test_file(path: Path) -> bool:
    rel_parts = set(path.parts)
    if {"tests", "__tests__", "spec"} & rel_parts:
        return True
    name = path.name.lower()
    return any(
        token in name
        for token in (".test.", ".spec.", "_test.", "_spec.", "test_", "spec_")
    )


def is_source_file(path: Path) -> bool:
    if path.suffix not in SOURCE_EXTENSIONS:
        return False
    if path.name in CONFIG_BASENAMES:
        return False
    if ".config." in path.name or path.name.endswith(".d.ts"):
        return False
    if is_test_file(path):
        return False
    if any(part in {"docs", "tasks", "harness"} for part in path.parts):
        return False
    return True


def related_test_matches(target: Path) -> List[str]:
    if not target.exists() or not is_source_file(target):
        return []
    stem = target.stem
    ext = target.suffix
    candidate_names = {
        f"{stem}.test{ext}",
        f"{stem}.spec{ext}",
        f"{stem}_test{ext}",
        f"test_{stem}{ext}",
    }
    if ext == ".go":
        candidate_names.add(f"{stem}_test.go")
    matches: List[str] = []
    for file_path in scan_files():
        if file_path == target:
            continue
        if not is_test_file(file_path):
            continue
        if file_path.name in candidate_names:
            try:
                matches.append(str(file_path.relative_to(ROOT)))
            except ValueError:
                matches.append(str(file_path))
    return sorted(dict.fromkeys(matches))


def command_related_tests(args: argparse.Namespace) -> int:
    target = (ROOT / args.path).resolve() if not Path(args.path).is_absolute() else Path(args.path)
    response = {
        "path": str(target),
        "exists": target.exists(),
        "source_file": is_source_file(target),
        "matches": related_test_matches(target),
    }
    response["count"] = len(response["matches"])
    print(json.dumps(response, indent=2))
    return 0


def command_record_incident(args: argparse.Namespace) -> int:
    state = load_json(INCIDENTS, {"events": []})
    current = datetime.now(timezone.utc)
    cutoff = current - timedelta(seconds=args.window_seconds)
    events = []
    for event in state.get("events", []):
        try:
            event_time = datetime.fromisoformat(event["time"])
        except Exception:
            continue
        if event_time >= cutoff:
            events.append(event)
    event = {
        "time": current.isoformat(timespec="seconds"),
        "source": args.source,
        "key": args.key,
        "message": args.message or "",
    }
    events.append(event)
    state["events"] = events
    save_json(INCIDENTS, state)
    count = sum(1 for item in events if item["source"] == args.source and item["key"] == args.key)
    result = {
        "count": count,
        "threshold": args.threshold,
        "window_seconds": args.window_seconds,
        "tripped": count >= args.threshold,
    }
    print(json.dumps(result))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Harness state manager")
    subparsers = parser.add_subparsers(dest="command", required=True)

    start = subparsers.add_parser("start")
    start.add_argument("phase")
    start.add_argument("goal")
    start.add_argument("--preset")
    start.add_argument("--commit-policy", choices=sorted(COMMIT_POLICIES))
    start.add_argument("--rollback-scope", choices=["none", "metadata", "git-head"])
    start.add_argument("--notes")
    start.add_argument("--files", nargs="*", default=[])
    start.set_defaults(func=command_start)

    checkpoint = subparsers.add_parser("checkpoint")
    checkpoint.add_argument("message")
    checkpoint.add_argument("--phase")
    checkpoint.add_argument("--files", nargs="*", default=[])
    checkpoint.add_argument("--commit", action="store_true")
    checkpoint.add_argument("--no-commit", action="store_true")
    checkpoint.add_argument("--commit-policy", choices=sorted(COMMIT_POLICIES))
    checkpoint.set_defaults(func=command_checkpoint)

    complete = subparsers.add_parser("complete")
    complete.add_argument("summary")
    complete.add_argument("--phase")
    complete.add_argument("--files", nargs="*", default=[])
    complete.add_argument("--commit", action="store_true")
    complete.add_argument("--no-commit", action="store_true")
    complete.add_argument("--commit-policy", choices=sorted(COMMIT_POLICIES))
    complete.set_defaults(func=command_complete)

    fail = subparsers.add_parser("fail")
    fail.add_argument("reason")
    fail.add_argument("--phase")
    fail.add_argument("--files", nargs="*", default=[])
    fail.add_argument("--commit", action="store_true")
    fail.add_argument("--no-commit", action="store_true")
    fail.add_argument("--commit-policy", choices=sorted(COMMIT_POLICIES))
    fail.set_defaults(func=command_fail)

    status = subparsers.add_parser("status")
    status.set_defaults(func=command_status)

    presets = subparsers.add_parser("presets")
    presets.set_defaults(func=command_presets)

    rollback = subparsers.add_parser("rollback-metadata")
    rollback.set_defaults(func=command_rollback_metadata)

    related = subparsers.add_parser("related-tests")
    related.add_argument("path")
    related.set_defaults(func=command_related_tests)

    incident = subparsers.add_parser("record-incident")
    incident.add_argument("--source", required=True)
    incident.add_argument("--key", required=True)
    incident.add_argument("--message")
    incident.add_argument("--window-seconds", type=int, default=60)
    incident.add_argument("--threshold", type=int, default=5)
    incident.set_defaults(func=command_record_incident)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
