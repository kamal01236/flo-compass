#!/usr/bin/env bash
# Per-plan worktree finish gate (Phase 2).
#
# Run from a LINKED worktree (not main). Enforces:
#   1. Tier 1 (flutter pub get && analyze && test)
#   2. Uncommitted-changes gate (excluding .worktree.env / plan-session.json / plan-checkpoint.json)
#   3. Forbidden-file gate against parallel-agents.mdc lines 21-29
#   4. Secret scan (regex + optional gitleaks) on diff vs base
#   5. Serial-merge patch-notes count
# On pass, flips session ready:true / tier1_pass:true and records patch note count.
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
PLAN_LIFECYCLE_SCRIPT="finish"
export PLAN_LIFECYCLE_SCRIPT

DO_PUSH=0
DO_SHIP=0
AUTO_YES=0

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_plan_worktree_finish.sh [--push] [--ship] [--yes] [-h|--help] [--version]

Run from a per-plan linked worktree after implementation is complete.

Gates (in order — first failure exits non-zero):
  1. Tier 1 (flutter pub get && analyze && test)
  2. Clean git tree (excluding .worktree.env / .cursor/plan-session.json / .cursor/plan-checkpoint.json)
  3. No forbidden shared files in the diff vs the integration base
  4. Secret pattern scan on the diff (gitleaks preferred, regex fallback)
  5. Patch-notes count from ### Serial-merge patch notes in the plan file

Options:
  --push       Push the branch to origin after gates pass (best-effort)
  --ship       Run Tier 2 smoke with teardown; with --push, open MR via wsl_open_mr.sh
  --yes        Non-interactive (currently only affects --push confirmation)
  -h, --help   Show this help
  --version    Show script and library versions

Env:
  FLUTTER_PORT / DOCKER_PORT — source .worktree.env first (FLUTTER_PORT must
                                not equal 3000 to prove you're in a linked
                                worktree, not the main one)
  PLAN_LIFECYCLE_IGNORE_FILE — override path to secret-scan allowlist
  DRY_RUN=1 — not supported (finish is already a read-only gate)

Example:
  cd /mnt/c/Nagarro/ai-avengers-plan-security
  source .worktree.env
  bash scripts/wsl_plan_worktree_finish.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) DO_PUSH=1; shift ;;
    --ship) DO_SHIP=1; shift ;;
    --yes)  AUTO_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    *)
      log "FAILED: unexpected argument: $1"
      usage
      exit 1
      ;;
  esac
done

version_gate || exit 1
phase_start
emit_event "start" "begin" 0

if is_main_worktree "${ROOT}"; then
  log "FAILED: run from a per-plan linked worktree, not the main worktree"
  emit_event "worktree_check" "fail" 1
  exit 1
fi

if [[ ! -f "${ROOT}/.worktree.env" ]]; then
  log "FAILED: missing .worktree.env — this doesn't look like a plan worktree"
  emit_event "env_check" "fail" 1
  exit 1
fi
# shellcheck disable=SC1091
source "${ROOT}/.worktree.env"

if [[ -z "${FLUTTER_PORT:-}" || "${FLUTTER_PORT}" == "3000" ]]; then
  log "FAILED: FLUTTER_PORT must come from .worktree.env (slot 1..5, not 3000)"
  log "Fix: source .worktree.env  before rerunning."
  emit_event "port_check" "fail" 1
  exit 1
fi

session_file="${ROOT}/${PLAN_SESSION_FILE_REL}"
if ! read_session "${session_file}"; then
  log "FAILED: missing ${session_file} — recreate the worktree with wsl_new_plan_worktree.sh"
  emit_event "session_load" "fail" 1
  exit 1
fi
branch="$(session_field branch)"
base="$(session_field base)"
plan_file_rel="$(session_field plan_file)"
PLAN_LIFECYCLE_BRANCH="${branch}"
export PLAN_LIFECYCLE_BRANCH

log "finish branch=${branch} base=${base} port=${FLUTTER_PORT}"

# 1. Tier 1
phase_start
log "Tier 1 (flutter pub get && analyze && test)..."
if ! flutter_pub_analyze_test; then
  log "FAILED: Tier 1 did not pass"
  log "Rollback: fix analyze/test errors, then re-run plan-worktree-finish.cmd"
  emit_event "tier1" "fail" 1
  exit 1
fi
emit_event "tier1" "pass" 0

# 2. Uncommitted-changes gate
phase_start
dirty="$(git status --porcelain \
  | grep -vE '^.. (\.worktree\.env|\.cursor/plan-session\.json|\.cursor/plan-checkpoint\.json)$' || true)"
if [[ -n "${dirty}" ]]; then
  log "FAILED: uncommitted changes remain (commit or stash before finish):"
  git status --short
  emit_event "dirty_tree" "fail" 1
  exit 1
