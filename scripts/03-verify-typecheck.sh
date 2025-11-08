#!/usr/bin/env bash
# scripts/03-verify-typecheck.sh
#
# Descrição: Verifica se typecheck passou após correção
# Uso: bash scripts/03-verify-typecheck.sh
# Pré-requisitos: pnpm, tsc
# Efeitos colaterais: Roda typecheck

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "=== VERIFICAÇÃO - Typecheck ==="
echo ""

# 1. Build primeiro
echo "[1] Building server..."
if pnpm --filter @mini-ide/server build; then
  echo "[ok] Build OK"
else
  echo "[erro] Build failed"
  exit 1
fi

# 2. Typecheck
echo ""
echo "[2] Running typecheck..."
if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] Typecheck OK"
else
  echo "[erro] Typecheck failed"
  echo ""
  echo "Possíveis causas:"
  echo "1. Arquivos .bak estão sendo checados (renomear ou remover)"
  echo "2. Imports nos testes estão incorretos"
  exit 1
fi

echo ""
echo "[ok] Typecheck passou!"
echo ""
echo "Próximo passo: bash scripts/04-run-tests.sh"
