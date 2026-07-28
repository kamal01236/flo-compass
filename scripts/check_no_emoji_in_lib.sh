#!/usr/bin/env bash
# Fail if lib/ string literals contain emoji or symbol-plane chars that trigger Noto downloads.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v rg >/dev/null 2>&1; then
  echo "[check_no_emoji_in_lib] FAILED: ripgrep (rg) is required"
  exit 1
fi

matches="$(rg -n "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]" lib/ --glob '*.dart' || true)"
if [[ -n "${matches}" ]]; then
  echo "[check_no_emoji_in_lib] FAILED: emoji/symbol Unicode found in lib/:"
  echo "${matches}"
  exit 1
fi

echo "[check_no_emoji_in_lib] OK: no emoji/symbol-plane Unicode in lib/"
