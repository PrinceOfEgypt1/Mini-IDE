#!/usr/bin/env bash
set -euo pipefail
cd ~/workspace/Mini-IDE
cat > PR_CONTENT.md << 'EOF'
# feat(server): implementa POST /analyze (200) com observabilidade

## 📝 Resumo

Implementa endpoint `POST /analyze` com validação completa, observabilidade estruturada e testes end-to-end.

## ✨ Features Implementadas

### Endpoint POST /analyze
- ✅ Validação de `text` (obrigatório, tipo string)
- ✅ Validação de `maxLen` (opcional, default 100, limites [1..1000])
- ✅ Retorna: `{ summary, tokensUsed, runId, ts }`
- ✅ Logs JSON estruturados (evento `analyze.200`)
- ✅ Truncamento determinístico de texto
- ✅ Contagem de tokens por split de espaços

### Testes (7/7 passando)
- ✅ **AC1**: Happy path com `maxLen` especificado
- ✅ **AC2**: Default `maxLen=100` quando omitido
- ✅ **AC3**: Todos campos obrigatórios presentes
- ✅ Boundary tests: `maxLen=1` e `maxLen=1000`
- ✅ Validação de múltiplos tokens
- ✅ Formato ISO-8601 para timestamps
- ✅ Formato UUID v4 para runId

## 📦 Arquivos Modificados

- `packages/server/src/index.ts` - Endpoint POST /analyze
- `packages/server/test/analyze.spec.ts` - 6 testes (AC1-AC3)
- `packages/server/test/healthz.spec.ts` - 1 teste
- `packages/server/test/test-utils.ts` - Type guards
- `scripts/smoke-analyze-200.sh` - Smoke test

## ✅ Qualidade

Pipeline 100% verde: build/typecheck/lint/tests/docs OK

## 🚀 Como Testar
```bash
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
bash scripts/smoke-analyze-200.sh
```

**Ready for review! 🎯**
EOF
echo "✅ PR_CONTENT.md criado!"
