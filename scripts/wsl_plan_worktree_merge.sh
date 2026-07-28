#!/usr/bin/env bash
# Merge a ready per-plan branch into the integration branch (Phase 3).
#
# Run from the MAIN worktree only. Steps:
#   1. Acquire flock on .git/integration-merge.lock (30s wait, stale-clear)
#   2. Load session for <branch>; verify ready:true (unless --resume)
#   3. Pre-flight (disk / fsck / remote-sync) — Phase 8.5
#   4. Reflog snapshot for <base> — Phase 8.7
#   5. git checkout <base>, ff-only pull, merge --no-ff <branch>
#   6. Secret scan on the merge commit (regex + optional gitleaks) — Phase 8.6
#   7. Grep guardrails (parallel-agents.mdc lines 38-42)
#   8. Tier 1 on integration
#   9. Patch-notes prompt loop (parent applies, then --resume)
#  10. git push origin <base> (best-effort)
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
PLAN_LIFECYCLE_SCRIPT="merge"
export PLAN_LIFECYCLE_SCRIPT

BRANCH=""
BASE=""
AUTO_YES=0
RESUME=0
FORCE_BEHIND=0
REFLOG_SNAPSHOT=""

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_plan_worktree_merge.sh <branch> [options]

Options:
  --base <integration>   Integration branch (default: from session file, else feat/sprint-1-integration)
  --yes                  Non-interactive confirmation for prompts
  --resume               Skip merge (assume already merged); re-run guardrails, Tier 1, push
  --dry-run              Print planned actions only (no side effects)
  --force-behind         Allow merge when local <base> is behind origin/<base>
  -h, --help             Show this help
  --version              Show script and library versions

Env:
  PLAN_LIFECYCLE_IGNORE_FILE — override path to secret-scan allowlist
  PLAN_LIFECYCLE_LOG        — override event log path (default: main worktree .cursor/plan-lifecycle.log.jsonl)

Locks:
  Serializes via flock on .git/integration-merge.lock (30 s wait). Stale locks
  (owner PID dead on same host, or STARTED_AT > 6 h ago) auto-clear on retry.

Example:
  bash scripts/wsl_plan_worktree_merge.sh feat/plan-security
  bash scripts/wsl_plan_worktree_merge.sh feat/plan-security --resume --yes
  bash scripts/wsl_plan_worktree_merge.sh feat/plan-security --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || { log "FAILED: --base requires a value"; exit 1; }
      BASE="$2"; shift 2 ;;
    --yes) AUTO_YES=1; shift ;;
    --resume) RESUME=1; shift ;;
    --dry-run) PLAN_LIFECYCLE_DRY_RUN=1; export PLAN_LIFECYCLE_DRY_RUN; shift ;;
    --force-behind) FORCE_BEHIND=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    -*) log "FAILED: unknown option: $1"; usage; exit 1 ;;
    *)
      if [[ -z "${BRANCH}" ]]; then
        BRANCH="$1"
      else
        log "FAILED: unexpected positional argument: $1"
        usage
        exit 1
      fi
      shift ;;
  esac
done

if [[ -z "${BRANCH}" ]]; then
  usage
  exit 1
fi

version_gate || exit 1

PLAN_LIFECYCLE_BRANCH="${BRANCH}"
export PLAN_LIFECYCLE_BRANCH

phase_start
emit_event "start" "begin" 0

# Install signal trap early so Ctrl+C between phases still releases the lock.
trap 'lifecycle_cleanup' INT TERM EXIT

if ! is_main_worktree "${ROOT}"; then
  log "FAILED: run from the main worktree (slot 0)"
  emit_event "worktree_check" "fail" 1
  exit 1
fi

# ---- Resolve base + load session ----------------------------------------
phase_start
worktree_for_branch="$(find_worktree_path_for_branch "${BRANCH}" "${ROOT}")"
SESSION_READY="unknown"
SESSION_PLAN_FILE=""
SESSION_SLOT=""
SESSION_FLUTTER_PORT=""
SESSION_DOCKER_PORT=""
if [[ -n "${worktree_for_branch}" ]] \
   && read_session "${worktree_for_branch}/${PLAN_SESSION_FILE_REL}"; then
  SESSION_READY="$(session_field ready)"
  SESSION_PLAN_FILE="$(session_field plan_file)"
  SESSION_SLOT="$(session_field slot)"
  SESSION_FLUTTER_PORT="$(session_field flutter_port)"
  SESSION_DOCKER_PORT="$(session_field docker_port)"
  if [[ -z "${BASE}" ]]; then
    BASE="$(session_field base)"
  fi
fi
BASE="${BASE:-feat/sprint-1-integration}"

