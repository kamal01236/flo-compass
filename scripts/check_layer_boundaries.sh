#!/usr/bin/env bash
# Fail if data/ or core/ import providers/
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0

if rg -q "import '.*providers/" lib/data lib/core 2>/dev/null; then
  echo "ERROR: lib/data or lib/core must not import lib/providers/"
  rg "import '.*providers/" lib/data lib/core || true
  fail=1
fi

if rg -q "import '.*providers/" lib/shared/utils 2>/dev/null; then
  echo "ERROR: lib/shared/utils must not import lib/providers/"
  rg "import '.*providers/" lib/shared/utils || true
  fail=1
fi

if rg -q "import '.*providers/" lib/shared/theme 2>/dev/null; then
  echo "ERROR: lib/shared/theme must not import lib/providers/"
  rg "import '.*providers/" lib/shared/theme || true
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Layer boundary check passed."
