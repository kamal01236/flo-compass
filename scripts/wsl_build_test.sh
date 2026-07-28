#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/flutter/bin:${PATH}"

echo "=== flutter pub get ==="
flutter pub get

echo "=== validate flo data ==="
dart run tools/validate_flo_data.dart

echo "=== flutter analyze ==="
flutter analyze

echo "=== dart format check ==="
dart format --set-exit-if-changed .

echo "=== flutter test ==="
flutter test

echo "=== flutter build web ==="
flutter build web --release

echo "=== Build complete ==="
