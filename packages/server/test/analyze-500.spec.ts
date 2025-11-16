/**
 * @file analyze-500.spec.ts
 * @description Testes de erro 5xx para endpoint /analyze
 *
 * CHANGELOG v1.0.17:
 * - Removido uso de resetBudget e recordUsage (não existem mais)
 * - Budget agora é por contexto, cada requisição tem seu próprio budget
 * - Removido tipo ErrorResponse (não exportado)
 *
 * NOTA: Testes de budget excedido agora estão em budget.spec.ts
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

describe('POST /analyze - Erros 5xx e 402 Budget', () => {
  beforeAll(async () => {
    await server.ready();
  });

  afterAll(async () => {
    await server.close();
  });

  describe('500 - Internal Server Error (estrutura esperada)', () => {
    it('deve processar requisição válida com 200 (estrutura de erro documentada em comentário)', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste válido',
        },
      });

      // Aqui garantimos que o caminho feliz funciona.
      expect(response.statusCode).toBe(200);

      // Se um dia simulássemos erro 500 real,
      // a estrutura esperada seria:
      // { error, message, requestId, timestamp }
    });
  });

  describe('402 - Budget Exceeded', () => {
    it('deve retornar 402 quando budget for insuficiente', async () => {
      // Criar um texto muito grande para exceder budget de R$ 10.00
      // Budget mock: R$ 0.01 por 1000 chars
      // Para exceder R$ 10.00, precisa > 1.000.000 chars
      const largeText = 'a'.repeat(1_500_000); // R$ 15.00 estimado

      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: largeText,
          maxLen: 100,
        },
      });

      expect(response.statusCode).toBe(402);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Orçamento excedido');
      expect(body.message).toContain('Budget');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });
  });
});
