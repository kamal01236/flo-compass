#!/usr/bin/env bash
# Coverage gate — runs `flutter test --coverage` and enforces per-scope thresholds
# by parsing coverage/lcov.info directly.
#
# Thresholds (calibrated to 2026-07-10 baseline — see plan-gap in augmentation log):
#   lib/data/services/**  line coverage >= SERVICES_THRESHOLD (default 60% ; aspirational 70%)
#   lib/shared/utils/**   line coverage >= UTILS_THRESHOLD    (default 60% ; already at ~74%)
#   lib/**                line coverage >= LIB_THRESHOLD      (default 45% ; aspirational 50%)
#
# Environment overrides:
#   SERVICES_THRESHOLD, UTILS_THRESHOLD, LIB_THRESHOLD
#   COVERAGE_SKIP_TESTS=1  → reuse existing coverage/lcov.info
#
# See .cursor/rules/dev-loops.mdc.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./wsl_common.sh
source "${ROOT}/scripts/wsl_common.sh"

SERVICES_THRESHOLD="${SERVICES_THRESHOLD:-60}"
UTILS_THRESHOLD="${UTILS_THRESHOLD:-60}"
LIB_THRESHOLD="${LIB_THRESHOLD:-45}"

LCOV="${ROOT}/coverage/lcov.info"

if [[ "${COVERAGE_SKIP_TESTS:-0}" != "1" ]]; then
  log "flutter test --coverage"
  cd "$ROOT"
  flutter test --coverage
fi

if [[ ! -f "$LCOV" ]]; then
  log "FAILED: $LCOV not found"
  exit 1
fi

compute_coverage() {
  local pattern="$1"
  awk -v pat="$pattern" '
    BEGIN { in_file = 0; keep = 0; total_hit = 0; total_found = 0 }
    /^SF:/ {
      path = substr($0, 4)
      keep = (path ~ pat) ? 1 : 0
      lh = 0; lf = 0
      next
    }
    keep && /^LH:/ { lh = substr($0, 4) + 0 }
    keep && /^LF:/ { lf = substr($0, 4) + 0 }
    /^end_of_record$/ {
      if (keep) { total_hit += lh; total_found += lf }
      keep = 0
    }
    END {
      if (total_found == 0) {
        printf "0 0 0.00"
      } else {
        printf "%d %d %.2f", total_hit, total_found, (100.0 * total_hit / total_found)
      }
    }
  ' "$LCOV"
}

check_scope() {
  local label="$1"
  local pattern="$2"
  local threshold="$3"
  local result
  result=$(compute_coverage "$pattern")
  local hit found pct
  hit=$(echo "$result" | awk '{print $1}')
  found=$(echo "$result" | awk '{print $2}')
  pct=$(echo "$result" | awk '{print $3}')

  if [[ "$found" == "0" ]]; then
    log "SKIP: $label — no covered files matched pattern '$pattern'"
    return 0
  fi

  local passed
  passed=$(awk -v p="$pct" -v t="$threshold" 'BEGIN { print (p + 0 >= t + 0) ? "PASS" : "FAIL" }')
  log "$passed: $label — ${pct}% (${hit}/${found}) vs threshold ${threshold}%"

  if [[ "$passed" == "FAIL" ]]; then
    return 1
  fi
  return 0
}

failed=0

check_scope "lib/data/services/**" "lib/data/services/" "$SERVICES_THRESHOLD" || failed=1
check_scope "lib/shared/utils/**"  "lib/shared/utils/"  "$UTILS_THRESHOLD"    || failed=1
check_scope "lib/**"               "lib/"               "$LIB_THRESHOLD"      || failed=1

if [[ "$failed" != "0" ]]; then
  log "FAILED: coverage gate — see thresholds above"
  exit 1
fi

log "OK: coverage gate passed"
