#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: fix_typecheck_errors.sh
# Objetivo: Corrigir erros de TypeScript após merge (imports duplicados e tipos)
# ==============================================================================

echo "[info] Corrigindo erros de typecheck no packages/server"

# ==============================================================================
# 1. Corrigir analyze.spec.ts - Remover imports duplicados
# ==============================================================================
echo "[info] Corrigindo packages/server/test/analyze.spec.ts"

cat > packages/server/test/analyze.spec.ts << 'EOF'
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('POST /analyze - Happy Path (200)', () => {
  let server: FastifyInstance;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('AC1: should return 200 with valid text and maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string; tokensUsed: number; runId: string; timestamp: string }>(response);
    expect(body.summary).toBeDefined();
    expect(body.summary.length).toBeLessThanOrEqual(10);
    expect(body.tokensUsed).toBeGreaterThan(0);
    expect(body.runId).toMatch(/^run-/);
    expect(body.timestamp).toBeDefined();
  });

  it('AC2: should use default maxLen (100) when omitted', async () => {
    const longText = 'a'.repeat(150);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBeLessThanOrEqual(100);
  });

  it('AC3: should include all required fields in response', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test analysis', maxLen: 50 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string; tokensUsed: number; runId: string; timestamp: string }>(response);
    expect(body).toHaveProperty('summary');
    expect(body).toHaveProperty('tokensUsed');
    expect(body).toHaveProperty('runId');
    expect(body).toHaveProperty('timestamp');
  });

  it('should handle text with multiple tokens correctly', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'One two three four five', maxLen: 100 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ tokensUsed: number }>(response);
    expect(body.tokensUsed).toBeGreaterThan(1);
  });

  it('should handle maxLen at minimum boundary (1)', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello', maxLen: 1 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBe(1);
  });

  it('should handle maxLen at maximum boundary (1000)', async () => {
    const longText = 'a'.repeat(2000);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText, maxLen: 1000 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBeLessThanOrEqual(1000);
  });
});
EOF

echo "[ok] analyze.spec.ts corrigido"

# ==============================================================================
# 2. Corrigir healthz.spec.ts - Remover imports duplicados
# ==============================================================================
echo "[info] Corrigindo packages/server/test/healthz.spec.ts"

cat > packages/server/test/healthz.spec.ts << 'EOF'
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('GET /healthz', () => {
  let server: FastifyInstance;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('should return 200 with status ok', async () => {
    const response = await inject(server, {
      method: 'GET',
      url: '/healthz',
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ status: string; timestamp: string }>(response);
    expect(body.status).toBe('ok');
    expect(body.timestamp).toBeDefined();
  });
});
EOF

echo "[ok] healthz.spec.ts corrigido"

# ==============================================================================
# 3. Corrigir test-utils.ts - Remover registerRoutes e corrigir tipos
# ==============================================================================
echo "[info] Corrigindo packages/server/test/test-utils.ts"

cat > packages/server/test/test-utils.ts << 'EOF'
/**
 * Test utilities for server package
 * Provides strongly-typed helpers for Fastify testing
 */

import type { FastifyInstance } from 'fastify';
import { createServer } from '../src/index.js';

/**
 * Injectable request configuration
 */
export interface InjectableRequest {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';
  url: string;
  payload?: unknown;
  headers?: Record<string, string>;
}

/**
 * Test response wrapper with typed body parsing
 */
export interface TestResponse {
  statusCode: number;
  headers: Record<string, string | string[] | undefined>;
  body: string;
  payload: string;
}

/**
 * Build a test server instance
 */
export async function build(): Promise<FastifyInstance> {
  const server = await createServer();
  return server;
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
    headers: response.headers as Record<string, string | string[] | undefined>,
    body: response.body,
    payload: response.payload as string,
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
# 4. Validar correções
# ==============================================================================
echo ""
echo "[info] Validando correções..."

echo "[info] Rodando typecheck..."
if pnpm -C packages/server run typecheck; then
  echo "[ok] Typecheck passou!"
else
  echo "[fail] Typecheck ainda falha"
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
echo "[ok] ✓ Imports duplicados removidos"
echo "[ok] ✓ registerRoutes removido"
echo "[ok] ✓ Tipos corrigidos"
echo "[ok] ✓ Typecheck OK"
echo "[ok] ✓ Testes OK"
echo ""
echo "[info] Execute o checklist completo:"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
