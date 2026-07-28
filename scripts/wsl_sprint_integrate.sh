#!/usr/bin/env bash
# Sprint close-out on integration branch (Phase 5).
#
# Run from the MAIN worktree while checked out on (or about to checkout) the
# integration branch. Steps:
#   1. checkout + ff-only pull integration
#   2. Full Tier 1 (flutter pub get && analyze && test)
#   3. Full Tier 2 + coverage — delegates to scripts/wsl_deploy.sh
#   4. Draft augmentation-log entry with duration rollup from plan-lifecycle.log.jsonl
#   5. Optional: append draft to hackathon-docs/augmentation-log.md (prompted)
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
PLAN_LIFECYCLE_SCRIPT="integrate"
export PLAN_LIFECYCLE_SCRIPT

BASE="feat/sprint-1-integration"
AUTO_YES=0
DRAFT_FILE="/tmp/augmentation-draft-parallel-lifecycle.md"

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_sprint_integrate.sh [options]

Options:
  --base <integration>  Integration branch (default: feat/sprint-1-integration)
  --yes                 Append augmentation-log draft without prompting
  --dry-run             Print planned actions only (no side effects)
  -h, --help            Show this help
  --version             Show script and library versions

Env:
  PLAN_LIFECYCLE_LOG    — override event log path (used for duration rollup)
  PLAN_LIFECYCLE_QUIET  — set to 1 to suppress the Windows launcher completion toast
  Delegates Tier 2 to scripts/wsl_deploy.sh — honours its env vars (SERVICES_THRESHOLD, etc.)

Runs full Tier 1 + Tier 2 + coverage gate on the integration branch, then drafts
one augmentation-log entry with duration rollup from .cursor/plan-lifecycle.log.jsonl.

Example:
  bash scripts/wsl_sprint_integrate.sh --base feat/sprint-1-integration
  bash scripts/wsl_sprint_integrate.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { log "FAILED: --base requires a value"; exit 1; }
      BASE="$2"; shift 2 ;;
    --yes) AUTO_YES=1; shift ;;
    --dry-run) PLAN_LIFECYCLE_DRY_RUN=1; export PLAN_LIFECYCLE_DRY_RUN; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    *) log "FAILED: unexpected argument: $1"; usage; exit 1 ;;
  esac
done

version_gate || exit 1

PLAN_LIFECYCLE_BRANCH="${BASE}"
export PLAN_LIFECYCLE_BRANCH

phase_start
emit_event "start" "begin" 0

trap 'lifecycle_cleanup' INT TERM EXIT

if ! is_main_worktree "${ROOT}"; then
  log "FAILED: run from the main worktree (slot 0)"
  emit_event "worktree_check" "fail" 1
  exit 1
fi

# Register a hook so Ctrl+C tears down docker if we started it (Tier 2).
LIFECYCLE_STARTED_DOCKER=0
register_cleanup_hook '[[ "${LIFECYCLE_STARTED_DOCKER:-0}" == "1" ]] && (docker compose down 2>/dev/null; fuser -k ${DOCKER_PORT:-8080}/tcp 2>/dev/null) || true'

if is_dry_run; then
  dry_run_msg "would checkout ${BASE} and ff-only pull"
  dry_run_msg "would run Tier 1 (flutter pub get && analyze && test)"
  dry_run_msg "would run scripts/wsl_deploy.sh (Tier 2 + coverage)"
  dry_run_msg "would draft augmentation-log entry to ${DRAFT_FILE}"
  dry_run_msg "would (with confirmation) append to hackathon-docs/augmentation-log.md"
  emit_event "dry_run" "pass" 0
  LIFECYCLE_COMPLETED=1
  exit 0
fi

# ---- Checkout + pull integration ----------------------------------------
phase_start
log "Checking out ${BASE}..."
git checkout "${BASE}"
if git show-ref --verify --quiet "refs/remotes/origin/${BASE}"; then
  git pull --ff-only origin "${BASE}" 2>/dev/null \
    || log "WARN: could not ff-only pull origin/${BASE} (offline?)"
