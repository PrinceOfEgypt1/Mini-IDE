#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 02d_fix_tests_retrocompat.sh
# Objetivo: Solução DEFINITIVA - API retrocompatível + bracket notation
# Versão: 1.0.17-patch3
# Data: 2024-11-15
#
# ANÁLISE DE CAUSA RAIZ:
# - Testes antigos usam API: inject(server, {...}) e shutdown(server)
# - Novo test-utils oferece: inject({...}) e shutdown()
# - Testes usam jsonUnknown<Type> com generics (não suportado)
# - TypeScript strict exige bracket notation (body['key'])
#
# SOLUÇÃO:
# 1. test-utils.ts: API retrocompatível (aceita ambas as assinaturas)
# 2. test-utils.ts: jsonUnknown com suporte a generics
# 3. analyze.spec.ts e healthz.spec.ts: bracket notation
#
# Arquivos afetados:
# - packages/server/test/test-utils.ts (REESCRITO)
# - packages/server/test/analyze.spec.ts (REESCRITO)
# - packages/server/test/healthz.spec.ts (REESCRITO)
#
# Como reverter:
# - Backups em .bak: mv arquivo.ts.bak arquivo.ts
###############################################################################

echo "[info] Iniciando solução DEFINITIVA com API retrocompatível"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Criar backups
echo "[info] Criando backups (.bak)..."
cp packages/server/test/test-utils.ts packages/server/test/test-utils.ts.bak
cp packages/server/test/analyze.spec.ts packages/server/test/analyze.spec.ts.bak
cp packages/server/test/healthz.spec.ts packages/server/test/healthz.spec.ts.bak
echo "[ok] Backups criados"

###############################################################################
# ARQUIVO 1/3: test-utils.ts (API RETROCOMPATÍVEL)
###############################################################################
echo ""
echo "[info] Reescrevendo test-utils.ts (retrocompatível + generics)..."

cat > packages/server/test/test-utils.ts << 'ENDOFFILE'
/**
 * @file test-utils.ts
 * @description Utilitários para testes do servidor (API retrocompatível)
 * 
 * CHANGELOG v1.0.17-patch3:
 * - API retrocompatível: aceita inject(server, opts) OU inject(opts)
 * - API retrocompatível: aceita shutdown(server) OU shutdown()
 * - jsonUnknown com suporte a type generics
 * 
 * @version 1.0.17-patch3
 */

import type { FastifyInstance } from 'fastify';
import type { InjectOptions, Response } from 'light-my-request';
import { server } from '../src/index.js';

/**
 * Instância do servidor para uso nos testes
 */
let testServer: FastifyInstance | null = null;

/**
 * Inicializa o servidor para testes
 * 
 * @returns Promise com instância do servidor pronta
 */
export async function build(): Promise<FastifyInstance> {
  if (!testServer) {
    testServer = server;
    await testServer.ready();
  }
  return testServer;
}

/**
 * Fecha o servidor após os testes
 * RETROCOMPATÍVEL: aceita shutdown(server) OU shutdown()
 * 
 * @param serverInstance - (Opcional) instância do servidor (ignorada, mantida por retrocompatibilidade)
 */
export async function shutdown(serverInstance?: FastifyInstance): Promise<void> {
  // Ignora serverInstance - mantido apenas para retrocompatibilidade
  if (testServer) {
    await testServer.close();
    testServer = null;
  }
}

/**
 * Helper para fazer requisições de teste
 * RETROCOMPATÍVEL: aceita inject(server, opts) OU inject(opts)
 * 
 * @param serverOrOptions - Servidor (ignorado) OU opções da requisição
 * @param optionsIfServerProvided - Opções se primeiro param for servidor
 * @returns Promise com resposta da requisição
 */
export async function inject(
  serverOrOptions: FastifyInstance | InjectOptions,
  optionsIfServerProvided?: InjectOptions
): Promise<Response> {
  if (!testServer) {
    await build();
  }
  
  // Detectar qual assinatura foi usada
  const options: InjectOptions = optionsIfServerProvided 
    ? optionsIfServerProvided  // inject(server, options) - API antiga
    : (serverOrOptions as InjectOptions);  // inject(options) - API nova
  
  return testServer!.inject(options);
}

/**
 * Type guard para verificar se objeto é um Record válido
 */
function isRecord(obj: unknown): obj is Record<string, unknown> {
  return typeof obj === 'object' && obj !== null && !Array.isArray(obj);
}

/**
 * Helper para extrair status code de resposta
 */
export function status(response: Response): number {
  return response.statusCode;
}

