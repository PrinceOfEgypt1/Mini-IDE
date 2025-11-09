import { buildServer, shutdown } from './test-utils';
import { describe, it, expect } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildServer, shutdown, inject, status, jsonUnknown } from './test-utils.js';

/**
 * Shape esperado da resposta /analyze
 */
interface AnalyzeBody {
  summary: string;
  tokensUsed: number;
  runId: string;
  ts: string;
}

/**
 * Type guard com validação em runtime
 */
function assertAnalyzeBody(u: unknown): asserts u is AnalyzeBody {
  if (typeof u !== 'object' || u === null) {
    throw new Error('body não é objeto');
  }
  const o = u as Record<string, unknown>;
  if (typeof o['summary'] !== 'string') {
    throw new Error('summary inválido');
  }
  if (typeof o['tokensUsed'] !== 'number') {
    throw new Error('tokensUsed inválido');
  }
  if (typeof o['runId'] !== 'string') {
    throw new Error('runId inválido');
  }
  if (typeof o['ts'] !== 'string') {
    throw new Error('ts inválido');
  }
}

describe('POST /analyze - Happy Path (200)', () => {
  it('AC1: should return 200 with valid text and maxLen', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'Olá Mini-IDE!',
          maxLen: 10,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      // Usar ['key'] para evitar TS4111
      expect(bodyUnknown['summary'].length).toBeLessThanOrEqual(10);
      expect(bodyUnknown['summary']).toBe('Olá Mini-I');
      expect(bodyUnknown['tokensUsed']).toBe(2);
      expect(bodyUnknown['ts']).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
      expect(bodyUnknown['runId']).toMatch(/^run-[0-9a-f-]{36}$/);
    } finally {
      await shutdown(app);
    }
  });

  it('AC2: should use default maxLen (100) when omitted', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const longText = 'a'.repeat(150);

      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: longText,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      expect(bodyUnknown['summary'].length).toBe(100);
      expect(bodyUnknown['tokensUsed']).toBe(1);
    } finally {
      await shutdown(app);
    }
  });

  it('AC3: should include all required fields in response', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'Texto de teste',
          maxLen: 50,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      expect(bodyUnknown['summary']).toBeTruthy();
      expect(bodyUnknown['tokensUsed']).toBeGreaterThan(0);
      expect(bodyUnknown['runId']).toBeTruthy();
      expect(bodyUnknown['ts']).toBeTruthy();
    } finally {
      await shutdown(app);
    }
  });

  it('should handle text with multiple tokens correctly', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'Um dois três quatro cinco',
          maxLen: 100,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      expect(bodyUnknown['tokensUsed']).toBe(5);
    } finally {
      await shutdown(app);
    }
  });

  it('should handle maxLen at minimum boundary (1)', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'Teste',
          maxLen: 1,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      expect(bodyUnknown['summary']).toBe('T');
      expect(bodyUnknown['summary'].length).toBe(1);
    } finally {
      await shutdown(app);
    }
  });

  it('should handle maxLen at maximum boundary (1000)', async () => {
    const app: FastifyInstance = await buildServer();

    try {
      const longText = 'x'.repeat(2000);

      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: {
          text: longText,
          maxLen: 1000,
        },
      });

      expect(status(res)).toBe(200);

      const bodyUnknown = jsonUnknown(res);
      assertAnalyzeBody(bodyUnknown);

      expect(bodyUnknown['summary'].length).toBe(1000);
    } finally {
      await shutdown(app);
    }
  });
});
