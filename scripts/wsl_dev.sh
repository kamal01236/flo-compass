#!/usr/bin/env bash
# Tier 1 — Flutter dev loop only (analyze + test + dev server on :3000).
# No docker, no build web. Target: < 90s cold, < 15s warm.
# See .cursor/rules/dev-loops.mdc and .cursor/rules/local-wsl-auto-validation.mdc.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

main() {
  install_flutter
  prepare_flutter
  flutter_pub_analyze_test
  boot_test_ok
  start_flutter_dev true
  wait_for_url "http://127.0.0.1:${FLUTTER_PORT}/" 60 || true

  echo ""
  echo "========================================"
  echo "Flo Compass dev (Tier 1) is running"
  echo "Flutter dev:  http://localhost:${FLUTTER_PORT}"
  echo "Stop:         wsl -e bash -lc \"fuser -k ${FLUTTER_PORT}/tcp\""
  echo "========================================"
  echo ""
  if [[ -f /tmp/flo-compass-flutter.pid ]]; then
    echo "Flutter PID: $(cat /tmp/flo-compass-flutter.pid)"
  fi
}

main "$@"
