#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== PHP =="
docker compose exec -T php-lab php -v | head -1
docker compose exec -T php-lab php -r \
  'echo "session.upload_progress.enabled=", ini_get("session.upload_progress.enabled"), PHP_EOL;'

echo
echo "== Node.js =="
docker compose exec -T node-lab node -p \
  "process.version + ' / brotli ' + process.versions.brotli"
echo "-- dependencias con brotli:"
docker compose exec -T node-lab npm ls --all 2>/dev/null | grep -i brotli \
  || echo "   (sin paquete brotli externo: lo aporta el runtime)"

echo
echo "== Python =="
docker compose exec -T py-lab python -c \
  "import sys, brotli; print('python', sys.version.split()[0]); print('brotli', getattr(brotli, '__version__', 'desconocida'))"
