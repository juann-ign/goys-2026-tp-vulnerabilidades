#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Las variables de entorno de la línea de comandos tienen prioridad sobre
# versions.env. Se recrean las imágenes con las versiones corregidas.
PHP_TAG=8.3.36-apache \
NODE_TAG=22.23.4-bookworm-slim \
BROTLI_VERSION=1.2.1 \
  docker compose --env-file versions.env up -d --build

echo
echo "== Versiones después del parche =="
./scripts/inventario.sh
