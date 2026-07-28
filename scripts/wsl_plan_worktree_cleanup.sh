#!/usr/bin/env bash
# Remove a merged per-plan worktree and free its port slot (Phase 4).
#
# Run from the MAIN worktree. Steps:
#   1. Refuse if <branch> is not merged into --base
#   2. Refuse if <branch> has commits not on any remote (unless --force) — Phase 8.8
#   3. Stop Flutter dev on the worktree's slot port
#   4. Best-effort `docker compose down` in the worktree
#   5. git worktree remove --force
#   6. git branch -D <branch>
#   7. git worktree prune
#
# See scripts/README.md and .cursor/plans/parallel_plans_lifecycle_8f81133b.plan.md.

set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "${ROOT}"

# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"
# shellcheck source=./wsl_plan_session.sh
source "${ROOT}/scripts/wsl_plan_session.sh"

SCRIPT_VERSION="1.0.0"
PLAN_LIFECYCLE_SCRIPT="cleanup"
export PLAN_LIFECYCLE_SCRIPT

BRANCH=""
BASE=""
AUTO_YES=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_plan_worktree_cleanup.sh <branch> [options]

Options:
  --base <integration>  Base branch used for the merged-gate check (default: from session)
  --yes                 Non-interactive confirmation
  --force               Allow cleanup when the branch has commits not on any remote
  --dry-run             Print planned actions only (no side effects)
  -h, --help            Show this help
  --version             Show script and library versions

Env:
  PLAN_LIFECYCLE_LOG  — override event log path (default: main worktree .cursor/plan-lifecycle.log.jsonl)

Run from the MAIN worktree after plan-worktree-merge.cmd has landed the branch
onto the integration branch and pushed it (typical flow).

Example:
  bash scripts/wsl_plan_worktree_cleanup.sh feat/plan-security --yes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { log "FAILED: --base requires a value"; exit 1; }
      BASE="$2"; shift 2 ;;
    --yes) AUTO_YES=1; shift ;;
    --force) FORCE=1; shift ;;
    --dry-run) PLAN_LIFECYCLE_DRY_RUN=1; export PLAN_LIFECYCLE_DRY_RUN; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    -*) log "FAILED: unknown option: $1"; usage; exit 1 ;;
    *)
      if [[ -z "${BRANCH}" ]]; then
        BRANCH="$1"
      else
        log "FAILED: unexpected positional argument: $1"; usage; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "${BRANCH}" ]]; then usage; exit 1; fi

version_gate || exit 1

PLAN_LIFECYCLE_BRANCH="${BRANCH}"
export PLAN_LIFECYCLE_BRANCH

phase_start
emit_event "start" "begin" 0

trap 'lifecycle_cleanup' EXIT

if ! is_main_worktree "${ROOT}"; then
  log "FAILED: run from the main worktree (slot 0)"
  emit_event "worktree_check" "fail" 1
  exit 1
fi

# ---- Resolve worktree path + session ------------------------------------
worktree_path="$(find_worktree_path_for_branch "${BRANCH}" "${ROOT}")"
session_flutter_port=""
session_docker_port=""
session_slot=""
session_base=""

if [[ -n "${worktree_path}" ]] \
   && read_session "${worktree_path}/${PLAN_SESSION_FILE_REL}"; then
  session_slot="$(session_field slot)"
  session_flutter_port="$(session_field flutter_port)"
  session_docker_port="$(session_field docker_port)"
  session_base="$(session_field base)"
elif [[ -z "${worktree_path}" ]]; then
  # No linked worktree — try derived path anyway (may still exist on disk).
  slug="${BRANCH#*/}"
  worktree_path="$(cd "${ROOT}/.." && pwd)/ai-avengers-${slug}"
  log "WARN: no linked worktree for ${BRANCH}; using derived path ${worktree_path}"
fi

BASE="${BASE:-${session_base:-feat/sprint-1-integration}}"

# ---- Merged gate --------------------------------------------------------
phase_start
if ! git show-ref --verify --quiet "refs/heads/${BRANCH}" \
   && ! git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  log "FAILED: no local or remote ref for branch ${BRANCH}"
  emit_event "branch_check" "fail" 1
  exit 1
