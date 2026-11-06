#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Árbol de procesos: web =="
docker top php-lab -eo pid,ppid,user,comm,args || true

echo
echo "== Árbol de procesos: API =="
docker top node-lab -eo pid,ppid,user,comm,args || true

echo
echo "== Árbol de procesos: servicio interno =="
docker top py-lab -eo pid,ppid,user,comm,args || true

echo
echo "== Hijos sospechosos en el log sintético =="
grep -E 'ppid_comm=(apache2|php-fpm|node|python)' logs/audit.log \
  | grep -E 'comm=(sh|bash|curl|wget|nc)' \
  || echo "sin coincidencias"
