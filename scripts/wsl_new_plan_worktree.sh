#!/usr/bin/env bash
# Parallel Plans Workflow — create a new git worktree on a new branch with
# an allocated Flutter/Docker port pair (slot 1..5) so multiple Cursor agents
# can iterate on separate plans in parallel on the same machine.
# See .cursor/rules/parallel-plans-workflow.mdc.
#
# Usage:
#   bash scripts/wsl_new_plan_worktree.sh <branch> <slot> [--base <base-branch>]
# Example:
#   bash scripts/wsl_new_plan_worktree.sh feat/plan-security 1 --base feat/sprint-N-integration

set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"
# shellcheck source=./wsl_plan_session.sh
source "${ROOT}/scripts/wsl_plan_session.sh"

SCRIPT_VERSION="1.1.0"
PLAN_LIFECYCLE_SCRIPT="start"
export PLAN_LIFECYCLE_SCRIPT

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_new_plan_worktree.sh <branch> <slot> [--base <base-branch>]

  <branch>   feat|fix|chore|refactor|test|docs|ci|perf|style / [a-z0-9-]+
  <slot>     1..5 (slot 0 is reserved for the main worktree; for >5 plans,
             use Task subagents with environment: "cloud" instead)
  --base     Base branch (default: main), typically feat/sprint-N-integration
  -h, --help
  --version  Print script version and short SHA of scripts/ tree

Ports allocated: FLUTTER_PORT=3000+slot, DOCKER_PORT=8080+slot.
See .cursor/rules/parallel-plans-workflow.mdc for the full workflow.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

# Parse -h/--version anywhere; positional args expected first otherwise.
positional=()
base="main"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    --base)
      [[ $# -ge 2 ]] || { log "FAILED: --base requires a value"; usage; exit 1; }
      base="$2"; shift 2 ;;
    -*)
      log "FAILED: unexpected argument: $1"; usage; exit 1 ;;
    *)
      positional+=("$1"); shift ;;
  esac
done

