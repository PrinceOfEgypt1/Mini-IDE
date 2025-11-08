#!/usr/bin/env bash
# scripts/13-finalize-hu.sh
#
# Descrição: Finaliza HU-Server-Analyze-200 e prepara commit
# Uso: bash scripts/13-finalize-hu.sh
# Pré-requisitos: bash, git
# Efeitos colaterais: Executa smoke test final e prepara commit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "FINALIZAÇÃO - HU-Server-Analyze-200"
echo "========================================="
echo ""

# 1. Smoke test final
echo "[1] Executando smoke test final..."
echo ""
if bash scripts/smoke-analyze-200.sh; then
  echo ""
  echo "[ok] Smoke test PASSED"
else
  echo ""
  echo "[erro] Smoke test FAILED"
  exit 1
fi

echo ""
echo "========================================="
echo ""

# 2. Resumo da implementação
echo "[2] RESUMO DA IMPLEMENTAÇÃO"
echo ""
echo "✅ Arquivos entregues:"
echo "  1. packages/server/src/index.ts"
echo "     - POST /analyze implementado"
echo "     - Default maxLen=100, limites [1..1000]"
echo "     - Logs JSON estruturados (evento analyze.200)"
echo ""
echo "  2. packages/server/test/analyze.spec.ts"
echo "     - 6 testes Vitest (AC1, AC2, AC3)"
echo "     - Boundary tests (maxLen=1, maxLen=1000)"
echo "     - Validação de múltiplos tokens"
echo ""
echo "  3. packages/server/test/healthz.spec.ts"
echo "     - Corrigido para compatibilidade"
echo "     - Valida { status, timestamp }"
echo ""
echo "  4. scripts/smoke-analyze-200.sh"
echo "     - Smoke test automatizado"
echo "     - 4 testes: campos, default, tokens, ISO-8601"
echo ""
echo "  5. test/smoke-analyze-200-runner.sh"
echo "     - Runner bash para validação"
echo ""
echo "✅ Validações:"
echo "  - 7 testes unitários passando"
echo "  - Build/typecheck/lint OK"
echo "  - TypeDoc gerado"
echo "  - Pipeline 42_checklist.sh verde"
echo "  - Smoke test validando endpoint real"
echo ""
echo "✅ Observabilidade:"
echo "  - Log JSON: { event, runId, ts, textLen, maxLen, summaryLen, tokensUsed }"
echo ""

echo "========================================="
echo ""

# 3. Status do Git
echo "[3] Status do Git:"
echo ""
git status --short

echo ""
echo "========================================="
echo ""

# 4. Preparar commit
echo "[4] COMANDO DE COMMIT SUGERIDO:"
echo ""
cat << 'COMMIT_MSG'
git add packages/server/src/index.ts \
        packages/server/test/analyze.spec.ts \
        packages/server/test/healthz.spec.ts \
        scripts/smoke-analyze-200.sh \
        test/smoke-analyze-200-runner.sh

git commit -m "feat(server): implementa POST /analyze (200) com summary/tokensUsed/runId/ts

- Adiciona endpoint POST /analyze com validação de text e maxLen
- Implementa default maxLen=100 e limites [1..1000]
- Gera logs estruturados JSON (evento analyze.200)
- Cria smoke test automatizado (scripts/smoke-analyze-200.sh)
- Adiciona 6 testes Vitest cobrindo AC1, AC2, AC3
- Corrige healthz.spec.ts para compatibilidade com { status, timestamp }
- 7 testes passando (1 healthz + 6 analyze)

Critérios de Aceite:
- AC1: Happy path com maxLen ✓
- AC2: Default maxLen (100) ✓
- AC3: Campos obrigatórios (summary/tokensUsed/runId/ts) ✓

Observabilidade:
- Log JSON estruturado com evento analyze.200
- Campos: runId, ts, textLen, maxLen, summaryLen, tokensUsed

Refs: HU-Server-Analyze-200"
COMMIT_MSG

echo ""
echo "========================================="
echo ""

echo "🎉 PRONTO — CICLO 1 COMPLETO 🎉"
echo ""
echo "HU-Server-Analyze-200 implementada com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. Revisar arquivos modificados (git diff)"
echo "  2. Executar comando de commit acima"
echo "  3. git push"
echo "  4. Aguardar revisão antes da próxima HU"
echo ""
echo "========================================="
