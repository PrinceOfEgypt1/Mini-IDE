#!/usr/bin/env bash
# Script: packages/server/scripts/05_test_endpoints.sh
# Objetivo: Testar endpoints HTTP do servidor
# Uso: bash packages/server/scripts/05_test_endpoints.sh
# Requisitos: servidor rodando em :3200

set -euo pipefail

BASE_URL="http://127.0.0.1:3200"

echo "[info] Testando endpoints do Mini-IDE Server"

# Verificar se servidor está rodando
if ! curl -s "${BASE_URL}/healthz" > /dev/null 2>&1; then
  echo "[erro] Servidor não está respondendo em ${BASE_URL}"
  echo "[info] Inicie o servidor com: bash packages/server/scripts/03_dev_server.sh"
  exit 1
fi

echo ""
echo "=== Teste 1: Health Check ==="
curl -s "${BASE_URL}/healthz" | jq '.'

echo ""
echo "=== Teste 2: Análise Válida ==="
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text": "Olá Mini-IDE!", "maxLen": 10}' | jq '.'

echo ""
echo "=== Teste 3: Validação - Text Ausente (400) ==="
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"maxLen": 10}' | jq '.'

echo ""
echo "=== Teste 4: Validação - Text Vazio (400) ==="
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text": "", "maxLen": 10}' | jq '.'

echo ""
echo "=== Teste 5: Validação - MaxLen Inválido (400) ==="
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text": "teste", "maxLen": 0}' | jq '.'

echo ""
echo "=== Teste 6: Validação - MaxLen Excedido (400) ==="
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text": "teste", "maxLen": 1001}' | jq '.'

echo ""
echo "=== Teste 7: Orçamento Excedido (402) ==="
# Criar arquivo temporário com texto grande
TEMP_FILE=$(mktemp)
# Gerar texto com muitas palavras (10 milhões de tokens simulados)
python3 -c "print(' '.join(['word'] * 10000000))" > "${TEMP_FILE}"
curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  --data-binary @- << EOF | jq '.'
{"text": "$(cat ${TEMP_FILE})", "maxLen": 100}
EOF
rm -f "${TEMP_FILE}"

echo ""
echo "[ok] Testes concluídos"
