#!/usr/bin/env bash
# Backward-compat wrapper for `deploy-local.cmd` / `wsl_run.sh` callers.
# Runs Tier 2 (docker/nginx :8080) and then Tier 1 (Flutter dev :3000) side by side,
# matching the historical behavior of this script. Prefer:
#   - scripts/wsl_dev.sh    (Tier 1 only)
#   - scripts/wsl_deploy.sh (Tier 2 only)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

fast_path() {
  if tier2_ok && url_ok "http://127.0.0.1:${FLUTTER_PORT}/" && boot_test_ok; then
    log "All services already healthy (:${DOCKER_PORT}, :${FLUTTER_PORT}, deep link); skipping build+start"
    return 0
  fi
  return 1
}

main() {
  if fast_path; then
    return 0
  fi

  # Tier 2 does the full pub/analyze/test/build; then start Flutter dev alongside.
  bash "${ROOT}/scripts/wsl_deploy.sh"
  start_flutter_dev true
  wait_for_url "http://127.0.0.1:${FLUTTER_PORT}/" 120 || true

  echo ""
  echo "========================================"
  echo "Flo Compass is running in WSL"
  echo "Flutter dev:  http://localhost:${FLUTTER_PORT}"
  echo "Docker/nginx: http://localhost:${DOCKER_PORT}"
  echo "Deep link:    http://localhost:${DOCKER_PORT}/session/s-001"
  echo "Directions:   http://localhost:${DOCKER_PORT}/directions?session=s-001"
  echo "========================================"
  echo ""
  if [[ -f /tmp/flo-compass-flutter.pid ]]; then
    echo "Flutter PID: $(cat /tmp/flo-compass-flutter.pid)"
  fi
}

main "$@"
