#!/usr/bin/env bash
# Script: packages/server/scripts/03_dev_server.sh
# Objetivo: Iniciar servidor de desenvolvimento com logs formatados
# Uso: bash packages/server/scripts/03_dev_server.sh
# Variáveis: PORT (default: 3200)

set -euo pipefail

PORT="${PORT:-3200}"

echo "[info] Iniciando servidor de desenvolvimento na porta ${PORT}"

# Build antes de iniciar
pnpm --filter @mini-ide/server build

# Iniciar servidor
PORT="${PORT}" node packages/server/dist/index.js | while IFS= read -r line; do
  # Formatar logs JSON para leitura
  if echo "${line}" | jq -e . >/dev/null 2>&1; then
    echo "${line}" | jq -C '.'
  else
    echo "${line}"
  fi
done
