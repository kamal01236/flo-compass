#!/usr/bin/env bash
# Verify route string literals in app_router match AppRoutes constants.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ROUTER="lib/routing/app_router.dart"
ROUTES="lib/core/routing/app_routes.dart"

fail=0

check_path() {
  local const="$1"
  if ! grep -q "path: $const" "$ROUTER"; then
    echo "ERROR: $ROUTER missing path: $const"
    fail=1
  fi
}

check_path "AppRoutes.discover"
check_path "AppRoutes.companion"
check_path "AppRoutes.myPlan"
check_path "AppRoutes.profile"
check_path "AppRoutes.onboarding"
check_path "AppRoutes.map"
check_path "AppRoutes.directions"
check_path "AppRoutes.recap"
check_path "AppRoutes.bingo"
check_path "AppRoutes.leaderboard"
check_path "AppRoutes.qr"
check_path "AppRoutes.planImport"

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Route constants check passed."
