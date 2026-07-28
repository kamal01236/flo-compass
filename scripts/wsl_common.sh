#!/usr/bin/env bash
# Shared helpers for wsl_dev.sh, wsl_deploy.sh, and legacy wsl_bootstrap_and_run.sh.
# Source, do not execute.

set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT"

export PATH="${HOME}/flutter/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"
FLUTTER_PORT="${FLUTTER_PORT:-3000}"
DOCKER_PORT="${DOCKER_PORT:-8080}"

log() { echo "[wsl] $*"; }

port_bound() {
  ss -ltn 2>/dev/null | grep -q ":$1 "
}

url_ok() {
  curl -fsS -o /dev/null -m 3 "$1" 2>/dev/null
}

wait_for_url() {
  local url="$1"
  local attempts="${2:-60}"
  local i
  for ((i=1; i<=attempts; i++)); do
    if curl -fsS -o /dev/null -m 5 "$url"; then
      log "OK: $url"
      return 0
    fi
    sleep 2
  done
  log "FAILED: $url"
  return 1
}

tier2_ok() {
  url_ok "http://127.0.0.1:${DOCKER_PORT}/" \
    && url_ok "http://127.0.0.1:${DOCKER_PORT}/session/s-001" \
    && url_ok "http://127.0.0.1:${DOCKER_PORT}/directions?session=s-001" \
    && url_ok "http://127.0.0.1:${DOCKER_PORT}/main.dart.js"
}

verify_web_bootstrap() {
  local bootstrap="${ROOT}/build/web/flutter_bootstrap.js"
  if [[ ! -f "${bootstrap}" ]]; then
    log "FAILED: missing ${bootstrap}"
    return 1
  fi
  local tail_line
  tail_line="$(tail -1 "${bootstrap}")"
  if ! echo "${tail_line}" | grep -q '_flutter.loader.load();'; then
    log "FAILED: ${bootstrap} tail is not _flutter.loader.load(); (unexpected bootstrap patch)"
    return 1
  fi
  if echo "${tail_line}" | grep -q 'fontFallbackBaseUrl'; then
    log "FAILED: ${bootstrap} still sets fontFallbackBaseUrl"
    return 1
  fi
  if echo "${tail_line}" | grep -q 'serviceWorkerSettings'; then
    log "FAILED: ${bootstrap} registers a service worker (use --pwa-strategy=none)"
    return 1
  fi
  if ! grep -q '"useLocalCanvasKit":true' "${bootstrap}"; then
    log "FAILED: ${bootstrap} does not set useLocalCanvasKit (use --no-web-resources-cdn)"
    return 1
  fi
  log "OK: web bootstrap has no service worker registration"
}

verify_security_headers() {
  local path header
  for path in "/" "/session/s-001" "/main.dart.js"; do
    header="$(curl -sI "http://127.0.0.1:${DOCKER_PORT}${path}")"
    if ! echo "${header}" | grep -qi 'X-Frame-Options:.*DENY'; then
      log "FAILED: missing X-Frame-Options on ${path}"
      return 1
    fi
    if ! echo "${header}" | grep -qi 'Content-Security-Policy:'; then
      log "FAILED: missing Content-Security-Policy on ${path}"
      return 1
    fi
    log "OK: security headers on ${path}"
  done
}

verify_served_bootstrap() {
  local served
  served="$(curl -fsS "http://127.0.0.1:${DOCKER_PORT}/flutter_bootstrap.js")"
  if echo "${served}" | tail -1 | grep -q 'serviceWorkerSettings'; then
    log "FAILED: served flutter_bootstrap.js registers a service worker"
    return 1
  fi
  if ! echo "${served}" | grep -q '"useLocalCanvasKit":true'; then
    log "FAILED: served flutter_bootstrap.js does not set useLocalCanvasKit (use --no-web-resources-cdn)"
    return 1
  fi
  if ! echo "${served}" | tail -1 | grep -q '_flutter.loader.load();'; then
    log "FAILED: served flutter_bootstrap.js tail is not _flutter.loader.load();"
    return 1
  fi
  if echo "${served}" | tail -1 | grep -q 'fontFallbackBaseUrl'; then
    log "FAILED: served flutter_bootstrap.js still sets fontFallbackBaseUrl"
    return 1
  fi
  log "OK: served flutter_bootstrap.js has no service worker registration"
  verify_security_headers
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/canvaskit/canvaskit.js" 30
  wait_for_url "http://127.0.0.1:${DOCKER_PORT}/shell.js" 30
}

