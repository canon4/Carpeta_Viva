#!/usr/bin/env bash
# Clona (o inicializa vacío) los repositorios backend y frontend dentro de Carpeta_Viva.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -f .env ]; then set -a; . ./.env; set +a; fi

preparar() {
  local nombre="$1" url="${2:-}"
  if [ -d "$nombre/.git" ]; then
    echo "$nombre: ya existe"
  elif [ -n "$url" ]; then
    git clone "$url" "$nombre"
  else
    mkdir -p "$nombre"
    git -C "$nombre" init -b main
    echo "$nombre: sin URL en .env, repositorio vacío inicializado"
  fi
}

preparar backend "${BACKEND_REPO_URL:-}"
preparar frontend "${FRONTEND_REPO_URL:-}"
[ -f .env ] || { cp .env.example .env; echo "Se creó .env: completa los valores antes de levantar los servicios."; }
