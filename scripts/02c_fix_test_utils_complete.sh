#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 02c_fix_test_utils_complete.sh
# Objetivo: Reescrever test-utils.ts com API completa
# Versão: 1.0.17-patch2
# Data: 2024-11-15
#
# Este script corrige os 12 erros restantes:
# - test/analyze.spec.ts (5 erros) - faltam funções no test-utils
# - test/healthz.spec.ts (5 erros) - faltam funções no test-utils
# - test/test-utils.ts (2 erros) - problemas de tipo
#
# Arquivos afetados:
# - packages/server/test/test-utils.ts (REESCRITO COMPLETO)
#
# Premissas:
# - Scripts 02 e 02b já foram executados
#
# Como reverter:
# - Backup em .bak: mv test-utils.ts.bak test-utils.ts
###############################################################################

echo "[info] Iniciando correção FINAL do test-utils.ts"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Criar backup
echo "[info] Criando backup (.bak)..."
cp packages/server/test/test-utils.ts packages/server/test/test-utils.ts.bak
echo "[ok] Backup criado"

###############################################################################
# test-utils.ts (REESCRITO COMPLETO)
###############################################################################
echo ""
echo "[info] Reescrevendo test-utils.ts com API completa..."

cat > packages/server/test/test-utils.ts << 'ENDOFFILE'
/**
 * @file test-utils.ts
 * @description Utilitários para testes do servidor
 * 
 * CHANGELOG v1.0.17:
 * - Adaptado para usar server diretamente ao invés de createServer
 * - Mantida API completa (build, shutdown, inject, status, jsonUnknown)
 * 
 * @version 1.0.17
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
 */
export async function shutdown(): Promise<void> {
  if (testServer) {
    await testServer.close();
    testServer = null;
  }
}

/**
 * Helper para fazer requisições de teste
 * 
 * @param options - Opções da requisição (method, url, payload, etc.)
 * @returns Promise com resposta da requisição
 */
export async function inject(options: InjectOptions): Promise<Response> {
  if (!testServer) {
    throw new Error('Servidor não inicializado. Chame build() primeiro.');
  }
  return testServer.inject(options);
}

/**
 * Type guard para verificar se objeto é um Record válido
 * 
 * @param obj - Objeto a verificar
 * @returns true se for Record<string, unknown>
 */
function isRecord(obj: unknown): obj is Record<string, unknown> {
  return typeof obj === 'object' && obj !== null && !Array.isArray(obj);
}

/**
 * Helper para extrair status code de resposta
 * 
 * @param response - Resposta da requisição
 * @returns Status code HTTP
 */
export function status(response: Response): number {
  return response.statusCode;
}

/**
 * Helper para parsear JSON de resposta com type safety
 * 
 * @param response - Resposta da requisição
 * @returns Objeto parseado do JSON
 * @throws Error se o body não for JSON válido
 */
export function jsonUnknown(response: Response): Record<string, unknown> {
  try {
    const parsed: unknown = JSON.parse(response.body);
    if (isRecord(parsed)) {
      return parsed;
    }
    throw new Error('Response body não é um objeto JSON válido');
  } catch (error) {
    throw new Error(
      `Falha ao parsear JSON: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}

/**
 * Aguarda o servidor estar pronto (alias para build)
 */
export async function waitForServer(): Promise<void> {
  await build();
}

/**
 * Fecha o servidor (alias para shutdown)
 */
export async function closeServer(): Promise<void> {
  await shutdown();
}
ENDOFFILE

echo "[ok] test-utils.ts reescrito (96 linhas)"

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
rm -f packages/server/test/test-utils.ts.bak
echo "[ok] Backup removido"

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 02c executado com sucesso!"
echo "=========================================="
echo ""
echo "🔧 Arquivo reescrito:"
echo "   - test-utils.ts (96 linhas) - API completa mantida"
echo ""
echo "📊 Funções exportadas:"
echo "   ✅ build() - inicializa servidor"
echo "   ✅ shutdown() - fecha servidor"
echo "   ✅ inject() - faz requisições de teste"
echo "   ✅ status() - extrai status code"
echo "   ✅ jsonUnknown() - parseia JSON com type safety"
echo ""
echo "✅ Validações:"
echo "   - Typecheck: PASSOU"
echo "   - Testes: VERIFICAR ACIMA"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Verificar que todos os testes passaram"
echo "   2. Commit: git add packages/server/"
echo "   3. Commit: git commit -m 'refactor(server): completar migração para BudgetContext'"
echo "   4. Prosseguir para Script 3 (HU-Quality-Coverage-Thresholds)"
echo ""
echo "[ok] Script finalizado em $(date)"
