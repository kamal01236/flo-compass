#!/usr/bin/env bash
# Backward-compat alias for scripts/wsl_dev.sh (Tier 1 dev loop).
# Preferred entry point: scripts/wsl_dev.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "${ROOT}/scripts/wsl_dev.sh" "$@"
