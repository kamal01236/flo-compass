#!/usr/bin/env bash
# Idempotent GitLab merge request opener for the current branch.
# Prefers glab when authenticated; falls back to git push merge-request options.
# See scripts/README.md and .cursor/rules/ship-branch.mdc.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

SCRIPT_VERSION="1.0.0"
MR_TARGET="${MR_TARGET:-main}"
MR_TITLE=""
DRAFT=0
AUTO_YES=0
SKIP_PUSH=0

usage() {
  cat <<'EOF'
Usage: bash scripts/wsl_open_mr.sh [options]

Open a GitLab merge request for the current branch (idempotent).

Options:
  --target <branch>   Target branch (default: main, or MR_TARGET env)
  --title <text>      MR title (default: last commit subject)
  --draft             Create as draft MR (glab only)
  --skip-push         Assume branch is already on origin (ship-branch sets this after push)
  --yes               Non-interactive
  -h, --help          Show this help
  --version           Show script version

Env:
  MR_TARGET           Default target branch (main)

One-time glab setup:
  glab auth login   # token via env; never commit credentials

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
  log "FAILED: refuse to open MR from default or target branch (${branch})"
  exit 1
fi

if [[ -z "${MR_TITLE}" ]]; then
  MR_TITLE="$(git log -1 --format='%s')"
fi

build_mr_description() {
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

${plan_file:-Add plan file path in MR description if applicable.}
EOF
}

glab_available() {
  command -v glab >/dev/null 2>&1 && glab auth status >/dev/null 2>&1
}

open_mr_with_glab() {
  local existing
  existing="$(glab mr list --source-branch "${branch}" --state opened -F json 2>/dev/null || echo '[]')"
  if [[ "${existing}" != "[]" && "${existing}" != "" && "${existing}" != "null" ]]; then
    log "Open MR already exists for ${branch}"
    glab mr list --source-branch "${branch}" --state opened || true
    local iid
    iid="$(glab mr list --source-branch "${branch}" --state opened -F json 2>/dev/null \
      | grep -o '"iid":[0-9]*' | head -1 | cut -d: -f2 || true)"
    if [[ -n "${iid}" ]]; then
      glab mr view "${iid}" --web 2>/dev/null || true
    fi
    return 0
  fi

  if [[ "${DRAFT}" == "1" ]]; then
    draft_flag=(--draft)
  fi

  log "Creating MR via glab: ${branch} → ${MR_TARGET}"
  glab mr create \
    --target-branch "${MR_TARGET}" \
    --title "${MR_TITLE}" \
    --description "$(build_mr_description)" \
    "${draft_flag[@]}"
  glab mr view --web 2>/dev/null || true
}

open_mr_with_push_options() {
  if [[ "${SKIP_PUSH}" == "1" ]]; then
    log "FAILED: --skip-push requires glab; install and authenticate glab or omit --skip-push"
    exit 1
  fi
  log "Creating MR via git push options: ${branch} → ${MR_TARGET}"
  git push -u origin HEAD \
    -o merge_request.create \
    -o "merge_request.target=${MR_TARGET}" \
    -o "merge_request.title=${MR_TITLE}"
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

  if glab_available; then
    open_mr_with_glab
  else
    if [[ "${SKIP_PUSH}" == "1" ]]; then
      log "WARN: glab not available; cannot create MR after push-only flow"
      log "Install glab: https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation.md"
      log "Then: glab auth login"
      exit 1
    fi
    open_mr_with_push_options
  fi

  log "MR flow complete for ${branch} → ${MR_TARGET}"
}

main "$@"
