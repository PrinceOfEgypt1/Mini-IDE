#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: fix_typecheck_errors_v4.sh
# Objetivo: Corrigir tipo dos headers (aceitar number também)
# ==============================================================================

echo "[info] Corrigindo test-utils.ts - tipo dos headers"

# ==============================================================================
# Corrigir test-utils.ts - Ajustar tipo dos headers
# ==============================================================================
cat > packages/server/test/test-utils.ts << 'EOF'
/**
 * Test utilities for server package
 * Provides strongly-typed helpers for Fastify testing
 */

import Fastify, { type FastifyInstance } from 'fastify';
import { createServer } from '../src/index.js';

/**
 * Injectable request configuration
 */
export interface InjectableRequest {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';
  url: string;
  payload?: string | object;
  headers?: Record<string, string>;
}

/**
 * Test response wrapper with typed body parsing
 */
export interface TestResponse {
  statusCode: number;
  headers: Record<string, string | string[] | number | undefined>;
  body: string;
}

/**
 * Build a test server instance
 */
export async function build(): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });
  await createServer(app);
  await app.ready();
  return app;
}

/**
 * Shutdown server gracefully
 */
export async function shutdown(server: FastifyInstance): Promise<void> {
  await server.close();
}

/**
 * Inject HTTP request into server
 */
export async function inject(
  server: FastifyInstance,
  request: InjectableRequest
): Promise<TestResponse> {
  const response = await server.inject({
    method: request.method,
    url: request.url,
    payload: request.payload,
    headers: request.headers,
  });

  return {
    statusCode: response.statusCode,
    headers: response.headers,
    body: response.body,
  };
}

/**
 * Extract status code from response
 */
export function status(response: TestResponse): number {
  return response.statusCode;
}

/**
 * Parse JSON body with type guard validation
 */
export function jsonUnknown<T extends Record<string, unknown>>(
  response: TestResponse
): T {
  const parsed = JSON.parse(response.body) as unknown;
  
  // Type guard: ensure parsed is an object
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    throw new TypeError('Expected JSON response to be a non-null object');
  }
  
  // Narrow to Record<string, unknown>
  return parsed as T;
}
EOF

echo "[ok] test-utils.ts corrigido"

# ==============================================================================
# Validar correções
# ==============================================================================
echo ""
echo "[info] Validando correções..."

echo "[info] Rodando typecheck..."
if pnpm -C packages/server run typecheck; then
  echo "[ok] Typecheck passou!"
else
  echo "[fail] Typecheck ainda falha"
  echo "[info] Mostrando erros detalhados..."
  pnpm -C packages/server run typecheck 2>&1 || true
  exit 1
fi

echo "[info] Rodando build..."
if pnpm -C packages/server run build; then
  echo "[ok] Build passou!"
else
  echo "[fail] Build falhou"
  exit 1
fi

echo "[info] Rodando testes..."
if pnpm -C packages/server run test; then
  echo "[ok] Testes passaram!"
else
  echo "[fail] Testes falharam"
  exit 1
fi

echo ""
echo "[ok] =========================================="
echo "[ok] CORREÇÃO CONCLUÍDA ✅"
echo "[ok] =========================================="
echo "[ok] ✓ Headers: aceita number agora"
echo "[ok] ✓ Typecheck OK"
echo "[ok] ✓ Build OK"
echo "[ok] ✓ Testes OK"
echo ""
echo "[info] Commitar mudanças:"
echo "  git add packages/server/test/"
echo "  git commit -m 'fix(server-tests): corrigir tipos após merge'"
echo "  git push"
echo ""
echo "[info] Execute o checklist completo:"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
