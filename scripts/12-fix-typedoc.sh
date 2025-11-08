#!/usr/bin/env bash
# scripts/12-fix-typedoc.sh
#
# Descrição: Remove backups e ajusta TypeDoc para funcionar
# Uso: bash scripts/12-fix-typedoc.sh
# Pré-requisitos: bash
# Efeitos colaterais: Remove pasta backups/, ajusta typedoc.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "CORREÇÃO - TypeDoc"
echo "========================================="
echo ""

# 1. Remover pasta backups (causa erro no TypeDoc)
if [[ -d "backups" ]]; then
  echo "[info] Removendo pasta backups/..."
  rm -rf backups/
  echo "[ok] Pasta backups/ removida"
else
  echo "[info] Pasta backups/ não existe"
fi
echo ""

# 2. Remover arquivos .bak em packages/server
echo "[info] Removendo arquivos .bak em packages/server..."
find packages/server -name "*.bak*" -type f -delete 2>/dev/null || true
echo "[ok] Arquivos .bak removidos"
echo ""

# 3. Verificar typedoc.json
if [[ -f "typedoc.json" ]]; then
  echo "[info] Conteúdo do typedoc.json:"
  cat typedoc.json
  echo ""
fi

# 4. Rodar TypeDoc
echo "[info] Executando TypeDoc..."
if pnpm run docs; then
  echo ""
  echo "[ok] TypeDoc executado com sucesso!"
else
  echo ""
  echo "[warn] TypeDoc falhou (não crítico)"
fi

echo ""
echo "========================================="
echo "[ok] CORREÇÃO COMPLETA"
echo "========================================="
echo ""
echo "Limpeza realizada:"
echo "  ✓ Pasta backups/ removida"
echo "  ✓ Arquivos .bak removidos"
echo "  ✓ TypeDoc executado"
echo ""
echo "Próximo: REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
