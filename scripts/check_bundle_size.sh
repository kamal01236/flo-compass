#!/usr/bin/env bash
# Soft gate: warn if main.dart.js gzipped size exceeds threshold (default 3 MB).
set -euo pipefail

THRESHOLD_MB="${BUNDLE_SIZE_THRESHOLD_MB:-3}"
BUILD_DIR="${1:-build/web}"

if [[ ! -f "$BUILD_DIR/main.dart.js" ]]; then
  echo "[check_bundle_size] main.dart.js not found — run flutter build web --release first"
  exit 0
fi

SIZE_BYTES=$(gzip -c "$BUILD_DIR/main.dart.js" | wc -c | tr -d ' ')
THRESHOLD_BYTES=$((THRESHOLD_MB * 1024 * 1024))

echo "[check_bundle_size] main.dart.js gzipped: ${SIZE_BYTES} bytes (threshold ${THRESHOLD_BYTES})"

if (( SIZE_BYTES > THRESHOLD_BYTES )); then
  echo "[check_bundle_size] WARN: bundle exceeds ${THRESHOLD_MB} MB gzipped — consider deferred imports (see docs/plans/backlog/deferred-imports-bundle-split.md)"
  exit 0
fi

echo "[check_bundle_size] OK"
