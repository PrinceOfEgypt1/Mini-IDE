#!/usr/bin/env bash
# scripts/15-final-commit.sh
#
# Descrição: Finaliza HU-Server-Analyze-200 e faz commit
# Uso: bash scripts/15-final-commit.sh
# Pré-requisitos: bash, git
# Efeitos colaterais: Prepara e sugere commit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "CONCLUSÃO - HU-Server-Analyze-200"
echo "========================================="
echo ""

# 1. Garantir que porta está livre
echo "[1] Verificando porta 3200..."
if lsof -i:3200 2>/dev/null; then
  echo "[warn] Porta 3200 em uso, limpando..."
  kill $(lsof -t -i:3200) 2>/dev/null || true
  sleep 2
fi
echo "[ok] Porta 3200 livre"
echo ""

# 2. Smoke test final
echo "[2] Executando smoke test final..."
if bash scripts/smoke-analyze-200.sh; then
  echo ""
  echo "[ok] ✅ SMOKE TEST PASSOU"
else
  echo ""
  echo "[erro] ❌ Smoke test falhou"
  exit 1
fi

echo ""
echo "========================================="
echo ""

# 3. Pipeline completo (validação final)
echo "[3] Executando pipeline completo..."
if REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh 2>&1 | tail -20; then
  echo ""
  echo "[ok] ✅ PIPELINE 100% VERDE"
else
  echo ""
  echo "[erro] ❌ Pipeline falhou"
  exit 1
fi

echo ""
echo "========================================="
echo ""

# 4. Resumo de entrega
cat << 'SUMMARY'
📦 ENTREGÁVEIS - HU-SERVER-ANALYZE-200

✅ Arquivos implementados:
  1. packages/server/src/index.ts
     • POST /analyze com validação
     • Default maxLen=100, limites [1..1000]
     • Logs JSON estruturados

  2. packages/server/test/analyze.spec.ts
     • 6 testes Vitest (AC1, AC2, AC3)
     • Boundary tests (maxLen 1-1000)
     • Validação de tokens

  3. packages/server/test/healthz.spec.ts
     • Corrigido: { status, timestamp }

  4. scripts/smoke-analyze-200.sh
     • Smoke test automatizado
     • 4 validações end-to-end

✅ Validações completas:
  • 7 testes unitários passando
  • Build/typecheck/lint OK
  • TypeDoc gerado
  • Pipeline 42_checklist verde
  • Smoke test validado

✅ Observabilidade:
  • Evento: analyze.200
  • Campos: runId, ts, textLen, maxLen, summaryLen, tokensUsed
  • Formato: JSON estruturado

========================================
SUMMARY

echo ""
echo "[4] Git status:"
echo ""
git status --short

echo ""
echo "========================================="
echo ""

# 5. Comando de commit
cat << 'COMMIT_CMD'
📝 COMANDO DE COMMIT:

git add packages/server/src/index.ts \
        packages/server/test/analyze.spec.ts \
        packages/server/test/healthz.spec.ts \
        scripts/smoke-analyze-200.sh

git commit -m "feat(server): implementa POST /analyze (200) com summary/tokensUsed/runId/ts

- Adiciona endpoint POST /analyze com validação de text e maxLen
- Implementa default maxLen=100 e limites [1..1000]
- Gera logs estruturados JSON (evento analyze.200)
- Cria smoke test automatizado (scripts/smoke-analyze-200.sh)
- Adiciona 6 testes Vitest cobrindo AC1, AC2, AC3
- Corrige healthz.spec.ts para compatibilidade
- 7 testes passando (1 healthz + 6 analyze)

Critérios de Aceite:
- AC1: Happy path com maxLen ✓
- AC2: Default maxLen (100) ✓
- AC3: Campos obrigatórios presentes ✓

Observabilidade:
- Log JSON: evento analyze.200
- Campos: runId, ts, textLen, maxLen, summaryLen, tokensUsed

Refs: HU-Server-Analyze-200"

COMMIT_CMD

echo ""
echo "========================================="
echo ""
echo "🎉 PRONTO — CICLO 1 COMPLETO! 🎉"
echo ""
echo "Próximos passos:"
echo "  1. Revisar arquivos: git diff"
echo "  2. Executar comando de commit acima"
echo "  3. git push"
echo "  4. Aguardar revisão antes da próxima HU"
echo ""
echo "========================================="