if [[ ${#positional[@]} -lt 2 ]]; then
  usage
  exit 1
fi
branch="${positional[0]}"
slot="${positional[1]}"

version_gate || exit 1
phase_start

branch_re='^(feat|fix|chore|refactor|test|docs|ci|perf|style)/[a-z0-9-]+$'
if ! [[ "${branch}" =~ ${branch_re} ]]; then
  log "FAILED: branch '${branch}' does not match ${branch_re}"
  log "See .cursor/rules/git-hygiene.mdc for branch naming."
  exit 1
fi

if ! [[ "${slot}" =~ ^[0-9]+$ ]]; then
  log "FAILED: slot must be an integer 1..5 (got '${slot}')"
  exit 1
fi
if (( slot == 0 )); then
  log "FAILED: slot 0 is reserved for the main worktree (ports 3000/8080)"
  exit 1
fi
if (( slot > 5 )); then
  log "FAILED: slot must be 1..5 (got ${slot}); for more than 5 concurrent plans,"
  log "use Task subagents with environment: \"cloud\" instead."
  log "See .cursor/rules/parallel-plans-workflow.mdc."
  exit 1
fi

PLAN_LIFECYCLE_BRANCH="${branch}"
export PLAN_LIFECYCLE_BRANCH

slug="${branch#*/}"
worktree_path="$(cd "${ROOT}/.." && pwd)/ai-avengers-${slug}"
FLUTTER_PORT=$((3000 + slot))
DOCKER_PORT=$((8080 + slot))

log "branch=${branch} base=${base} slot=${slot} FLUTTER_PORT=${FLUTTER_PORT} DOCKER_PORT=${DOCKER_PORT}"
log "worktree path: ${worktree_path}"

if [[ -e "${worktree_path}" ]]; then
  log "FAILED: worktree path already exists: ${worktree_path}"
  log "Remove it first: git worktree remove ${worktree_path}"
  emit_event "guard" "worktree_exists" 1
  exit 1
fi
if git -C "${ROOT}" show-ref --verify --quiet "refs/heads/${branch}"; then
  log "FAILED: local branch '${branch}' already exists"
  log "Pick a different branch name or delete: git branch -D ${branch}"
  emit_event "guard" "branch_exists" 1
  exit 1
fi

resolve_base_ref() {
  if git -C "${ROOT}" show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    echo "origin/${base}"
    return 0
  fi
  if git -C "${ROOT}" show-ref --verify --quiet "refs/heads/${base}"; then
    echo "${base}"
    return 0
  fi
  return 1
}

log "Resolving base ref for ${base}..."
start_point="$(resolve_base_ref || true)"
if [[ -z "${start_point}" ]]; then
  log "No local origin/${base} or ${base}; fetching origin..."
  if ! GIT_TERMINAL_PROMPT=0 timeout 60 git -C "${ROOT}" fetch origin "${base}" 2>/dev/null; then
    log "FAILED: cannot resolve base '${base}' (fetch failed and no local ref)"
    emit_event "resolve_base" "fail" 1
    exit 1
  fi
  start_point="origin/${base}"
fi

if GIT_TERMINAL_PROMPT=0 timeout 60 git -C "${ROOT}" fetch origin "${base}" 2>/dev/null; then
  if git -C "${ROOT}" show-ref --verify --quiet "refs/remotes/origin/${base}"; then
    start_point="origin/${base}"
  fi
fi

if GIT_TERMINAL_PROMPT=0 timeout 15 git -C "${ROOT}" ls-remote --exit-code origin "${branch}" >/dev/null 2>&1; then
  log "FAILED: remote branch 'origin/${branch}' already exists"
  log "Pick a different branch name."
  emit_event "guard" "remote_branch_exists" 1
  exit 1
fi

log "Creating worktree at ${worktree_path} on new branch ${branch} (base: ${start_point})"
git -C "${ROOT}" worktree add -b "${branch}" "${worktree_path}" "${start_point}"

env_file="${worktree_path}/.worktree.env"
cat > "${env_file}" <<EOF
export FLUTTER_PORT=${FLUTTER_PORT}
export DOCKER_PORT=${DOCKER_PORT}
EOF
log "Wrote ${env_file}"

# Write session metadata consumed by finish/merge/cleanup scripts.
session_file="${worktree_path}/${PLAN_SESSION_FILE_REL}"
plan_file_rel=".cursor/plans/${slug}.plan.md"
main_root_wsl="$(cd "${ROOT}" && pwd)"
mkdir -p "$(dirname "${session_file}")"
write_session "${session_file}" \
  "branch=${branch}" \
  "base=${base}" \
  "slot=int:${slot}" \
  "flutter_port=int:${FLUTTER_PORT}" \
  "docker_port=int:${DOCKER_PORT}" \
  "worktree_path=${worktree_path}" \
  "main_worktree=${main_root_wsl}" \
  "plan_file=${plan_file_rel}" \
  "ready=bool:false" \
  "tier1_pass=bool:false" \
  "patch_notes_count=int:0"
log "Wrote ${session_file}"

# Enable Cursor plan-lifecycle hook reminders in this worktree only.
lifecycle_config_file="${worktree_path}/.cursor/plan-lifecycle.json"
mkdir -p "$(dirname "${lifecycle_config_file}")"
cat > "${lifecycle_config_file}" <<'EOF'
{
  "enabled": true,
  "remind_on_prompt": true,
  "remind_on_stop": true,
  "auto_continue": true,
  "auto_continue_max_loops": 5,
  "auto_continue_on_stop": true,
  "auto_continue_on_subagent_stop": true,
  "auto_continue_context_on_prompt": true
}
EOF
log "Wrote ${lifecycle_config_file} (enabled lifecycle + auto-continue for this plan worktree)"

hooks_template="${ROOT}/.cursor/hooks.json.template"
hooks_file="${worktree_path}/.cursor/hooks.json"
if [[ -f "${hooks_template}" ]]; then
  cp "${hooks_template}" "${hooks_file}"
  log "Wrote ${hooks_file} (registered Cursor hook reminders for this plan worktree)"
else
  log "WARN: ${hooks_template} not found; skipping hook registration in ${worktree_path}"
fi

# Exclude .worktree.env, plan-session.json, and plan-checkpoint.json from git in this worktree
# only. Linked worktrees have their own info directory under
# .git/worktrees/<name>/info/, so ask git for the resolved path rather than
# assuming ${worktree_path}/.git/info/exclude.
exclude_path="$(git -C "${worktree_path}" rev-parse --git-path info/exclude)"
[[ "${exclude_path}" == /* ]] || exclude_path="${worktree_path}/${exclude_path}"
mkdir -p "$(dirname "${exclude_path}")"
if ! grep -qxF '.worktree.env' "${exclude_path}" 2>/dev/null; then
  echo '.worktree.env' >> "${exclude_path}"
fi
if ! grep -qxF "${PLAN_SESSION_FILE_REL}" "${exclude_path}" 2>/dev/null; then
  echo "${PLAN_SESSION_FILE_REL}" >> "${exclude_path}"
fi
if ! grep -qxF '.cursor/plan-checkpoint.json' "${exclude_path}" 2>/dev/null; then
  echo '.cursor/plan-checkpoint.json' >> "${exclude_path}"
fi
log "Excluded .worktree.env, ${PLAN_SESSION_FILE_REL}, and .cursor/plan-checkpoint.json via ${exclude_path}"

ensure_lifecycle_log_excluded "${ROOT}"
emit_event "worktree_add" "created" 0

template="${ROOT}/.cursor/plans/_TEMPLATE_parallel_plan.md"
seeded_plan="${worktree_path}/.cursor/plans/${slug}.plan.md"
if [[ -f "${template}" ]]; then
  if [[ ! -f "${seeded_plan}" ]]; then
    mkdir -p "$(dirname "${seeded_plan}")"
    cp "${template}" "${seeded_plan}"
    sed -i \
      -e "s|{{BRANCH}}|${branch}|g" \
      -e "s|{{WORKTREE_PATH}}|${worktree_path}|g" \
      -e "s|{{SLOT}}|${slot}|g" \
      -e "s|{{FLUTTER_PORT}}|${FLUTTER_PORT}|g" \
      -e "s|{{DOCKER_PORT}}|${DOCKER_PORT}|g" \
      "${seeded_plan}"
    log "Seeded plan file: ${seeded_plan}"
  else
    log "Plan file already exists (leaving as-is): ${seeded_plan}"
  fi
else
  log "Template ${template} not found; skipping plan seed (create the plan file manually)"
fi

LIFECYCLE_COMPLETED=1
cat <<EOF

================================================================
Parallel worktree ready

  Worktree:      ${worktree_path}
  Branch:        ${branch}  (base: origin/${base})
  Slot:          ${slot}
  FLUTTER_PORT:  ${FLUTTER_PORT}
  DOCKER_PORT:   ${DOCKER_PORT}

Next steps (run inside WSL from the new worktree):

  cd ${worktree_path}
  source .worktree.env
  echo \$FLUTTER_PORT           # sanity check: should print ${FLUTTER_PORT}
  bash scripts/wsl_dev.sh

When the plan is complete, run finish (from this worktree):

  bash scripts/wsl_plan_worktree_finish.sh
  # Or from Windows in this folder: plan-worktree-finish.cmd

Windows browser URL once dev server is up:

  http://localhost:${FLUTTER_PORT}/

Open the new worktree in a Cursor window (from Windows PowerShell or CMD):

  cursor "C:\\Nagarro\\ai-avengers-${slug}"

Reminder: base your MR on '${base}', not 'main'.

After finish passes, from the MAIN worktree run:

  plan-worktree-merge.cmd ${branch}
  plan-worktree-cleanup.cmd ${branch}   # after merge

================================================================
EOF
