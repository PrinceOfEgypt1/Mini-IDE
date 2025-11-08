#!/usr/bin/env bash
# test/smoke-analyze-200-runner.sh
#
# Descrição: Runner de testes para smoke-analyze-200.sh (substitui Bats)
# Uso: bash test/smoke-analyze-200-runner.sh
# Pré-requisitos: bash, smoke-analyze-200.sh executável
# Efeitos colaterais: Executa smoke test e valida saídas

set -euo pipefail

# Detecta diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Contadores
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Funções auxiliares
log_test() {
  echo -e "${YELLOW}[TEST]${NC} $*"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $*"
  ((TESTS_PASSED++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $*"
  ((TESTS_FAILED++))
}

run_test() {
  local test_name="$1"
  local test_command="$2"
  local expected_pattern="$3"
  
  ((TESTS_RUN++))
  log_test "${test_name}"
  
  if OUTPUT=$(eval "${test_command}" 2>&1); then
    if [[ "${OUTPUT}" =~ ${expected_pattern} ]]; then
      log_pass "${test_name}"
      return 0
    else
      log_fail "${test_name} - Pattern '${expected_pattern}' not found in output"
      return 1
    fi
  else
    log_fail "${test_name} - Command failed with exit code $?"
    return 1
  fi
}

# Banner inicial
echo "========================================"
echo "Smoke Test Runner - HU-Server-Analyze-200"
echo "========================================"
echo ""

# Teste 1: Script existe e é executável
((TESTS_RUN++))
log_test "smoke-analyze-200.sh should exist and be executable"
if [[ -x "scripts/smoke-analyze-200.sh" ]]; then
  log_pass "Script exists and is executable"
else
  log_fail "Script not found or not executable"
  echo ""
  echo "Summary: ${TESTS_PASSED}/${TESTS_RUN} tests passed"
  exit 1
fi

# Teste 2: Script executa sem erros
((TESTS_RUN++))
log_test "smoke-analyze-200.sh should complete successfully"
if OUTPUT=$(bash scripts/smoke-analyze-200.sh 2>&1); then
  EXIT_CODE=$?
  if [[ ${EXIT_CODE} -eq 0 ]]; then
    log_pass "Script completed with exit code 0"
  else
    log_fail "Script failed with exit code ${EXIT_CODE}"
    echo "Output:"
    echo "${OUTPUT}"
  fi
else
  EXIT_CODE=$?
  log_fail "Script failed with exit code ${EXIT_CODE}"
  echo "Output:"
  echo "${OUTPUT}"
fi

# Teste 3: Valida que o script faz build
run_test \
  "smoke-analyze-200.sh should build server" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Building @mini-ide/server"

# Teste 4: Valida que o script inicia o servidor
run_test \
  "smoke-analyze-200.sh should start server on port 3200" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Starting server on port 3200"

# Teste 5: Valida Test 1 (campos obrigatórios)
run_test \
  "smoke-analyze-200.sh should validate POST /analyze response" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Test 1 passed: All required fields present"

# Teste 6: Valida Test 2 (default maxLen)
run_test \
  "smoke-analyze-200.sh should validate default maxLen" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Test 2 passed: Default maxLen applied correctly"

# Teste 7: Valida Test 3 (tokensUsed)
run_test \
  "smoke-analyze-200.sh should validate tokensUsed calculation" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Test 3 passed: tokensUsed calculated correctly"

# Teste 8: Valida Test 4 (timestamp ISO-8601)
run_test \
  "smoke-analyze-200.sh should validate ISO-8601 timestamp" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Test 4 passed: Timestamp in ISO-8601 format"

# Teste 9: Valida mensagem de sucesso final
run_test \
  "smoke-analyze-200.sh should report overall success" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Smoke test PASSED - HU-Server-Analyze-200"

# Teste 10: Valida cleanup do servidor
run_test \
  "smoke-analyze-200.sh should cleanup server process" \
  "bash scripts/smoke-analyze-200.sh 2>&1" \
  "Stopping server"

# Sumário final
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total tests run: ${TESTS_RUN}"
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"
echo ""

if [[ ${TESTS_FAILED} -eq 0 ]]; then
  echo -e "${GREEN}[SUCCESS]${NC} All tests passed!"
  exit 0
else
  echo -e "${RED}[FAILURE]${NC} Some tests failed"
  exit 1
fi
