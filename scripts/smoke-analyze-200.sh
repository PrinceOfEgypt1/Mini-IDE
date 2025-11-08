#!/usr/bin/env bash
# scripts/smoke-analyze-200.sh
#
# Descrição: Smoke test do caminho feliz (200) do endpoint POST /analyze
# Uso: ./scripts/smoke-analyze-200.sh (executar da RAIZ do projeto)
# Pré-requisitos: pnpm, Node.js, curl, jq
# Variáveis de ambiente: PORT (padrão 3200)
# Efeitos colaterais: Inicia servidor temporário em background, depois finaliza

set -euo pipefail

# Detecta diretório raiz do projeto (onde está o pnpm-workspace.yaml)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Muda para o diretório raiz do projeto
cd "${PROJECT_ROOT}"

# Configuração
PORT="${PORT:-3200}"
BASE_URL="http://127.0.0.1:${PORT}"
SERVER_PID=""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função de cleanup
cleanup() {
  if [[ -n "${SERVER_PID}" ]]; then
    echo -e "${YELLOW}[info]${NC} Stopping server (PID ${SERVER_PID})..."
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

# Função de log
log_info() {
  echo -e "${YELLOW}[info]${NC} $*"
}

log_ok() {
  echo -e "${GREEN}[ok]${NC} $*"
}

log_error() {
  echo -e "${RED}[erro]${NC} $*" >&2
}

# Valida que estamos no diretório correto
if [[ ! -f "pnpm-workspace.yaml" ]]; then
  log_error "Must be run from project root (pnpm-workspace.yaml not found)"
  log_error "Current directory: $(pwd)"
  exit 1
fi

log_info "Project root: ${PROJECT_ROOT}"

# 1. Build do server
log_info "Building @mini-ide/server..."
pnpm --filter @mini-ide/server build

# Valida que o build gerou o arquivo esperado
if [[ ! -f "packages/server/dist/index.js" ]]; then
  log_error "Build failed: packages/server/dist/index.js not found"
  exit 1
fi

# 2. Start do servidor
log_info "Starting server on port ${PORT}..."
PORT="${PORT}" node packages/server/dist/index.js > /dev/null 2>&1 &
SERVER_PID=$!

# Aguarda servidor iniciar
log_info "Waiting for server to be ready..."
sleep 3

# Verifica se processo está rodando
if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
  log_error "Server failed to start"
  exit 1
fi

log_info "Server running with PID ${SERVER_PID}"

# 3. Teste 1: Happy path com maxLen
log_info "Test 1: POST /analyze with text and maxLen..."
RESPONSE=$(curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text":"Olá Mini-IDE!","maxLen":10}')

# Valida HTTP 200 (curl -w adiciona status code)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text":"Olá Mini-IDE!","maxLen":10}')

if [[ "${HTTP_CODE}" != "200" ]]; then
  log_error "Expected HTTP 200, got ${HTTP_CODE}"
  log_error "Response: ${RESPONSE}"
  exit 1
fi

# Valida campos obrigatórios no JSON
if ! echo "${RESPONSE}" | jq -e '.summary' > /dev/null 2>&1; then
  log_error "Missing field 'summary' in response"
  log_error "Response: ${RESPONSE}"
  exit 1
fi

if ! echo "${RESPONSE}" | jq -e '.tokensUsed | type == "number"' > /dev/null 2>&1; then
  log_error "Field 'tokensUsed' is not a number"
  log_error "Response: ${RESPONSE}"
  exit 1
fi

if ! echo "${RESPONSE}" | jq -e '.runId' > /dev/null 2>&1; then
  log_error "Missing field 'runId' in response"
  log_error "Response: ${RESPONSE}"
  exit 1
fi

if ! echo "${RESPONSE}" | jq -e '.ts' > /dev/null 2>&1; then
  log_error "Missing field 'ts' in response"
  log_error "Response: ${RESPONSE}"
  exit 1
fi

log_ok "Test 1 passed: All required fields present"

# 4. Teste 2: Default maxLen
log_info "Test 2: POST /analyze without maxLen (should use default 100)..."
RESPONSE2=$(curl -s -X POST "${BASE_URL}/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text":"Texto sem maxLen especificado"}')

SUMMARY_LEN=$(echo "${RESPONSE2}" | jq -r '.summary | length')

if [[ "${SUMMARY_LEN}" -gt 100 ]]; then
  log_error "Summary length ${SUMMARY_LEN} exceeds default maxLen (100)"
  exit 1
fi

log_ok "Test 2 passed: Default maxLen applied correctly"

# 5. Teste 3: Validação de tokensUsed
log_info "Test 3: Validating tokensUsed calculation..."
TOKENS=$(echo "${RESPONSE}" | jq -r '.tokensUsed')

if [[ "${TOKENS}" -ne 2 ]]; then
  log_error "Expected tokensUsed=2 for 'Olá Mini-IDE!', got ${TOKENS}"
  exit 1
fi

log_ok "Test 3 passed: tokensUsed calculated correctly"

# 6. Teste 4: Formato ISO-8601 do timestamp
log_info "Test 4: Validating ISO-8601 timestamp format..."
TS=$(echo "${RESPONSE}" | jq -r '.ts')

if ! echo "${TS}" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'; then
  log_error "Timestamp '${TS}' is not in ISO-8601 format"
  exit 1
fi

log_ok "Test 4 passed: Timestamp in ISO-8601 format"

# Sucesso!
log_ok "====================================="
log_ok "Smoke test PASSED - HU-Server-Analyze-200"
log_ok "All tests passed successfully"
log_ok "====================================="

exit 0
