#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 02e_fix_analyze_types.sh
# Objetivo: Corrigir tipos incompletos em analyze.spec.ts
# Versão: 1.0.17-patch4
# Data: 2024-11-15
#
# PROBLEMA:
# - Tipos genéricos em analyze.spec.ts não correspondem à resposta real
# - Faltam: inputLength, outputLength, requestId
# - Sobram: tokensUsed (não existe), runId (deveria ser requestId)
#
# SOLUÇÃO:
# - Usar tipo completo que corresponde a AnalyzeResponse de index.ts
#
# Arquivos afetados:
# - packages/server/test/analyze.spec.ts (CORRIGIDO)
###############################################################################

echo "[info] Iniciando correção CIRÚRGICA dos tipos em analyze.spec.ts"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Criar backup
echo "[info] Criando backup (.bak)..."
cp packages/server/test/analyze.spec.ts packages/server/test/analyze.spec.ts.bak
echo "[ok] Backup criado"

###############################################################################
# analyze.spec.ts (TIPOS CORRIGIDOS)
###############################################################################
echo ""
echo "[info] Corrigindo tipos em analyze.spec.ts..."

cat > packages/server/test/analyze.spec.ts << 'ENDOFFILE'
/**
 * @file analyze.spec.ts
 * @description Testes do endpoint /analyze
 * 
 * CHANGELOG v1.0.17-patch4:
 * - Tipos corrigidos para corresponder a AnalyzeResponse real
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('POST /analyze', () => {
  let server: Awaited<ReturnType<typeof build>>;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('deve processar texto com maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      inputLength: number;
      outputLength: number;
      requestId: string;
      timestamp: string;
      budgetUsed: number;
      budgetRemaining: number;
    }>(response);
    
    expect(body['summary']).toBeDefined();
    expect((body['summary'] as string).length).toBeLessThanOrEqual(10);
    expect(body['inputLength']).toBeDefined();
    expect(body['outputLength']).toBeDefined();
    expect(body['requestId']).toBeDefined();
    expect(body['timestamp']).toBeDefined();
  });

  it('deve aplicar maxLen padrão quando não especificado', async () => {
    const longText = 'a'.repeat(200);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect((body['summary'] as string).length).toBeLessThanOrEqual(100);
  });

  it('deve incluir requestId e timestamp na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test analysis', maxLen: 50 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      requestId: string;
      timestamp: string;
    }>(response);
    expect(body['requestId']).toBeDefined();
    expect(body['requestId']).toMatch(/^req_/);
    expect(body['timestamp']).toBeDefined();
  });

  it('deve incluir informações de budget na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test budget tracking', maxLen: 100 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown(response);
    expect(body['budgetUsed']).toBeDefined();
    expect(body['budgetRemaining']).toBeDefined();
    expect(typeof body['budgetUsed']).toBe('number');
    expect(typeof body['budgetRemaining']).toBe('number');
  });
});
ENDOFFILE

echo "[ok] analyze.spec.ts corrigido (91 linhas)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando typecheck para validar correções..."

if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] ✅ Typecheck passou! Todos os erros foram corrigidos."
else
  echo "[erro] ❌ Ainda há erros de TypeScript."
  exit 1
fi

echo ""
echo "[info] Executando todos os testes do servidor..."

if pnpm --filter @mini-ide/server test; then
  echo "[ok] ✅ Todos os testes estão passando!"
else
  echo "[warn] ⚠️  Alguns testes falharam. Veja detalhes acima."
fi

# Remover backup se tudo passou
echo ""
echo "[info] Removendo backup (.bak)..."
rm -f packages/server/test/analyze.spec.ts.bak
echo "[ok] Backup removido"

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 02e executado com sucesso!"
echo "=========================================="
echo ""
echo "🔧 Arquivo corrigido:"
echo "   - analyze.spec.ts (91 linhas)"
echo ""
echo "📊 Correções aplicadas:"
echo "   ✅ Tipo completo no teste 'deve processar texto com maxLen'"
echo "   ✅ inputLength: number (adicionado)"
echo "   ✅ outputLength: number (adicionado)"
echo "   ✅ requestId: string (corrigido de 'runId')"
echo "   ✅ budgetUsed: number (adicionado)"
echo "   ✅ budgetRemaining: number (adicionado)"
echo ""
echo "📊 Total: 3 erros de TypeScript corrigidos"
echo ""
echo "✅ Validações:"
echo "   - Typecheck: PASSOU"
echo "   - Testes: VERIFICAR ACIMA"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Confirmar que TODOS os testes passaram"
echo "   2. Commit: git add packages/server/"
echo "   3. Commit: git commit -m 'test(server): corrigir tipos em analyze.spec.ts'"
echo "   4. FINALMENTE prosseguir para Script 3 (HU-Quality-Coverage-Thresholds)"
echo ""
echo "[ok] Script finalizado em $(date)"
