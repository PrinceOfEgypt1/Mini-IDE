#!/usr/bin/env bash
# Script: packages/server/scripts/01_build_and_test.sh
# Objetivo: Build do pacote server e execução de todos os testes
# Uso: bash packages/server/scripts/01_build_and_test.sh

set -euo pipefail

echo "[info] Iniciando build e testes do pacote @mini-ide/server"

# Build do pacote
echo "[info] Executando build..."
pnpm --filter @mini-ide/server build

# Executar testes
echo "[info] Executando testes..."
pnpm --filter @mini-ide/server test

echo "[ok] Build e testes concluídos com sucesso"