fi

if ! git merge-base --is-ancestor "${BRANCH}" "${BASE}" 2>/dev/null; then
  log "FAILED: ${BRANCH} is not an ancestor of ${BASE}"
  log "Merge it first: plan-worktree-merge.cmd ${BRANCH} --base ${BASE}"
  emit_event "merged_gate" "fail" 1
  exit 1
fi
emit_event "merged_gate" "pass" 0

# ---- Unpushed-commit guard (Phase 8.8) ----------------------------------
phase_start
unpushed="$(git log --oneline "${BRANCH}" --not --remotes='origin/*' 2>/dev/null || true)"
if [[ -n "${unpushed}" ]] && [[ "${FORCE}" != "1" ]]; then
  local_count="$(echo "${unpushed}" | wc -l | tr -d ' ')"
  log "FAILED: branch ${BRANCH} has ${local_count} commit(s) not on any remote:"
  echo "${unpushed}" | sed 's/^/  /'
  log ""
  log "Push first, or pass --force to discard the unpushed work:"
  log "  git push origin ${BRANCH}     # to keep it"
  log "  ${BASH_SOURCE[0]##*/} ${BRANCH} --force --yes   # to discard"
  emit_event "unpushed_guard" "fail" 1
  exit 1
fi
emit_event "unpushed_guard" "pass" 0

# ---- Dry-run early exit -------------------------------------------------
if is_dry_run; then
  dry_run_msg "would stop Flutter on port ${session_flutter_port:-?}"
  dry_run_msg "would run docker compose down (DOCKER_PORT=${session_docker_port:-?}) in ${worktree_path}"
  dry_run_msg "would git worktree remove --force ${worktree_path}"
  dry_run_msg "would git branch -D ${BRANCH}"
  dry_run_msg "would git worktree prune"
  emit_event "dry_run" "pass" 0
  LIFECYCLE_COMPLETED=1
  exit 0
fi

if ! confirm_or_yes "Remove worktree ${worktree_path} and branch ${BRANCH}? [y/N]" "${AUTO_YES}"; then
  log "Cleanup cancelled."
  emit_event "confirm" "cancelled" 0
  LIFECYCLE_COMPLETED=1
  exit 0
fi

# ---- Stop Flutter -------------------------------------------------------
phase_start
if [[ -n "${session_flutter_port}" ]]; then
  pidfile="/tmp/flo-compass-flutter-${session_flutter_port}.pid"
  if [[ -f "${pidfile}" ]]; then
    kill "$(cat "${pidfile}")" 2>/dev/null || true
    rm -f "${pidfile}"
  fi
  fuser -k "${session_flutter_port}/tcp" 2>/dev/null || true
fi
emit_event "stop_flutter" "pass" 0

# ---- Docker compose down (best-effort) ----------------------------------
phase_start
if [[ -d "${worktree_path}" && -n "${session_docker_port}" ]]; then
  (
    cd "${worktree_path}"
    DOCKER_PORT="${session_docker_port}" docker compose down 2>/dev/null || true
  )
fi
emit_event "docker_down" "pass" 0

# ---- Worktree removal ---------------------------------------------------
phase_start
if [[ -d "${worktree_path}" ]]; then
  git worktree remove --force "${worktree_path}" 2>/dev/null \
    || git worktree remove "${worktree_path}" 2>/dev/null \
    || log "WARN: git worktree remove failed for ${worktree_path}"
fi
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git branch -D "${BRANCH}" 2>/dev/null || log "WARN: git branch -D failed for ${BRANCH}"
fi
git worktree prune
emit_event "worktree_remove" "pass" 0

log "Slot ${session_slot:-?} freed (ports ${session_flutter_port:-?}/${session_docker_port:-?})"

LIFECYCLE_COMPLETED=1
cat <<EOF

================================================================
Worktree cleanup complete

  Branch removed:  ${BRANCH}
  Slot freed:      ${session_slot:-unknown}

$(rollback_hint cleanup)

================================================================
EOF
emit_event "done" "pass" 0
