#!/usr/bin/env python3
"""Smoke test for plan-auto-continue.sh lifecycle_enabled() activation."""
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HOOK = ROOT / ".cursor/hooks/plan-auto-continue.sh"
LIFECYCLE = ROOT / ".cursor/plan-lifecycle.json"
CHECKPOINT = ROOT / ".cursor/plan-checkpoint.json"
EXAMPLE = ROOT / ".cursor/plan-checkpoint.example.json"

original_lifecycle = LIFECYCLE.read_text(encoding="utf-8") if LIFECYCLE.exists() else None
had_checkpoint = CHECKPOINT.exists()


def run_hook(enabled: bool, auto_continue: bool, env: str = "") -> bool:
    cfg = {
        "enabled": enabled,
        "auto_continue": auto_continue,
        "remind_on_prompt": True,
        "remind_on_stop": True,
    }
    LIFECYCLE.write_text(json.dumps(cfg) + "\n", encoding="utf-8")
    CHECKPOINT.write_text(EXAMPLE.read_text(encoding="utf-8"), encoding="utf-8")

    env_vars = os.environ.copy()
    env_vars["CURSOR_HOOK_EVENT"] = "stop"
    env_vars["CURSOR_PROJECT_DIR"] = str(ROOT)
    if env:
        env_vars["PLAN_AUTO_CONTINUE_ENABLED"] = env
    else:
        env_vars.pop("PLAN_AUTO_CONTINUE_ENABLED", None)

    proc = subprocess.run(
        [str(HOOK)],
        input="{}",
        capture_output=True,
        text=True,
        env=env_vars,
        cwd=ROOT,
        check=False,
    )
    out = json.loads(proc.stdout or "{}")
    return "followup_message" in out


def run_hook_with_checkpoint(checkpoint: dict, env: str = "") -> dict:
    cfg = {
        "enabled": False,
        "auto_continue": True,
        "remind_on_prompt": True,
        "remind_on_stop": True,
    }
    LIFECYCLE.write_text(json.dumps(cfg) + "\n", encoding="utf-8")
    CHECKPOINT.write_text(json.dumps(checkpoint) + "\n", encoding="utf-8")

    env_vars = os.environ.copy()
    env_vars["CURSOR_HOOK_EVENT"] = "stop"
    env_vars["CURSOR_PROJECT_DIR"] = str(ROOT)
    if env:
        env_vars["PLAN_AUTO_CONTINUE_ENABLED"] = env
    else:
        env_vars.pop("PLAN_AUTO_CONTINUE_ENABLED", None)

    proc = subprocess.run(
        [str(HOOK)],
        input="{}",
        capture_output=True,
        text=True,
        env=env_vars,
        cwd=ROOT,
        check=False,
    )
    return json.loads(proc.stdout or "{}")


def main() -> int:
    cases = [
        (True, False, "", True, "enabled=true alone should activate"),
        (False, True, "", True, "auto_continue=true should activate"),
        (False, False, "", False, "both false should stay off"),
        (False, False, "1", True, "env override should activate"),
    ]
    failed = 0
    for enabled, auto_continue, env, expected, label in cases:
        actual = run_hook(enabled, auto_continue, env)
        if actual != expected:
            print(f"FAIL: {label} (got {actual}, expected {expected})")
            failed += 1
        else:
            print(f"OK: {label}")

    example = json.loads(EXAMPLE.read_text(encoding="utf-8"))
    missing_updated = dict(example)
    del missing_updated["updated_at"]
    out = run_hook_with_checkpoint(missing_updated)
    if "followup_message" in out:
        print("FAIL: checkpoint missing updated_at should not auto-continue")
        failed += 1
    else:
        print("OK: checkpoint missing updated_at rejected by validation")

    if original_lifecycle is not None:
        LIFECYCLE.write_text(original_lifecycle, encoding="utf-8")
    elif LIFECYCLE.exists():
        LIFECYCLE.unlink()
    if not had_checkpoint and CHECKPOINT.exists():
        CHECKPOINT.unlink()

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