fi
emit_event "dirty_tree" "pass" 0

# 3. Forbidden-file gate
phase_start
# Try origin/base first (typical), then plain base (offline dev boxes).
forbidden="$(forbidden_files_in_diff "origin/${base}" "${ROOT}" 2>/dev/null || true)"
if [[ -z "${forbidden}" ]]; then
  forbidden="$(forbidden_files_in_diff "${base}" "${ROOT}" 2>/dev/null || true)"
fi
if [[ -n "${forbidden}" ]]; then
  log "FAILED: forbidden shared files changed on this per-plan branch"
  log "See .cursor/rules/parallel-agents.mdc lines 21-29."
  echo "${forbidden}"
  log "Queue these as serial-merge patch notes in the plan file so the parent"
  log "can apply them on the integration branch — never on the per-plan branch."
  emit_event "forbidden_files" "fail" 1
  exit 1
fi
emit_event "forbidden_files" "pass" 0

# 4. Secret scan
phase_start
scan_base="origin/${base}"
git show-ref --verify --quiet "refs/remotes/origin/${base}" || scan_base="${base}"
if ! run_secret_scan "${scan_base}" since_base; then
  emit_event "secret_scan" "fail" 1
  exit 1
fi
emit_event "secret_scan" "pass" 0

# 5. Patch-notes count
phase_start
plan_file="${ROOT}/${plan_file_rel}"
notes_count="$(patch_notes_count "${plan_file}")"
if (( notes_count > 0 )); then
  log "Serial-merge patch notes (${notes_count}) queued for the parent to apply:"
  print_patch_notes "${plan_file}" | sed 's/^/  /'
else
  log "No serial-merge patch notes — nothing for the parent to apply on integration."
fi
emit_event "patch_notes" "counted" 0 "${notes_count}"

# Update session — mark ready. Preserve fields not written here.
main_worktree="$(session_field main_worktree)"
worktree_path="$(session_field worktree_path)"
slot="$(session_field slot)"
docker_port="$(session_field docker_port)"
write_session "${session_file}" \
  "branch=${branch}" \
  "base=${base}" \
  "slot=int:${slot}" \
  "flutter_port=int:${FLUTTER_PORT}" \
  "docker_port=int:${docker_port}" \
  "worktree_path=${worktree_path}" \
  "main_worktree=${main_worktree}" \
  "plan_file=${plan_file_rel}" \
  "ready=bool:true" \
  "tier1_pass=bool:true" \
  "patch_notes_count=int:${notes_count}"
emit_event "session_update" "ready" 0

if [[ "${DO_SHIP}" == "1" ]]; then
  phase_start
  log "Tier 2 smoke (TEARDOWN=1) via wsl_tier2_smoke.sh..."
  if TEARDOWN=1 bash "${ROOT}/scripts/wsl_tier2_smoke.sh"; then
    emit_event "tier2_smoke" "pass" 0
  else
    log "FAILED: Tier 2 smoke did not pass"
    emit_event "tier2_smoke" "fail" 1
    exit 1
  fi
fi

if [[ "${DO_PUSH}" == "1" ]]; then
  phase_start
  if git remote get-url origin >/dev/null 2>&1; then
    if [[ "${DO_SHIP}" == "1" ]]; then
      log "Opening MR via wsl_open_mr.sh (includes push)..."
      mr_args=(--yes)
      if [[ "${AUTO_YES}" == "0" ]]; then
        mr_args=()
      fi
      if bash "${ROOT}/scripts/wsl_open_mr.sh" "${mr_args[@]}"; then
        emit_event "push" "pass" 0
        emit_event "open_mr" "pass" 0
      else
        log "WARN: MR flow failed — resolve remote state and retry manually"
        emit_event "open_mr" "fail" 1
      fi
    else
      log "Pushing ${branch} to origin..."
      if git push -u origin "${branch}"; then
        emit_event "push" "pass" 0
      else
        log "WARN: push failed — resolve remote state and retry manually"
        emit_event "push" "fail" 1
      fi
    fi
  else
    log "No origin remote configured; skipping push"
    emit_event "push" "skip" 0
  fi
fi

LIFECYCLE_COMPLETED=1
cat <<EOF

================================================================
Plan worktree finish — READY

  Branch:              ${branch}
  Base:                ${base}
  Patch notes queued:  ${notes_count}

Next step (from the MAIN worktree, slot 0):

  plan-worktree-merge.cmd ${branch}

Rollback (if finish was premature):
  Continue editing in this worktree, then rerun this script; it will
  re-derive ready:true only when all gates pass again.

================================================================
EOF
emit_event "done" "pass" 0