fi
emit_event "checkout" "pass" 0

# ---- Sprint summary -----------------------------------------------------
phase_start
main_ref="main"
if ! git show-ref --verify --quiet "refs/heads/main" \
   && ! git show-ref --verify --quiet "refs/remotes/origin/main"; then
  main_ref="${BASE}"
fi
log "Sprint summary (${main_ref}..HEAD):"
git log --oneline "${main_ref}..HEAD" 2>/dev/null | head -30 | sed 's/^/  /' || true
merged_count="$(git log --oneline --merges "${main_ref}..HEAD" 2>/dev/null | wc -l | tr -d ' ')"
log "Merge commits since ${main_ref}: ${merged_count}"
emit_event "summary" "pass" 0

# ---- Tier 1 -------------------------------------------------------------
phase_start
log "Tier 1..."
if ! flutter_pub_analyze_test; then
  log "FAILED: Tier 1 on ${BASE}"
  emit_event "tier1" "fail" 1
  exit 1
fi
emit_event "tier1" "pass" 0

# ---- Tier 2 + coverage (delegate) ---------------------------------------
phase_start
log "Tier 2 + coverage — delegating to scripts/wsl_deploy.sh"
LIFECYCLE_STARTED_DOCKER=1
if ! bash "${ROOT}/scripts/wsl_deploy.sh"; then
  log "FAILED: Tier 2 / coverage on ${BASE}"
  log "$(rollback_hint integrate)"
  emit_event "tier2" "fail" 1
  exit 1
fi
LIFECYCLE_STARTED_DOCKER=0
emit_event "tier2" "pass" 0

# ---- Augmentation-log draft ---------------------------------------------
phase_start
duration_rollup="$(rollup_durations "$(lifecycle_log_path "${ROOT}")")"
today="$(date +%Y-%m-%d)"

cat > "${DRAFT_FILE}" <<EOF
## [${today}] Sprint integrate — parallel plans lifecycle

- **Owner:** Lead Developer
- **Model:** composer
- **Goal:** Integration branch validated end-to-end (Tier 1 + Tier 2 + coverage) after per-plan merges
- **Cursor prompt:** sprint-integrate on ${BASE} after ${merged_count} merge commits
- **Cursor did:** Full Tier 1 + Tier 2 + coverage gate via wsl_deploy.sh; lifecycle duration rollup below
- **Local validation:** Tier 1 pass · Tier 2 pass · coverage gate per wsl_deploy.sh
- **Plan gap:** none
- **Outcome:** accepted
- **Lifecycle durations:**
${duration_rollup}
- **Files:** integration branch ${BASE} (no app changes in this tooling run)

---
EOF

log "Augmentation-log draft written to ${DRAFT_FILE}"
echo "----------------------------------------------------------------"
cat "${DRAFT_FILE}"
echo "----------------------------------------------------------------"
emit_event "draft" "written" 0

# ---- Optional append ----------------------------------------------------
phase_start
if confirm_or_yes "Append draft to hackathon-docs/augmentation-log.md? [y/N]" "${AUTO_YES}"; then
  aug_log="${ROOT}/hackathon-docs/augmentation-log.md"
  {
    echo ""
    cat "${DRAFT_FILE}"
  } >> "${aug_log}"
  log "Appended to ${aug_log}"
  emit_event "auglog_append" "pass" 0
else
  log "Skipped append — draft remains at ${DRAFT_FILE}"
  emit_event "auglog_append" "skip" 0
fi

LIFECYCLE_COMPLETED=1
cat <<EOF

================================================================
Sprint integrate complete

  Integration: ${BASE}
  Draft:       ${DRAFT_FILE}

Open MR manually: ${BASE} -> main
(Auto-MR is intentionally out of scope — see plan Not in scope.)

$(rollback_hint integrate)

================================================================
EOF
emit_event "done" "pass" 0
