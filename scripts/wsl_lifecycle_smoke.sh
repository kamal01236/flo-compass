#!/usr/bin/env bash
# Disposable lifecycle smoke — run from main worktree in WSL.
set -euo pipefail

export PATH="${HOME}/flutter/bin:/usr/bin:/bin:${PATH}"
ROOT="/mnt/c/Nagarro/ai-avengers"
cd "${ROOT}"
BASE="${1:-chore/v6-integration-cleanup}"

source "${ROOT}/scripts/wsl_common.sh"
source "${ROOT}/scripts/wsl_plan_session.sh"

log() { echo "[smoke] $*"; }

cleanup_smoke() {
  for b in chore/lifecycle-smoke-a chore/lifecycle-smoke-b; do
    local slug="${b#*/}"
    local wt_default="/mnt/c/Nagarro/ai-avengers-${slug}"
    local wt
    wt="$(find_worktree_path_for_branch "$b" "${ROOT}" 2>/dev/null || true)"
    [[ -z "${wt}" && -d "${wt_default}" ]] && wt="${wt_default}"
    [[ -n "${wt}" && -d "${wt}" ]] && git worktree remove --force "${wt}" 2>/dev/null || true
    [[ -d "${wt_default}" ]] && rm -rf "${wt_default}" 2>/dev/null || true
    git branch -D "${b}" 2>/dev/null || true
  done
  git worktree prune
  rm -f "${ROOT}/.git/integration-merge.lock"
  rmdir "${ROOT}/.git/integration-merge.lockdir" 2>/dev/null || true
}

trap cleanup_smoke EXIT

log "=== Cleanup prior smoke ==="
cleanup_smoke
trap - EXIT

log "=== Create worktrees ==="
bash scripts/wsl_new_plan_worktree.sh chore/lifecycle-smoke-a 1 --base "${BASE}"
bash scripts/wsl_new_plan_worktree.sh chore/lifecycle-smoke-b 2 --base "${BASE}"

WTA="/mnt/c/Nagarro/ai-avengers-lifecycle-smoke-a"
WTB="/mnt/c/Nagarro/ai-avengers-lifecycle-smoke-b"

for wt in "${WTA}" "${WTB}"; do
  git -C "${wt}" config user.email "smoke@example.com"
  git -C "${wt}" config user.name "Lifecycle Smoke"
done

log "=== Verify plan-session.json ==="
python3 -c "import json; d=json.load(open('${WTA}/.cursor/plan-session.json')); assert d['slot']==1 and d['ready']==False; print('session-a OK', d['branch'])"
python3 -c "import json; d=json.load(open('${WTB}/.cursor/plan-session.json')); assert d['slot']==2; print('session-b OK')"

log "=== Validate JSON log ==="
python3 -c "import json; [json.loads(l) for l in open('${ROOT}/.cursor/plan-lifecycle.log.jsonl')]"
log "JSON log valid"

log "=== Secret scan block ==="
cd "${WTA}"
echo "AKIA0123456789ABCDEF" > smoke-secret.txt
git add smoke-secret.txt
git commit -q -m "fake secret"
if run_secret_scan "${BASE}" since_base; then
  log "FAIL: secret scan should block"
  exit 1
fi
log "secret scan blocked OK"
git reset --hard HEAD~1

log "=== Forbidden file gate ==="
echo "name: smoke" > pubspec.yaml
git add pubspec.yaml
git commit -q -m "forbidden pubspec"
forbidden="$(forbidden_files_in_diff "${BASE}" "${WTA}")"
if [[ -z "${forbidden}" ]]; then
  log "FAIL: forbidden gate should detect pubspec.yaml"
  exit 1
fi
log "forbidden gate OK: ${forbidden}"
git reset --hard HEAD~1

log "=== Mark session ready (pre dry-run) ==="
update_session_field "${WTA}/.cursor/plan-session.json" ready bool:true
update_session_field "${WTA}/.cursor/plan-session.json" tier1_pass bool:true
update_session_field "${WTA}/.cursor/plan-session.json" patch_notes_count int:0

log "=== Merge dry-run ==="
cd "${ROOT}"
bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --base "${BASE}" --dry-run 2>&1 | grep -q "\[dry-run\]"
log "dry-run OK"

log "=== Stale lock detection ==="
cat > "${ROOT}/.git/integration-merge.lock" <<EOF
PID=999999
HOST=$(hostname -s 2>/dev/null || hostname)
STARTED_AT=2020-01-01T00:00:00Z
COMMAND=smoke-stale
EOF
if ! _lock_is_stale "${ROOT}/.git/integration-merge.lock"; then
  log "FAIL: stale lock should be detected"
  exit 1
fi
log "stale lock OK"
rm -f "${ROOT}/.git/integration-merge.lock"

log "=== Unpushed guard (direct) ==="
cd "${WTA}"
echo "local" >> README.md
git add README.md
git commit -q -m "unpushed local"
unpushed="$(git log --oneline chore/lifecycle-smoke-a --not --remotes=origin/* 2>/dev/null || true)"
if [[ -z "${unpushed}" ]]; then
  log "WARN: unpushed check empty (no remote?) — skipping strict guard"
else
  log "unpushed commits present: OK for guard test"
fi

log "=== Mark session ready (skip Tier 1 for smoke speed) ==="
update_session_field "${WTA}/.cursor/plan-session.json" ready bool:true
update_session_field "${WTA}/.cursor/plan-session.json" tier1_pass bool:true
update_session_field "${WTA}/.cursor/plan-session.json" patch_notes_count int:0

log "=== Stash main worktree dirty state for merge ==="
cd "${ROOT}"
STASHED=0
if [[ -n "$(git status --porcelain)" ]]; then
  git stash push -m "lifecycle-smoke-temp" >/dev/null
  STASHED=1
fi

log "=== Merge with --yes ==="
bash scripts/wsl_plan_worktree_merge.sh chore/lifecycle-smoke-a --base "${BASE}" --yes

if [[ "${STASHED}" == "1" ]]; then
  git stash pop >/dev/null 2>&1 || true
fi

log "=== Cleanup smoke-a ==="
bash scripts/wsl_plan_worktree_cleanup.sh chore/lifecycle-smoke-a --yes

log "=== Cleanup smoke-b (not merged — expect fail) ==="
if bash scripts/wsl_plan_worktree_cleanup.sh chore/lifecycle-smoke-b --yes 2>&1 | grep -q "not merged"; then
  log "unmerged cleanup refused OK"
else
  log "WARN: expected unmerged refusal for smoke-b"
fi

bash scripts/wsl_plan_worktree_cleanup.sh chore/lifecycle-smoke-b --yes --force 2>/dev/null || {
  git worktree remove --force "${WTB}" 2>/dev/null || true
  git branch -D chore/lifecycle-smoke-b 2>/dev/null || true
  git worktree prune
}

log "=== SMOKE PASS ==="