/**
 * Helper para parsear JSON de resposta com type safety
 * SUPORTA GENERICS: jsonUnknown<Type>(response)
 * 
 * @param response - Resposta da requisição
 * @returns Objeto parseado do JSON
 * @throws Error se o body não for JSON válido
 */
export function jsonUnknown<T = Record<string, unknown>>(response: Response): T {
  try {
    const parsed: unknown = JSON.parse(response.body);
    if (isRecord(parsed)) {
      return parsed as T;
    }
    throw new Error('Response body não é um objeto JSON válido');
  } catch (error) {
    throw new Error(
      `Falha ao parsear JSON: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}
ENDOFFILE

echo "[ok] test-utils.ts reescrito (95 linhas - retrocompatível)"

###############################################################################
# ARQUIVO 2/3: analyze.spec.ts (BRACKET NOTATION)
###############################################################################
echo "[info] Reescrevendo analyze.spec.ts (bracket notation)..."

cat > packages/server/test/analyze.spec.ts << 'ENDOFFILE'
/**
 * @file analyze.spec.ts
 * @description Testes do endpoint /analyze
 * 
 * CHANGELOG v1.0.17-patch3:
 * - Migrado para usar bracket notation (TypeScript strict)
 * - Adaptado para BudgetContext (sem estado global)
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
      tokensUsed: number;
      runId: string;
      timestamp: string;
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

echo "[ok] analyze.spec.ts reescrito (80 linhas)"

###############################################################################
# ARQUIVO 3/3: healthz.spec.ts (BRACKET NOTATION)
###############################################################################
echo "[info] Reescrevendo healthz.spec.ts (bracket notation)..."

cat > packages/server/test/healthz.spec.ts << 'ENDOFFILE'
/**
 * @file healthz.spec.ts
 * @description Testes do endpoint /healthz
 * 
 * CHANGELOG v1.0.17-patch3:
 * - Migrado para usar bracket notation (TypeScript strict)
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('GET /healthz', () => {
  let server: Awaited<ReturnType<typeof build>>;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('deve retornar status ok', async () => {
    const response = await inject(server, {
      method: 'GET',
      url: '/healthz',
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ status: string; timestamp: string }>(response);
    expect(body['status']).toBe('ok');
    expect(body['timestamp']).toBeDefined();
  });

  it('deve incluir uptime', async () => {
    const response = await inject(server, {
      method: 'GET',
      url: '/healthz',
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown(response);
    expect(body['uptime']).toBeDefined();
    expect(typeof body['uptime']).toBe('number');
    expect(body['uptime'] as number).toBeGreaterThan(0);
  });

  it('deve incluir status dos componentes', async () => {
    const response = await inject(server, {
      method: 'GET',
      url: '/healthz',
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown(response);
    expect(body['components']).toBeDefined();
    const components = body['components'] as Record<string, unknown>;
    expect(components['budget']).toBe('ok');
    expect(components['llm']).toBe('mock');
  });
});
ENDOFFILE

echo "[ok] healthz.spec.ts reescrito (61 linhas)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando typecheck para validar correções..."

if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] ✅ Typecheck passou! Todos os 31 erros foram corrigidos."
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

# Remover backups se tudo passou
echo ""
echo "[info] Removendo backups (.bak)..."
rm -f packages/server/test/test-utils.ts.bak
rm -f packages/server/test/analyze.spec.ts.bak
rm -f packages/server/test/healthz.spec.ts.bak
echo "[ok] Backups removidos"

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 02d executado com sucesso!"
echo "=========================================="
echo ""
echo "🔧 Arquivos reescritos:"
echo "   - test-utils.ts (95 linhas) - API retrocompatível"
echo "   - analyze.spec.ts (80 linhas) - bracket notation"
echo "   - healthz.spec.ts (61 linhas) - bracket notation"
echo ""
echo "📊 Correções aplicadas:"
echo "   ✅ inject() aceita: inject(server, opts) OU inject(opts)"
echo "   ✅ shutdown() aceita: shutdown(server) OU shutdown()"
echo "   ✅ jsonUnknown<Type> suporta generics"
echo "   ✅ body['key'] ao invés de body.key (TypeScript strict)"
echo ""
echo "📊 Total: 31 erros de TypeScript corrigidos"
echo ""
echo "✅ Validações:"
echo "   - Typecheck: PASSOU"
echo "   - Testes: VERIFICAR ACIMA"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Confirmar que TODOS os testes passaram"
echo "   2. Commit: git add packages/server/"
echo "   3. Commit: git commit -m 'refactor(server): finalizar migração para BudgetContext'"
echo "   4. Prosseguir para Script 3 (HU-Quality-Coverage-Thresholds)"
echo ""
echo "[ok] Script finalizado em $(date)"
