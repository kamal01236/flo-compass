#!/usr/bin/env bash
# Ship branch — Tier 1 + Tier 2 smoke (teardown) + push + idempotent GitLab MR.
# Explicit pre-review command; not run on every commit.
# See .cursor/rules/ship-branch.mdc and scripts/README.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

SCRIPT_VERSION="1.0.0"
DRY_RUN=0
ALLOW_DIRTY=0
SKIP_TIER2=0
SKIP_MR=0
AUTO_YES=0

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_ship_branch.sh [options]

Gates (in order):
  1. Branch guard (not main / default)
  2. Clean git tree (unless --allow-dirty)
  3. Tier 1 (flutter pub get && analyze && test + boot test)
  4. Tier 2 smoke with teardown (unless --no-tier2)
  5. git push -u origin <branch>
  6. Open GitLab MR to main if none exists (unless --no-mr)

Options:
  --dry-run         Print planned steps without flutter/docker/push/MR
  --no-tier2        Tier 1 + push + MR only
  --no-mr           Push only; skip MR creation
  --allow-dirty     Allow uncommitted changes (emergency only)
  --yes             Non-interactive
  -h, --help        Show this help
  --version         Show script version

Env:
  MR_TARGET         MR target branch (default: main)
  DOCKER_PORT       From .worktree.env when present, else 8080
  FLUTTER_PORT      From .worktree.env when present, else 3000

Example:
  bash scripts/wsl_ship_branch.sh --dry-run
  MR_TARGET=feat/sprint-1-integration bash scripts/wsl_ship_branch.sh
EOF
}

print_script_version() {
  local ver="$1"
  local tree_sha
  tree_sha="$(git -C "${ROOT}" log -1 --format=%h scripts/ 2>/dev/null || echo unknown)"
  echo "wsl_ship_branch.sh ${ver} (scripts@${tree_sha})"
}

dry_step() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] $*"
    return 0
  fi
  "$@"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --no-tier2) SKIP_TIER2=1; shift ;;
    --no-mr) SKIP_MR=1; shift ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    --yes) AUTO_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --version) print_script_version "${SCRIPT_VERSION}"; exit 0 ;;
    *)
      log "FAILED: unexpected argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -f "${ROOT}/.worktree.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT}/.worktree.env"
fi

default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
}

branch_guard() {
  local branch default_br
  branch="$(git branch --show-current 2>/dev/null || true)"
  default_br="$(default_branch)"
  if [[ -z "${branch}" ]]; then
    log "FAILED: detached HEAD"
    exit 1
  fi
  if [[ "${branch}" == "main" || "${branch}" == "${default_br}" ]]; then
    log "FAILED: ship-branch must run from a feature branch, not ${branch}"
    exit 1
  fi
  log "Shipping branch: ${branch}"
}

clean_tree_guard() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] skipping clean-tree check"
    return 0
  fi
  if [[ "${ALLOW_DIRTY}" == "1" ]]; then
    log "WARN: --allow-dirty — skipping clean-tree check"
    return 0
  fi
  local dirty
  dirty="$(git status --porcelain || true)"
  if [[ -n "${dirty}" ]]; then
    log "FAILED: uncommitted changes — commit or stash before ship-branch"
    git status --short
    exit 1
  fi
}

run_tier1() {
  log "Tier 1 (flutter pub get && analyze && test)..."
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] install_flutter && prepare_flutter && flutter_pub_analyze_test && boot_test_ok"
    return 0
  fi
  install_flutter
  prepare_flutter
  flutter_pub_analyze_test
  boot_test_ok
}

run_tier2_smoke() {
  log "Tier 2 smoke (build + docker + deep links + coverage, teardown)..."
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] TEARDOWN=1 bash scripts/wsl_tier2_smoke.sh"
    return 0
  fi
  TEARDOWN=1 bash "${ROOT}/scripts/wsl_tier2_smoke.sh"
}

run_push() {
  local branch
  branch="$(git branch --show-current)"
  if ! git remote get-url origin >/dev/null 2>&1; then
    log "FAILED: no origin remote configured"
    exit 1
  fi
  dry_step git push -u origin "${branch}"
}

run_open_mr() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] bash scripts/wsl_open_mr.sh --skip-push"
    return 0
  fi
  bash "${ROOT}/scripts/wsl_open_mr.sh" --skip-push ${AUTO_YES:+--yes}
}

main() {
  branch_guard
  clean_tree_guard
  run_tier1

  if [[ "${SKIP_TIER2}" == "0" ]]; then
    run_tier2_smoke
  elif [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] skipping Tier 2 (--no-tier2)"
  fi

  run_push

  if [[ "${SKIP_MR}" == "0" ]]; then
    run_open_mr
  elif [[ "${DRY_RUN}" == "1" ]]; then
    log "[dry-run] skipping MR (--no-mr)"
  fi

  echo ""
  echo "========================================"
  echo "Ship branch complete"
  echo "  Branch: $(git branch --show-current)"
  echo "  MR target: ${MR_TARGET:-main}"
  if [[ "${SKIP_TIER2}" == "1" ]]; then
    echo "  Tier 2: skipped"
  fi
  if [[ "${SKIP_MR}" == "1" ]]; then
    echo "  MR: skipped"
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    echo "  Mode: dry-run (no side effects)"
  fi
  echo "========================================"
  echo ""
}

main "$@"
