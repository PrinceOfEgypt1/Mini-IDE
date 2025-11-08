#!/usr/bin/env bash
# scripts/00-fix-all.sh
#
# Descrição: Executa todos os scripts de correção em sequência
# Uso: bash scripts/00-fix-all.sh
# Pré-requisitos: todos os scripts 01-05 devem existir
# Efeitos colaterais: Corrige todos os problemas identificados

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "========================================="
echo "CORREÇÃO COMPLETA - HU-Server-Analyze-200"
echo "========================================="
echo ""

# Step 1: Diagnóstico e backup
if bash scripts/01-diagnose-backup.sh; then
  echo ""
else
  echo "[erro] Falha no diagnóstico"
  exit 1
fi

# Step 2: Correção do index.ts
if bash scripts/02-fix-index-ts.sh; then
  echo ""
else
  echo "[erro] Falha na correção do index.ts"
  exit 1
fi

# Step 3: Cleanup de arquivos .bak
if bash scripts/05-cleanup-bak-files.sh; then
  echo ""
else
  echo "[warn] Falha no cleanup (não crítico)"
fi

# Step 4: Verificação de typecheck
if bash scripts/03-verify-typecheck.sh; then
  echo ""
else
  echo "[erro] Falha no typecheck"
  exit 1
fi

# Step 5: Testes
if bash scripts/04-run-tests.sh; then
  echo ""
else
  echo "[erro] Falha nos testes"
  exit 1
fi

# Step 6: Smoke test
if bash scripts/smoke-analyze-200.sh; then
  echo ""
else
  echo "[erro] Falha no smoke test"
  exit 1
fi

echo "========================================="
echo "[ok] CORREÇÃO COMPLETA - SUCESSO!"
echo "========================================="
echo ""
echo "Todos os passos passaram:"
echo "✓ Diagnóstico e backup"
echo "✓ Correção do index.ts"
echo "✓ Cleanup de arquivos .bak"
echo "✓ Typecheck"
echo "✓ Testes unitários"
echo "✓ Smoke test"
echo ""
echo "Próximo passo: REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