if [[ "${RESUME}" != "1" && "${SESSION_READY}" != "true" && ! is_dry_run ]]; then
  log "FAILED: branch ${BRANCH} is not marked ready:true in .cursor/plan-session.json"
  log "Run plan-worktree-finish.cmd in the per-plan worktree first."
  emit_event "ready_check" "fail" 1
  exit 1
fi
emit_event "session_load" "pass" 0

# ---- Summary + confirmation ---------------------------------------------
patch_notes_n=0
if [[ -n "${SESSION_PLAN_FILE}" && -n "${worktree_for_branch}" ]]; then
  patch_notes_n="$(patch_notes_count "${worktree_for_branch}/${SESSION_PLAN_FILE}")"
fi
changed_files="$(git diff --name-only "origin/${BASE}...${BRANCH}" 2>/dev/null \
              || git diff --name-only "${BASE}...${BRANCH}" 2>/dev/null || true)"

log "Merge summary:"
log "  branch:      ${BRANCH}"
log "  base:        ${BASE}"
log "  slot:        ${SESSION_SLOT:-?}"
log "  ports:       flutter=${SESSION_FLUTTER_PORT:-?} docker=${SESSION_DOCKER_PORT:-?}"
log "  patch notes: ${patch_notes_n}"
log "  changed files vs base:"
if [[ -n "${changed_files}" ]]; then
  echo "${changed_files}" | sed 's/^/    /'
else
  log "    (none — or base ref could not be resolved locally)"
fi

if is_dry_run; then
  dry_run_msg "would acquire integration merge lock"
  dry_run_msg "would run pre-flight (disk / fsck / remote-sync)"
  dry_run_msg "would checkout ${BASE} and pull --ff-only"
  dry_run_msg "would snapshot reflog to /tmp/lifecycle-merge-${BRANCH}-reflog-<ts>.txt"
  dry_run_msg "would git merge --no-ff ${BRANCH}"
  dry_run_msg "would run secret scan + grep guardrails + Tier 1 on integration"
  if (( patch_notes_n > 0 )); then
    dry_run_msg "would prompt for patch-note application (${patch_notes_n} entries)"
  fi
  dry_run_msg "would push origin ${BASE}"
  emit_event "dry_run" "pass" 0
  LIFECYCLE_COMPLETED=1
  exit 0
fi

if [[ "${RESUME}" != "1" ]]; then
  if ! confirm_or_yes "Merge ${BRANCH} into ${BASE}? [y/N]" "${AUTO_YES}"; then
    log "Merge cancelled."
    emit_event "confirm" "cancelled" 0
    LIFECYCLE_COMPLETED=1
    exit 0
  fi
fi

# ---- Acquire lock -------------------------------------------------------
phase_start
LOCK_PATH="${ROOT}/.git/integration-merge.lock"
if ! acquire_lock "${LOCK_PATH}"; then
  emit_event "lock" "fail" 1
  exit 1
fi
emit_event "lock" "acquired" 0

# Any docker started downstream: register a hook so Ctrl+C best-effort tears it
# down. sprint-integrate uses a similar hook.
LIFECYCLE_STARTED_DOCKER=0
register_cleanup_hook '[[ "${LIFECYCLE_STARTED_DOCKER:-0}" == "1" ]] && docker compose down 2>/dev/null || true'

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  log "FAILED: main worktree has uncommitted changes — commit or stash first"
  emit_event "dirty_tree" "fail" 1
  exit 1
fi

# ---- Pre-flight (Phase 8.5) ---------------------------------------------
phase_start
if ! preflight_merge "${BASE}" "${FORCE_BEHIND}"; then
  emit_event "preflight" "fail" 1
  exit 1
fi
emit_event "preflight" "pass" 0

# ---- Checkout + fetch ---------------------------------------------------
phase_start
if git remote get-url origin >/dev/null 2>&1; then
  GIT_TERMINAL_PROMPT=0 timeout 60 git fetch origin "${BASE}" "${BRANCH}" 2>/dev/null || true
fi
if [[ "${RESUME}" != "1" ]]; then
  log "Checking out ${BASE}..."
  git checkout "${BASE}"
  if git show-ref --verify --quiet "refs/remotes/origin/${BASE}"; then
    git pull --ff-only origin "${BASE}" 2>/dev/null \
      || log "WARN: could not ff-only pull origin/${BASE} (offline?)"
  fi
else
  git checkout "${BASE}" 2>/dev/null || true
  log "--resume: skipping merge; re-running validation on ${BASE}"
fi
emit_event "checkout" "pass" 0

# ---- Reflog snapshot (Phase 8.7) ----------------------------------------
if [[ "${RESUME}" != "1" ]]; then
  phase_start
  REFLOG_SNAPSHOT="/tmp/lifecycle-merge-${BRANCH//\//-}-reflog-$(date -u +%s).txt"
  git reflog show "refs/heads/${BASE}" > "${REFLOG_SNAPSHOT}" 2>/dev/null \
    || echo "(no reflog for ${BASE})" > "${REFLOG_SNAPSHOT}"
  log "Reflog snapshot: ${REFLOG_SNAPSHOT}"
  emit_event "reflog_snapshot" "pass" 0
