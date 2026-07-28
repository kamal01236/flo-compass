#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=== Installing Linux packages ==="
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl git unzip xz-utils zip ca-certificates \
  libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

FLUTTER_DIR="${HOME}/flutter"
if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  echo "=== Installing Flutter (stable) to ${FLUTTER_DIR} ==="
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

echo "=== Flutter version ==="
flutter --version

echo "=== Flutter doctor (summary) ==="
flutter doctor

echo "=== Docker group (Tier 2 nginx) ==="
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "Docker: ready"
  elif id -nG "$USER" 2>/dev/null | grep -qw docker; then
    echo "Docker: in docker group — run 'newgrp docker' or re-open WSL"
  else
    echo "Docker: add user to group — sudo usermod -aG docker \"\$USER\" && newgrp docker"
  fi
else
  echo "Docker: not installed (SPA python fallback will be used on :8080)"
fi

echo "=== Enabling web ==="
flutter config --enable-web

echo "=== Setup complete ==="
