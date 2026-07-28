#!/usr/bin/env bash
# Auto-continue long plan runs via .cursor/plan-checkpoint.json.
# Opt-in: plan-lifecycle.json "auto_continue": true or PLAN_AUTO_CONTINUE_ENABLED=1.
# Always exits 0 — emits followup_message or additional_context only.

set -uo pipefail

input="$(cat)"
hook_event="${CURSOR_HOOK_EVENT:-}"
cwd="${CURSOR_PROJECT_DIR:-$(pwd)}"
checkpoint_file="${cwd}/.cursor/plan-checkpoint.json"
config_file="${cwd}/.cursor/plan-lifecycle.json"
local_config_file="${cwd}/.cursor/plan-lifecycle.local.json"

if [[ -z "${hook_event}" ]]; then
  if echo "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if "prompt" in d else 1)' 2>/dev/null; then
    hook_event="beforeSubmitPrompt"
  elif echo "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if "subagent_type" in d else 1)' 2>/dev/null; then
    hook_event="subagentStop"
  else
    hook_event="stop"
  fi
fi

export PLAN_AUTO_CONTINUE_ENABLED="${PLAN_AUTO_CONTINUE_ENABLED:-}"
export PLAN_CHECKPOINT_FILE="${checkpoint_file}"
export PLAN_LIFECYCLE_CONFIG="${config_file}"
export PLAN_LIFECYCLE_LOCAL="${local_config_file}"
export PLAN_HOOK_EVENT="${hook_event}"

python3 <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

checkpoint_path = os.environ["PLAN_CHECKPOINT_FILE"]
config_path = os.environ["PLAN_LIFECYCLE_CONFIG"]
local_config_path = os.environ["PLAN_LIFECYCLE_LOCAL"]
hook_event = os.environ["PLAN_HOOK_EVENT"]
env_flag = os.environ.get("PLAN_AUTO_CONTINUE_ENABLED", "").strip().lower()


def load_json(path):
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}


def lifecycle_enabled():
    defaults = {
        "enabled": False,
        "auto_continue": False,
        "auto_continue_max_loops": 5,
        "auto_continue_on_stop": True,
        "auto_continue_on_subagent_stop": True,
        "auto_continue_context_on_prompt": True,
    }
    config = dict(defaults)
    config.update(load_json(config_path))
    config.update(load_json(local_config_path))
    env_on = env_flag in {"1", "true", "yes", "on"}
    if env_on:
        config["auto_continue"] = True
    # Active when lifecycle enabled OR auto_continue / env override.
    if not config.get("enabled") and not config.get("auto_continue"):
        return config, False
    return config, True


def validate_checkpoint(data):
    if not isinstance(data, dict):
        return False, "not an object"
    if data.get("version") != "1":
        return False, "unsupported version"
    for key in (
        "plan",
        "phase",
        "done",
        "remaining",
        "auto_continue",
        "continue_count",
        "max_loops",
        "updated_at",
    ):
        if key not in data:
            return False, f"missing {key}"
    if not isinstance(data.get("done"), list) or not isinstance(data.get("remaining"), list):
        return False, "done/remaining must be arrays"
    updated_at = data.get("updated_at")
    if not isinstance(updated_at, str) or not updated_at.strip():
        return False, "updated_at must be a non-empty string"
    return True, ""


def iso_now():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def emit(obj):
    print(json.dumps(obj))
    sys.exit(0)


config, active = lifecycle_enabled()
if not active:
    emit({})

if not os.path.isfile(checkpoint_path):
    emit({})

checkpoint = load_json(checkpoint_path)
ok, reason = validate_checkpoint(checkpoint)
if not ok:
    emit({})

remaining = [str(x).strip() for x in checkpoint.get("remaining", []) if str(x).strip()]
if not remaining:
    emit({})

if not checkpoint.get("auto_continue", False):
    emit({})

max_loops = int(checkpoint.get("max_loops") or config.get("auto_continue_max_loops") or 5)
continue_count = int(checkpoint.get("continue_count") or 0)

plan = checkpoint.get("plan", "unknown-plan")
phase = checkpoint.get("phase", "unknown-phase")
done = checkpoint.get("done") or []
plan_file = checkpoint.get("plan_file", "")
branch = checkpoint.get("branch", "")
agent_id = checkpoint.get("agent_id", "")
notes = checkpoint.get("notes", "")

context_block = (
    f"Active plan checkpoint ({plan}, phase {phase}). "
    f"Done: {', '.join(done) if done else '(none)'}. "
    f"Remaining (finish-only): {', '.join(remaining)}."
)
if notes:
    context_block += f" Notes: {notes}"
if plan_file:
    context_block += f" Plan file: {plan_file}."
if branch:
    context_block += f" Branch: {branch}."
if agent_id:
    context_block += f" Prefer Task resume={agent_id} when applicable."

if hook_event in {"beforeSubmitPrompt", "UserPromptSubmit"}:
    if not config.get("auto_continue_context_on_prompt", True):
        emit({})
    emit({"additional_context": context_block})

if hook_event == "subagentStop" and not config.get("auto_continue_on_subagent_stop", True):
    emit({})

if hook_event == "stop" and not config.get("auto_continue_on_stop", True):
    emit({})

if hook_event not in {"stop", "subagentStop"}:
    emit({})

if continue_count >= max_loops:
    emit(
        {
            "additional_context": (
                f"Plan checkpoint auto-continue paused after {continue_count} loops "
                f"(max {max_loops}). Finish manually: {', '.join(remaining)}."
            )
        }
    )

checkpoint["continue_count"] = continue_count + 1
checkpoint["updated_at"] = iso_now()
try:
    with open(checkpoint_path, "w", encoding="utf-8") as fh:
        json.dump(checkpoint, fh, indent=2)
        fh.write("\n")
except OSError:
    pass

followup = (
    "Continue this plan from the checkpoint (finish-only — do NOT re-implement done items). "
    f"Plan: {plan}. Phase: {phase}. "
    f"Already done: {', '.join(done) if done else '(none)'}. "
    f"Remaining: {', '.join(remaining)}. "
    "Read .cursor/plan-checkpoint.json and .cursor/rules/plan-auto-continue.mdc. "
    "Update the checkpoint after each phase; clear remaining[] when complete. "
    "Run WSL Tier 1 before claiming done; Tier 2 when routing/deploy touched."
)
if agent_id:
    followup += f" If this was a subagent slice, resume agent {agent_id} instead of replanning."
if notes:
    followup += f" {notes}"

emit({"followup_message": followup})
PY
