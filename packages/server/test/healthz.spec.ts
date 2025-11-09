import { buildServer, shutdown } from './test-utils';
import { describe, it, expect } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildServer, shutdown, inject, status, jsonUnknown } from './test-utils.js';

/**
 * Shape esperado da resposta /healthz
 */
interface HealthzBody {
  status: string;
  timestamp: string;
}

/**
 * Type guard com validação em runtime
 */
function assertHealthzBody(u: unknown): asserts u is HealthzBody {
  if (typeof u !== 'object' || u === null) {
    throw new Error('body não é objeto');
  }
  const o = u as Record<string, unknown>;
  if (typeof o['status'] !== 'string') {
    throw new Error('status inválido');
  }
  if (typeof o['timestamp'] !== 'string') {
    throw new Error('timestamp inválido');
  }
}

describe('server :: /healthz', () => {
  it('retorna status ok e timestamp ISO-8601', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const res = await inject(app, '/healthz');
      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertHealthzBody(bodyUnknown);

      // Usar ['key'] para evitar TS4111
      expect(bodyUnknown['status']).toBe('ok');
      expect(bodyUnknown['timestamp']).toBeTruthy();

      // Valida formato ISO-8601
      expect(() => new Date(bodyUnknown['timestamp'])).not.toThrow();
      expect(bodyUnknown['timestamp']).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
    } finally {
      await shutdown(app);
    }
  });
});
