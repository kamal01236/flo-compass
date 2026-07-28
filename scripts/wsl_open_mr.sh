#!/usr/bin/env bash
# Idempotent GitHub pull request opener for the current branch.
# Prefers `gh` when authenticated; falls back to printing a create URL.
# See scripts/README.md and .cursor/rules/ship-branch.mdc.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

SCRIPT_VERSION="2.0.0"
MR_TARGET="${MR_TARGET:-main}"
MR_TITLE=""
DRAFT=0
AUTO_YES=0
SKIP_PUSH=0

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_open_mr.sh [options]

Open a GitHub pull request for the current branch (idempotent).

Options:
  --target <branch>   Target branch (default: main, or MR_TARGET env)
  --title <text>      PR title (default: last commit subject)
  --draft             Create as draft PR (gh only)
  --skip-push         Assume branch is already on origin (ship-branch sets this after push)
  --yes               Non-interactive
  -h, --help          Show this help
  --version           Show script version

Env:
  MR_TARGET           Default target branch (main)

One-time gh setup:
  gh auth login   # never commit credentials

Example:
  MR_TARGET=feat/sprint-1-integration bash scripts/wsl_open_mr.sh
EOF
}

print_script_version() {
  local ver="$1"
  local tree_sha
  tree_sha="$(git -C "${ROOT}" log -1 --format=%h scripts/ 2>/dev/null || echo unknown)"
  echo "wsl_open_mr.sh ${ver} (scripts@${tree_sha})"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || { log "FAILED: --target requires a value"; exit 1; }
      MR_TARGET="$2"
      shift 2
      ;;
    --title)
      [[ $# -ge 2 ]] || { log "FAILED: --title requires a value"; exit 1; }
      MR_TITLE="$2"
      shift 2
      ;;
    --draft) DRAFT=1; shift ;;
    --skip-push) SKIP_PUSH=1; shift ;;
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

branch="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "${branch}" ]]; then
  log "FAILED: detached HEAD — checkout a branch first"
  exit 1
fi

default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"
}

origin_default="$(default_branch)"
if [[ "${branch}" == "main" || "${branch}" == "${origin_default}" || "${branch}" == "${MR_TARGET}" ]]; then
  log "FAILED: refuse to open PR from default or target branch (${branch})"
  exit 1
fi

if [[ -z "${MR_TITLE}" ]]; then
  MR_TITLE="$(git log -1 --format='%s')"
fi

build_pr_body() {
  local plan_file=""
  if [[ -f "${ROOT}/.cursor/plan-session.json" ]]; then
    plan_file="$(grep -o '"plan_file"[[:space:]]*:[[:space:]]*"[^"]*"' "${ROOT}/.cursor/plan-session.json" \
      | head -1 | sed 's/.*: *"\([^"]*\)"/\1/' || true)"
  fi
  cat <<EOF
## Branch: ${branch}

Target: \`${MR_TARGET}\`

### Commits

\`\`\`
$(git log "origin/${MR_TARGET}..HEAD" --oneline 2>/dev/null \
  || git log "${MR_TARGET}..HEAD" --oneline 2>/dev/null \
  || git log -5 --oneline)
\`\`\`

### Plan

${plan_file:-Add plan file path in PR description if applicable.}
EOF
}

gh_available() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

open_pr_with_gh() {
  local existing
  existing="$(gh pr list --head "${branch}" --state open --json number -q '.[0].number' 2>/dev/null || true)"
  if [[ -n "${existing}" ]]; then
    log "Open PR already exists for ${branch}: #${existing}"
    gh pr view "${existing}" --web 2>/dev/null || gh pr view "${existing}" || true
    return 0
  fi

  local draft_args=()
  if [[ "${DRAFT}" == "1" ]]; then
    draft_args=(--draft)
  fi

  log "Creating PR via gh: ${branch} → ${MR_TARGET}"
  gh pr create \
    --base "${MR_TARGET}" \
    --head "${branch}" \
    --title "${MR_TITLE}" \
    --body "$(build_pr_body)" \
    "${draft_args[@]}"
  gh pr view --web 2>/dev/null || true
}

print_manual_pr_hint() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || echo '')"
  log "gh not available — push completed; open a PR manually:"
  log "  gh auth login && gh pr create --base ${MR_TARGET} --head ${branch}"
  if [[ "${remote_url}" == *github.com* ]]; then
    log "  Or use the GitHub UI for ${remote_url}"
  fi
}

ensure_remote() {
  if ! git remote get-url origin >/dev/null 2>&1; then
    log "FAILED: no origin remote configured"
    exit 1
  fi
}

push_branch() {
  if [[ "${SKIP_PUSH}" == "1" ]]; then
    return 0
  fi
  log "Pushing ${branch} to origin..."
  git push -u origin "${branch}"
}

main() {
  ensure_remote
  push_branch

  if gh_available; then
    open_pr_with_gh
  else
    if [[ "${SKIP_PUSH}" == "1" ]]; then
      log "WARN: gh not available; cannot create PR after push-only flow"
      log "Install: https://cli.github.com/ — then: gh auth login"
      exit 1
    fi
    print_manual_pr_hint
  fi

  log "PR flow complete for ${branch} → ${MR_TARGET}"
}

main "$@"
