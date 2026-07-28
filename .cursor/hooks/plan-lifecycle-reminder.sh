#!/usr/bin/env bash
# Non-blocking plan-lifecycle reminders for Cursor hooks.
# Opt-in via .cursor/plan-lifecycle.json (enabled: true) or PLAN_LIFECYCLE_ENABLED=1.
# Always exits 0 — injects context only, never blocks merges.

set -uo pipefail

input="$(cat)"
hook_event="${CURSOR_HOOK_EVENT:-}"
cwd="${CURSOR_PROJECT_DIR:-$(pwd)}"
session_file="${cwd}/.cursor/plan-session.json"
checkpoint_file="${cwd}/.cursor/plan-checkpoint.json"
config_file="${cwd}/.cursor/plan-lifecycle.json"
local_config_file="${cwd}/.cursor/plan-lifecycle.local.json"

# Detect event from stdin JSON when CURSOR_HOOK_EVENT is unset
if [[ -z "${hook_event}" ]]; then
  if echo "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if "prompt" in d else 1)' 2>/dev/null; then
    hook_event="beforeSubmitPrompt"
  else
    hook_event="stop"
  fi
fi

read_lifecycle_config() {
  python3 - "${config_file}" "${local_config_file}" "${PLAN_LIFECYCLE_ENABLED:-}" <<'PY'
import json
import os
import sys

defaults = {
    "enabled": False,
    "remind_on_prompt": True,
    "remind_on_stop": True,
}

def load(path):
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
        return data if isinstance(data, dict) else {}
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return {}

config = dict(defaults)
for path in sys.argv[1:3]:
    if path:
        config.update(load(path))

env_flag = sys.argv[3].strip().lower()
if env_flag in {"1", "true", "yes", "on"}:
    config["enabled"] = True

print(json.dumps(config))
PY
}

lifecycle_config="$(read_lifecycle_config 2>/dev/null || echo '{"enabled":false,"remind_on_prompt":true,"remind_on_stop":true}')"
lifecycle_enabled="$(echo "${lifecycle_config}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("enabled", False))' 2>/dev/null || echo False)"
remind_on_prompt="$(echo "${lifecycle_config}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("remind_on_prompt", True))' 2>/dev/null || echo True)"
remind_on_stop="$(echo "${lifecycle_config}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("remind_on_stop", True))' 2>/dev/null || echo True)"

if [[ "${lifecycle_enabled}" != "True" && "${lifecycle_enabled}" != "true" && "${lifecycle_enabled}" != "1" ]]; then
  echo '{}'
  exit 0
fi

emit_followup() {
  local msg="$1"
  printf '%s\n' "{\"followup_message\":$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "${msg}")}"
}

emit_context() {
  local msg="$1"
  printf '%s\n' "{\"additional_context\":$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "${msg}")}"
}

case "${hook_event}" in
  beforeSubmitPrompt|UserPromptSubmit)
    if [[ "${remind_on_prompt}" == "True" || "${remind_on_prompt}" == "true" || "${remind_on_prompt}" == "1" ]]; then
      prompt="$(echo "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("prompt",""))' 2>/dev/null || true)"
      if echo "${prompt}" | grep -qE '\.cursor/plans/[^[:space:]]+\.plan\.md'; then
        if [[ ! -f "${session_file}" ]]; then
          emit_context "Reminder: parallel plan work should start from a dedicated worktree — run new-plan-worktree.cmd <branch> <slot> --base <integration> before editing."
          exit 0
        fi
      fi
    fi
    ;;
  stop)
    if [[ "${remind_on_stop}" == "True" || "${remind_on_stop}" == "true" || "${remind_on_stop}" == "1" ]]; then
      # plan-auto-continue.sh owns follow-up when an active checkpoint remains.
      if [[ -f "${checkpoint_file}" ]]; then
        remaining="$(python3 -c '
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    rem = [x for x in d.get("remaining", []) if str(x).strip()]
    auto = bool(d.get("auto_continue", False))
    print("yes" if auto and rem else "no")
except Exception:
    print("no")
' "${checkpoint_file}" 2>/dev/null || echo no)"
        if [[ "${remaining}" == "yes" ]]; then
          echo '{}'
          exit 0
        fi
      fi
      if [[ -f "${session_file}" ]]; then
        ready="$(python3 -c 'import json; print(json.load(open("'"${session_file}"'")).get("ready", False))' 2>/dev/null || echo False)"
        if [[ "${ready}" == "False" ]]; then
          emit_followup "Reminder: run plan-worktree-finish.cmd in this worktree when the plan slice is complete (Tier 1 + gates)."
          exit 0
        fi
      fi
    fi
    ;;
esac

echo '{}'
exit 0
