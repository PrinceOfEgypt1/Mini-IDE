#!/usr/bin/env bash
# scripts/14-diagnose-server-start.sh
#
# Descrição: Diagnostica por que o servidor não inicia no smoke test
# Uso: bash scripts/14-diagnose-server-start.sh
# Pré-requisitos: bash
# Efeitos colaterais: Tenta iniciar servidor manualmente

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "DIAGNÓSTICO - Servidor não inicia"
echo "========================================="
echo ""

# 1. Verificar se já tem servidor rodando
echo "[1] Verificando se porta 3200 está em uso..."
if lsof -i:3200 2>/dev/null; then
  echo "[warn] Porta 3200 já está em uso!"
  echo ""
  echo "Para matar o processo:"
  echo "  kill \$(lsof -t -i:3200)"
  echo ""
  read -p "Deseja matar o processo? (y/n): " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    kill $(lsof -t -i:3200) 2>/dev/null || true
    sleep 2
    echo "[ok] Processo morto"
  fi
else
  echo "[ok] Porta 3200 livre"
fi
echo ""

# 2. Verificar build
echo "[2] Verificando build..."
if [[ ! -f "packages/server/dist/index.js" ]]; then
  echo "[erro] Build não encontrado"
  echo "[info] Executando build..."
  pnpm --filter @mini-ide/server build
fi
echo "[ok] Build existe"
echo ""

# 3. Tentar iniciar servidor manualmente com output visível
echo "[3] Tentando iniciar servidor manualmente..."
echo "[info] Executando: PORT=3200 node packages/server/dist/index.js"
echo "[info] Pressione Ctrl+C após ver 'server.started'"
echo ""

PORT=3200 node packages/server/dist/index.js &
SERVER_PID=$!

sleep 3

if kill -0 $SERVER_PID 2>/dev/null; then
  echo ""
  echo "[ok] Servidor iniciou com PID $SERVER_PID"
  echo ""
  echo "Testando endpoint..."
  curl -s http://127.0.0.1:3200/healthz | jq .
  echo ""
  echo "Matando servidor..."
  kill $SERVER_PID
  wait $SERVER_PID 2>/dev/null || true
else
  echo ""
  echo "[erro] Servidor falhou ao iniciar"
  echo ""
  echo "Tentando novamente com output completo..."
  PORT=3200 node packages/server/dist/index.js
fi

echo ""
echo "Diagnóstico completo"
