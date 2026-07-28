#!/usr/bin/env bash
# Tier 2 — Pre-push local deploy: full Tier 1 + build web + docker/nginx :8080 +
# deep-link smoke + coverage gate. Leaves Docker running for manual smoke.
# See .cursor/rules/dev-loops.mdc and .cursor/rules/local-wsl-auto-validation.mdc.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

if [[ -f "${ROOT}/.worktree.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT}/.worktree.env"
fi

main() {
  install_flutter
  prepare_flutter
  flutter_pub_analyze_test
  boot_test_ok

  TEARDOWN=0 bash "${ROOT}/scripts/wsl_tier2_smoke.sh"
}

main "$@"
