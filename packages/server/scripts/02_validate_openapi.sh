#!/usr/bin/env bash
# Script: packages/server/scripts/02_validate_openapi.sh
# Objetivo: Validar especificação OpenAPI
# Uso: bash packages/server/scripts/02_validate_openapi.sh
# Requisitos: npx disponível

set -euo pipefail

echo "[info] Validando especificação OpenAPI"

cd packages/server

# Verificar se arquivo existe
if [ ! -f "openapi.yaml" ]; then
  echo "[erro] Arquivo openapi.yaml não encontrado"
  exit 1
fi

# Validar com swagger-cli (via npx)
echo "[info] Validando sintaxe YAML e estrutura OpenAPI..."
npx --yes @apidevtools/swagger-cli validate openapi.yaml

echo "[ok] Especificação OpenAPI válida"
