#!/usr/bin/env bash
# ==============================================================================
# Script: 30_fix_discovery_and_check_ui.sh
# Objetivo:
#   1. Garantir que estamos na raiz do projeto Mini-IDE
#   2. Remover diretivas eslint-disable inúteis de DiscoveryNotes.tsx
#   3. Rodar pipeline da UI (@mini-ide/ui): lint, test, typecheck, build
#   4. Avisar se existe rebase em andamento e mostrar git status
# ==============================================================================

set -euo pipefail

echo "========================================="
echo " MINI-IDE :: Fix DiscoveryNotes + UI CI  "
echo "========================================="
echo ""

# 1) Conferir se estamos na raiz do Mini-IDE
if [ ! -f "42_pipeline_checklist.sh" ] || [ ! -d "packages/ui" ]; then
  echo "[erro] Este script deve ser executado na raiz do projeto Mini-IDE."
  echo "       Exemplo: cd ~/workspace/Mini-IDE"
  exit 1
fi

ROOT_DIR="$(pwd)"
echo "[info] Raiz do projeto: $ROOT_DIR"
echo ""

# 2) Remover diretivas eslint-disable inúteis do DiscoveryNotes.tsx
DISCOVERY_FILE="packages/ui/src/components/discovery/DiscoveryNotes.tsx"

if [ -f "$DISCOVERY_FILE" ]; then
  echo "[info] Ajustando arquivo: $DISCOVERY_FILE"

  if grep -q "eslint-disable" "$DISCOVERY_FILE"; then
    TMP_FILE="$(mktemp)"
    echo "[info] Removendo linhas com 'eslint-disable'..."
    # Remove qualquer linha que contenha 'eslint-disable'
    grep -v "eslint-disable" "$DISCOVERY_FILE" > "$TMP_FILE"
    mv "$TMP_FILE" "$DISCOVERY_FILE"
    echo "[ok] Diretivas eslint-disable removidas de $DISCOVERY_FILE"
  else
    echo "[info] Nenhuma diretiva eslint-disable encontrada em $DISCOVERY_FILE"
  fi
else
  echo "[warn] Arquivo não encontrado: $DISCOVERY_FILE"
fi

echo ""

# 3) Rodar pipeline da UI (@mini-ide/ui)
echo "-----------------------------------------"
echo "[info] Rodando lint da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui lint
echo "[ok] Lint da UI passou"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando testes da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui test
echo "[ok] Testes da UI passaram"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando typecheck da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui typecheck
echo "[ok] Typecheck da UI passou"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando build da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui build
echo "[ok] Build da UI passou"
echo ""

# 4) Verificar se há rebase em andamento e mostrar git status
echo "-----------------------------------------"
echo "[info] Verificando estado do Git..."

if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
  echo "[warn] Há um REBASE em andamento neste repositório."
  echo "[warn] Revise arquivos em conflito (ex.: DEVELOPMENT.md), resolva,"
  echo "       faça 'git add <arquivos>' e depois:"
  echo "       git rebase --continue"
  echo ""
fi

echo "[info] Saída do 'git status':"
git status
echo ""

echo "========================================="
echo " ✅ Script concluído"
echo " - DiscoveryNotes.tsx ajustado (sem eslint-disable inútil)"
echo " - UI: lint / test / typecheck / build OK"
echo " - Veja o git status acima para próximos passos (commit / rebase)"
echo "========================================="
