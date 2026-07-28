#!/usr/bin/env bash
set -euo pipefail
flutter pub get
dart run tools/validate_flo_data.dart
flutter analyze
bash scripts/check_layer_boundaries.sh
bash scripts/check_route_constants.sh
dart format --set-exit-if-changed .
flutter test
bash scripts/check_bundle_size.sh build/web 2>/dev/null || true
