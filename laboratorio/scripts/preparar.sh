#!/usr/bin/env bash
set -euo pipefail

# Preparación del docente: deja las imágenes vulns y parcheadas listas
# para que la clase de 2 horas no pierda tiempo en pulls/builds.
cd "$(dirname "$0")/.."

echo "== PHP: imágenes vulnerable y parcheada =="
docker pull php:8.3.35-apache
docker pull php:8.3.36-apache

echo "== Node/Python vulnerable =="
docker compose --env-file versions.env build

echo "== Node/Python parcheado =="
NODE_TAG=22.23.4-bookworm-slim \
BROTLI_VERSION=1.2.1 \
  docker compose --env-file versions.env build

echo
echo "Listo. La clase puede arrancar con:"
echo "  ./scripts/arrancar-2h.sh"