fi

# ---- Merge --------------------------------------------------------------
if [[ "${RESUME}" != "1" ]]; then
  phase_start
  log "git merge --no-ff ${BRANCH} -m \"chore(integration): merge ${BRANCH}\""
  if ! git merge --no-ff "${BRANCH}" -m "chore(integration): merge ${BRANCH}"; then
    log "FAILED: merge conflict on ${BRANCH} -> ${BASE}"
    log "$(rollback_hint merge "${BASE}")"
    emit_event "git_merge" "fail" 1
    exit 1
  fi
  emit_event "git_merge" "pass" 0
fi

# ---- Secret scan on the new merge commit (Phase 8.6) --------------------
phase_start
scan_mode=head_only
[[ "${RESUME}" == "1" ]] && scan_mode=head_only
if ! run_secret_scan "${BASE}" "${scan_mode}"; then
  log "Rolling back merge due to secret findings."
  git reset --hard ORIG_HEAD 2>/dev/null || git merge --abort 2>/dev/null || true
  log "$(rollback_hint merge "${BASE}")"
  emit_event "secret_scan" "fail" 1
  exit 1
fi
emit_event "secret_scan" "pass" 0

# ---- Grep guardrails (parallel-agents.mdc 38-42) ------------------------
phase_start
if ! grep_guardrails "${ROOT}"; then
  log "Rolling back merge due to duplicate entries in forbidden shared files."
  git reset --hard ORIG_HEAD 2>/dev/null || git merge --abort 2>/dev/null || true
  log "$(rollback_hint merge "${BASE}")"
  emit_event "grep_guardrails" "fail" 1
  exit 1
fi
emit_event "grep_guardrails" "pass" 0

# ---- Tier 1 on integration ----------------------------------------------
phase_start
log "Tier 1 on integration (${BASE})..."
if ! flutter_pub_analyze_test; then
  log "FAILED: Tier 1 on integration"
  log "$(rollback_hint merge "${BASE}")"
  emit_event "tier1" "fail" 1
  exit 1
fi
emit_event "tier1" "pass" 0

# ---- Patch notes loop ---------------------------------------------------
if (( patch_notes_n > 0 )) && [[ "${RESUME}" != "1" ]]; then
  phase_start
  log "Serial-merge patch notes (${patch_notes_n}) require parent action on ${BASE}:"
  print_patch_notes "${worktree_for_branch}/${SESSION_PLAN_FILE}" | sed 's/^/  /'
  log ""
  log "Apply the patches on ${BASE} (Lead Developer / parent), commit, then re-run:"
  log "  bash scripts/wsl_plan_worktree_merge.sh ${BRANCH} --resume --yes"
  if ! confirm_or_yes "Applied patch notes and committed? [y/N]" "${AUTO_YES}"; then
    log "Pausing merge. Rerun with --resume once patch notes are applied."
    emit_event "patch_notes" "pending" 0
    LIFECYCLE_COMPLETED=1
    exit 0
  fi
  # Re-validate after patches: Tier 1 + grep guardrails.
  phase_start
  if ! grep_guardrails "${ROOT}"; then
    log "$(rollback_hint merge "${BASE}")"
    emit_event "grep_post_patch" "fail" 1
    exit 1
  fi
  emit_event "grep_post_patch" "pass" 0
  phase_start
  if ! flutter_pub_analyze_test; then
    log "$(rollback_hint merge "${BASE}")"
    emit_event "tier1_post_patch" "fail" 1
    exit 1
  fi
  emit_event "tier1_post_patch" "pass" 0
fi

# ---- Push ---------------------------------------------------------------
phase_start
if git remote get-url origin >/dev/null 2>&1; then
  log "Pushing ${BASE} to origin (best-effort)..."
  if ! git push origin "${BASE}"; then
    log "FAILED: push failed"
    log "$(rollback_hint push)"
    emit_event "push" "fail" 1
    exit 1
  fi
  emit_event "push" "pass" 0
else
  log "No origin remote configured; skipping push"
  emit_event "push" "skip" 0
fi

LIFECYCLE_COMPLETED=1
release_lock

cat <<EOF

================================================================
Integration merge complete

  Merged:   ${BRANCH} -> ${BASE}
  Reflog:   ${REFLOG_SNAPSHOT:-n/a (resume mode)}

Next step (main worktree):

  plan-worktree-cleanup.cmd ${BRANCH}

$(rollback_hint merge "${BASE}")
$(rollback_hint push)

================================================================
EOF
emit_event "done" "pass" 0
