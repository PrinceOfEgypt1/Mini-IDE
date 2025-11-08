#!/usr/bin/env bash
# scripts/05-cleanup-bak-files.sh
#
# Descrição: Remove arquivos .bak que causam erro no typecheck
# Uso: bash scripts/05-cleanup-bak-files.sh
# Pré-requisitos: bash
# Efeitos colaterais: Remove arquivos .bak

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "=== CLEANUP - Arquivos .bak ==="
echo ""

# Encontrar e remover .bak
BAK_FILES=$(find packages/server/test -name "*.bak.ts" 2>/dev/null || true)

if [[ -n "${BAK_FILES}" ]]; then
  echo "[info] Arquivos .bak encontrados:"
  echo "${BAK_FILES}"
  echo ""
  
  for file in ${BAK_FILES}; do
    echo "[info] Removendo: ${file}"
    rm -f "${file}"
  done
  
  echo ""
  echo "[ok] Arquivos .bak removidos"
else
  echo "[info] Nenhum arquivo .bak encontrado"
fi

echo ""
echo "Verifique com: pnpm --filter @mini-ide/server typecheck"
