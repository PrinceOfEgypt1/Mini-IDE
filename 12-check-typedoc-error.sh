#!/usr/bin/env bash
# scripts/12-check-typedoc-error.sh
#
# Descrição: Verifica erro do TypeDoc e tenta corrigir
# Uso: bash scripts/12-check-typedoc-error.sh
# Pré-requisitos: bash
# Efeitos colaterais: Lê log de erro e executa TypeDoc

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "DIAGNÓSTICO - TypeDoc"
echo "========================================="
echo ""

# 1. Verificar log de erro
if [[ -f /tmp/typedoc.log ]]; then
  echo "[info] Conteúdo do /tmp/typedoc.log:"
  echo "-------------------------------------"
  cat /tmp/typedoc.log
  echo "-------------------------------------"
  echo ""
else
  echo "[warn] /tmp/typedoc.log não encontrado"
  echo ""
fi

# 2. Tentar executar TypeDoc manualmente
echo "[info] Tentando executar TypeDoc manualmente..."
echo ""

if pnpm run docs 2>&1 | tee /tmp/typedoc-manual.log; then
  echo ""
  echo "[ok] TypeDoc executado com sucesso!"
else
  echo ""
  echo "[erro] TypeDoc falhou. Log salvo em /tmp/typedoc-manual.log"
  echo ""
  echo "Conteúdo do erro:"
  echo "-------------------------------------"
  cat /tmp/typedoc-manual.log
  echo "-------------------------------------"
fi

echo ""
echo "Próximo: analisar erro e aplicar correção"
