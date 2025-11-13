/**
 * Test suite for server error handling (5xx)
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';
import { resetBudget, recordUsage } from '../src/budget.js';
import type { ErrorResponse } from '../src/index.js';

describe('POST /analyze - Server Errors (5xx)', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await build();
  });

  afterAll(async () => {
    await shutdown(app);
  });

  beforeEach(() => {
    resetBudget();
  });

  describe('Error Response Structure', () => {
    it('should include required error fields', async () => {
      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: '' }, // Will trigger 400 for testing structure
      });

      const body = jsonUnknown<ErrorResponse>(response);
      expect(body).toHaveProperty('error');
      expect(body).toHaveProperty('code');
      expect(body).toHaveProperty('requestId');
      expect(body).toHaveProperty('timestamp');
      expect(body.requestId).toMatch(/^req-/);
    });

    it('should have ISO timestamp', async () => {
      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: '' },
      });

      const body = jsonUnknown<ErrorResponse>(response);
      expect(body.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
    });
  });

  describe('Fallback Mechanism', () => {
    it('should return result even when using fallback', async () => {
      // Current implementation doesn't fail, but structure is in place
      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: 'Test fallback', maxLen: 50 },
      });

      expect(status(response)).toBe(200);
      const body = jsonUnknown<{ summary: string; tokensUsed: number }>(response);
      expect(body.summary).toBeDefined();
      expect(body.tokensUsed).toBeGreaterThanOrEqual(0);
    });
  });

  describe('Budget Exceeded (402)', () => {
    it('should return 402 when budget is exceeded', async () => {
      // Simular orçamento já excedido usando recordUsage
      // R$ 5.00 de limite, gastar R$ 5.00 para exceder
      recordUsage(5000000); // 5M tokens = R$ 5.00

      // Agora qualquer requisição deve retornar 402
      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: 'This should exceed budget', maxLen: 100 },
      });

      expect(status(response)).toBe(402);
      const body = jsonUnknown<ErrorResponse>(response);
      expect(body.error).toContain('Orçamento insuficiente');
      expect(body.code).toBe('BUDGET_EXCEEDED');
    });

    it('should include budget details in error message', async () => {
      // Simular orçamento já excedido
      recordUsage(5000000); // 5M tokens = R$ 5.00

      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: 'Test budget details', maxLen: 100 },
      });

      const body = jsonUnknown<ErrorResponse>(response);
      expect(body.error).toContain('R$');
      expect(body.error).toContain('Necessário');
      expect(body.error).toContain('Disponível');
    });
  });

  describe('Error Code Categorization', () => {
    it('should use VALIDATION_ERROR for 400s', async () => {
      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: '' },
      });

      const body = jsonUnknown<ErrorResponse>(response);
      expect(body.code).toBe('VALIDATION_ERROR');
    });

    it('should use BUDGET_EXCEEDED for 402', async () => {
      // Simular orçamento já excedido
      recordUsage(5000000); // 5M tokens = R$ 5.00

      const response = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: 'Test error code', maxLen: 100 },
      });

      const body = jsonUnknown<ErrorResponse>(response);
      expect(body.code).toBe('BUDGET_EXCEEDED');
    });
  });
});