boot_test_ok() {
  log "Running app boot test gate (test/app_boot_test.dart)"
  flutter test test/app_boot_test.dart
}

stop_port() {
  local port="$1"
  local flutter_pid_file="/tmp/flo-compass-flutter-${FLUTTER_PORT:-3000}.pid"
  fuser -k "${port}/tcp" 2>/dev/null || true
  if [[ "${port}" == "${FLUTTER_PORT}" && -f "${flutter_pid_file}" ]]; then
    kill "$(cat "${flutter_pid_file}")" 2>/dev/null || true
    rm -f "${flutter_pid_file}"
  fi
  sleep 1
}

selfheal_crlf() {
  # Windows autocrlf sometimes corrupts these; strip \r once before executing.
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && sed -i 's/\r$//' "$f" 2>/dev/null || true
  done
}

install_flutter() {
  if [[ -x "${HOME}/flutter/bin/flutter" ]]; then
    log "Flutter already installed"
    return 0
  fi
  log "Installing Flutter stable to ${HOME}/flutter"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${HOME}/flutter"
}

prepare_flutter() {
  flutter --version
  flutter config --enable-web
  flutter precache --web
}

flutter_build_web_release() {
  log "checking lib/ for emoji/symbol-plane Unicode triggers"
  bash "${ROOT}/scripts/check_no_emoji_in_lib.sh"
  # Clear .dart_tool/flutter_build so entrypoint package name matches pubspec
  # (e.g. after starter_kit → flo_compass rename).
  log "flutter clean (release web — drop stale build cache)"
  flutter clean
  log "flutter pub get"
  flutter pub get
  log "flutter build web --release --pwa-strategy=none --no-web-resources-cdn --no-wasm-dry-run"
  flutter build web --release --pwa-strategy=none --no-web-resources-cdn --no-wasm-dry-run
  verify_web_bootstrap
}

flutter_pub_analyze_test() {
  log "flutter pub get"
  flutter pub get
  log "flutter analyze"
  flutter analyze --no-fatal-infos --no-fatal-warnings
  log "flutter test"
  flutter test
}

start_flutter_dev() {
  local force_restart="${1:-false}"
  if port_bound "${FLUTTER_PORT}"; then
    if [[ "${force_restart}" == "true" ]]; then
      log "Restarting Flutter dev after rebuild"
      stop_port "${FLUTTER_PORT}"
    elif url_ok "http://127.0.0.1:${FLUTTER_PORT}/"; then
      log "Flutter dev port ${FLUTTER_PORT} already healthy; skipping"
      return 0
    else
      log "Flutter dev port ${FLUTTER_PORT} unhealthy; restarting"
      stop_port "${FLUTTER_PORT}"
    fi
  fi
  local flutter_log_file="/tmp/flo-compass-flutter-${FLUTTER_PORT:-3000}.log"
  local flutter_pid_file="/tmp/flo-compass-flutter-${FLUTTER_PORT:-3000}.pid"
  log "Starting Flutter dev server on port ${FLUTTER_PORT}"
  nohup flutter run -d web-server \
    --web-port="${FLUTTER_PORT}" \
    --web-hostname=0.0.0.0 \
    > "${flutter_log_file}" 2>&1 &
  echo $! > "${flutter_pid_file}"
}

docker_available() {
  docker info >/dev/null 2>&1
}

docker_run() {
  if docker_available; then
    docker "$@"
    return $?
  fi
  if id -nG "$USER" 2>/dev/null | grep -qw docker && command -v sg >/dev/null; then
    sg docker -c "docker $*"
    return $?
  fi
  return 1
}
