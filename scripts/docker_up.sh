#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-8080}"
echo "Local Tier 2 smoke (not production ARM deploy): http://localhost:${PORT}"
exec docker compose up --build "$@"
