#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Controles declarados en el compose =="
docker compose config | grep -E 'read_only|cap_drop|mem_limit|internal' || true

echo
echo "== Prueba de salida a Internet (debe fallar) =="

echo "-- PHP:"
docker compose exec -T php-lab php -r '
$ctx = stream_context_create(["http" => ["timeout" => 3]]);
$r = @file_get_contents("http://example.com", false, $ctx);
echo $r ? "SALIDA OK\n" : "SIN SALIDA\n";
' || true

echo "-- Node.js:"
docker compose exec -T node-lab node -e '
fetch("https://example.com", { signal: AbortSignal.timeout(3000) })
  .then(r => console.log("SALIDA OK", r.status))
  .catch(e => console.log("SIN SALIDA", e.name));
' || true

echo "-- Python:"
docker compose exec -T py-lab python -c '
import urllib.request
try:
    urllib.request.urlopen("https://example.com", timeout=3)
    print("SALIDA OK")
except Exception as e:
    print("SIN SALIDA", type(e).__name__)
' || true
