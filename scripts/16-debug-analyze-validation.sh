#!/usr/bin/env bash
# scripts/16-debug-analyze-validation.sh
#
# Descrição: Debug da validação do /analyze no pipeline
# Uso: bash scripts/16-debug-analyze-validation.sh
# Pré-requisitos: bash
# Efeitos colaterais: Testa endpoint /analyze manualmente

set -euo pipefail

cd ~/workspace/Mini-IDE

echo "========================================="
echo "DEBUG - Validação /analyze"
echo "========================================="
echo ""

# 1. Limpar porta
echo "[1] Limpando porta 3200..."
pkill -f "node packages/server/dist/index.js" 2>/dev/null || true
kill $(lsof -t -i:3200) 2>/dev/null || true
sleep 2
echo "[ok] Porta limpa"
echo ""

# 2. Build
echo "[2] Build do servidor..."
pnpm --filter @mini-ide/server build
echo ""

# 3. Iniciar servidor
echo "[3] Iniciando servidor..."
PORT=3200 node packages/server/dist/index.js > /tmp/server.log 2>&1 &
SERVER_PID=$!
echo "[info] Servidor PID: $SERVER_PID"
sleep 3

if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo "[erro] Servidor não iniciou"
  cat /tmp/server.log
  exit 1
fi
echo "[ok] Servidor rodando"
echo ""

# 4. Testar /healthz
echo "[4] Testando /healthz..."
HEALTHZ=$(curl -s http://127.0.0.1:3200/healthz)
echo "$HEALTHZ" | jq .
echo ""

# 5. Testar /analyze
echo "[5] Testando /analyze..."
ANALYZE=$(curl -s -X POST http://127.0.0.1:3200/analyze \
  -H "Content-Type: application/json" \
  -d '{"text":"teste","maxLen":10}')
  
echo "Resposta:"
echo "$ANALYZE" | jq .
echo ""

# Verificar campos
echo "[6] Verificando campos obrigatórios..."
if echo "$ANALYZE" | jq -e '.summary' > /dev/null; then
  echo "  ✓ summary"
else
  echo "  ✗ summary AUSENTE"
fi

if echo "$ANALYZE" | jq -e '.tokensUsed' > /dev/null; then
  echo "  ✓ tokensUsed"
else
  echo "  ✗ tokensUsed AUSENTE"
fi

if echo "$ANALYZE" | jq -e '.runId' > /dev/null; then
  echo "  ✓ runId"
else
  echo "  ✗ runId AUSENTE"
fi

if echo "$ANALYZE" | jq -e '.ts' > /dev/null; then
  echo "  ✓ ts"
else
  echo "  ✗ ts AUSENTE"
fi

echo ""

# Limpar
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

echo "[ok] Debug completo"
