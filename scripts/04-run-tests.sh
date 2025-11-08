#!/usr/bin/env bash
# scripts/04-run-tests.sh
#
# Descrição: Executa testes unitários do servidor
# Uso: bash scripts/04-run-tests.sh
# Pré-requisitos: pnpm, vitest
# Efeitos colaterais: Roda testes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "=== TESTES - Vitest ==="
echo ""

# Rodar testes
if pnpm --filter @mini-ide/server test; then
  echo ""
  echo "[ok] Todos os testes passaram!"
else
  echo ""
  echo "[erro] Alguns testes falharam"
  exit 1
fi

echo ""
echo "Próximo passo: bash scripts/smoke-analyze-200.sh"
