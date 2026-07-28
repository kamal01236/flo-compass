#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="${HOME}/flutter/bin:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"
FLUTTER_PORT="${FLUTTER_PORT:-3000}"

docker pull nginx:alpine
docker compose up --build -d

if ! ss -ltn 2>/dev/null | grep -q ":${FLUTTER_PORT} "; then
  nohup flutter run -d web-server --web-port="${FLUTTER_PORT}" --web-hostname=0.0.0.0 > /tmp/flo-compass-flutter.log 2>&1 &
  echo $! > /tmp/flo-compass-flutter.pid
fi

for i in $(seq 1 90); do
  curl -fsS -o /dev/null -m 5 http://127.0.0.1:8080/ && break
  sleep 2
done
for i in $(seq 1 90); do
  curl -fsS -o /dev/null -m 5 http://127.0.0.1:${FLUTTER_PORT}/ && break
  sleep 2
done

echo "Flutter dev:  http://localhost:${FLUTTER_PORT}"
echo "Docker/nginx: http://localhost:8080"
docker compose ps
