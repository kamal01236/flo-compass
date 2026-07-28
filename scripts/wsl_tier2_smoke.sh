#!/usr/bin/env bash
# Tier 2 smoke — build web, docker/nginx, deep-link verification, coverage gate.
# Shared by wsl_deploy.sh (leave container running) and wsl_ship_branch.sh (teardown).
# See .cursor/rules/dev-loops.mdc and scripts/wsl_ship_branch.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

TEARDOWN="${TEARDOWN:-0}"
CONNECT_SAMPLE_TOKEN="${CONNECT_SAMPLE_TOKEN:-abc123}"

if [[ -f "${ROOT}/.worktree.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT}/.worktree.env"
fi

tier2_teardown() {
  log "Tearing down Docker/nginx on port ${DOCKER_PORT}"
  docker_run compose down 2>/dev/null || true
  stop_port "${DOCKER_PORT}"
}

if [[ "${TEARDOWN}" == "1" ]]; then
  trap 'tier2_teardown' EXIT
fi

docker_compose_up() {
  if ! docker_run info >/dev/null 2>&1; then
    log "FAILED: Docker daemon not reachable"
    log "Fix: sudo usermod -aG docker \"\$USER\" && newgrp docker"
    log "     Then verify: docker ps"
    exit 1
  fi

  if [[ ! -f "${ROOT}/build/web/main.dart.js" ]]; then
    log "FAILED: missing ${ROOT}/build/web/main.dart.js — run flutter_build_web_release first"
    exit 1
  fi

  if port_bound "${DOCKER_PORT}"; then
    log "Port ${DOCKER_PORT} bound; stopping any existing container/process"
    stop_port "${DOCKER_PORT}"
    docker_run compose down 2>/dev/null || true
  fi

  log "Starting Docker/nginx on port ${DOCKER_PORT} (prebuilt build/web via docker/Dockerfile.local)"
  docker_run pull nginx:alpine >/dev/null 2>&1 || true
  docker_run compose up --build -d
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/main.dart.js" 120
}

verify_tier2() {
  log "Verifying Tier 2 deep links"
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/flutter_bootstrap.js" 30
  verify_served_bootstrap
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/" 60
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/session/s-001" 30
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/directions?session=s-001" 30
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/connect/${CONNECT_SAMPLE_TOKEN}" 30
}

run_coverage_gate() {
  if [[ -x "${ROOT}/scripts/wsl_coverage.sh" ]]; then
    log "Running coverage gate (scripts/wsl_coverage.sh)"
    bash "${ROOT}/scripts/wsl_coverage.sh" || {
      log "FAILED: coverage gate did not meet thresholds"
      exit 1
    }
  else
    log "Skipping coverage gate — scripts/wsl_coverage.sh not present"
  fi
}

main() {
  install_flutter
  prepare_flutter
  flutter_build_web_release

  docker_compose_up
  verify_tier2
  run_coverage_gate

  if [[ "${TEARDOWN}" == "1" ]]; then
    tier2_teardown
    trap - EXIT
    log "Tier 2 smoke complete (docker torn down)"
  else
    echo ""
    echo "========================================"
    echo "Flo Compass Tier 2 smoke is running"
    echo "Docker/nginx: http://localhost:${DOCKER_PORT}"
    echo "Deep link:    http://localhost:${DOCKER_PORT}/session/s-001"
    echo "Directions:   http://localhost:${DOCKER_PORT}/directions?session=s-001"
    echo "Connect:      http://localhost:${DOCKER_PORT}/connect/${CONNECT_SAMPLE_TOKEN}"
    echo "Stop:         wsl -e bash -lc \"docker compose down; fuser -k ${DOCKER_PORT}/tcp\""
    echo "========================================"
    echo ""
    docker_run compose ps 2>/dev/null || true
  fi
}

main "$@"
