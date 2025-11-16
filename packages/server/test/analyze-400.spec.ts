/**
 * @file analyze-400.spec.ts
 * @description Testes de validação 4xx para endpoint /analyze
 *
 * CHANGELOG v1.0.17:
 * - Removido uso de resetBudget (não existe mais - budget agora é por contexto)
 * - Removido tipo ErrorResponse (não exportado)
 * - Usando jsonUnknown<T>() para parse seguro da resposta
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { server } from '../src/index.js';
import { jsonUnknown } from './test-utils.js';

interface ErrorBody {
  error: string;
  message: string;
  requestId: string;
  timestamp: string;
}

describe('POST /analyze - Validações 4xx', () => {
  beforeAll(async () => {
    await server.ready();
  });

  afterAll(async () => {
    await server.close();
  });

  describe('400 - Bad Request', () => {
    it('deve retornar 400 quando text estiver ausente', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          maxLen: 100,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('text');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando text estiver vazio', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: '',
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('vazio');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando text for apenas espaços', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: '   ',
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('vazio');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando maxLen < 1', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste',
          maxLen: 0,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('maxLen');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando maxLen > 1000', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste',
          maxLen: 1001,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('maxLen');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });
  });
});
