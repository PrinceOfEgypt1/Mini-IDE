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
