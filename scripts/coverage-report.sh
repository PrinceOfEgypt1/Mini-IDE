#!/usr/bin/env bash
################################################################################
# Script: coverage-report.sh
# Objetivo: Executar testes com coverage e abrir relatório HTML
# Uso: bash scripts/coverage-report.sh
################################################################################

set -euo pipefail

echo "[info] Executando testes com cobertura..."

# Executar testes com coverage em todos os pacotes
pnpm test -- --coverage

echo "[ok] Testes com cobertura concluídos"
echo "[info] Relatórios de cobertura gerados:"
echo "  - packages/shared/coverage/index.html"
echo "  - packages/server/coverage/index.html"
echo "  - packages/analysis-agent/coverage/index.html (se existir)"
echo "  - packages/cli/coverage/index.html (se existir)"

# Detectar SO e abrir relatório no browser
if [[ -f "packages/server/coverage/index.html" ]]; then
  echo "[info] Abrindo relatório do servidor no browser..."
  
  if command -v xdg-open > /dev/null; then
    # Linux
    xdg-open packages/server/coverage/index.html
  elif command -v open > /dev/null; then
    # macOS
    open packages/server/coverage/index.html
  elif command -v start > /dev/null; then
    # Windows (Git Bash/WSL)
    start packages/server/coverage/index.html
  else
    echo "[warn] Não foi possível detectar comando para abrir browser"
    echo "[info] Abra manualmente: packages/server/coverage/index.html"
  fi
else
  echo "[warn] Relatório do servidor não encontrado"
fi

echo "[ok] Processo de coverage concluído"
