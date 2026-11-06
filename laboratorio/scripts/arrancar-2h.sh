#!/usr/bin/env bash
set -euo pipefail

# Arranque rápido para la clase de 2 horas.
# Usa `--wait`: no devuelve el control hasta que los 3 servicios están healthy.
cd "$(dirname "$0")/.."

NODE_IMAGE="goys-vuln-lab-node:${NODE_TAG:-22.23.3-bookworm-slim}"

if ! docker image inspect "$NODE_IMAGE" >/dev/null 2>&1; then
  echo "Imágenes no encontradas: construyendo (puede tardar unos minutos)..."
  docker compose --env-file versions.env build
fi

docker compose --env-file versions.env up -d --wait
docker compose ps
echo
./scripts/inventario.sh
