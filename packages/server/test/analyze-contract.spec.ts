/**
 * @fileoverview Testes do contrato oficial do endpoint POST /analyze
 * @module @mini-ide/server/test/analyze-contract
 *
 * Estes testes validam que o endpoint /analyze retorna respostas que
 * aderem ao contrato oficial definido em AnalyzeResponse.
 *
 * HU: HU-Server-Analyze-Shape-Contract
 */

import { describe, it, expect } from 'vitest';
import { isAnalyzeResponse, REQUIRED_FIELDS, OPTIONAL_FIELDS } from '@mini-ide/shared';

describe('Contrato do endpoint POST /analyze', () => {
  describe('isAnalyzeResponse - validação de tipo', () => {
    it('deve aceitar objeto com todos os campos obrigatórios', () => {
      const validResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(validResponse)).toBe(true);
    });

    it('deve aceitar objeto com campos obrigatórios + opcionais', () => {
      const validResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
        budgetUsed: 0.05,
        budgetRemaining: 4.95,
      };

      expect(isAnalyzeResponse(validResponse)).toBe(true);
    });

    it('deve rejeitar objeto sem summary', () => {
      const invalidResponse = {
        // summary: 'Resumo de teste', // AUSENTE
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar objeto sem inputLength', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        // inputLength: 100, // AUSENTE
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar objeto sem outputLength', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        // outputLength: 50, // AUSENTE
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar objeto sem requestId', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        // requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde', // AUSENTE
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar objeto sem timestamp', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        // timestamp: '2024-11-16T14:30:00.000Z' // AUSENTE
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar inputLength negativo', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: -1, // INVÁLIDO
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar outputLength negativo', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: -1, // INVÁLIDO
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar budgetUsed negativo', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
        budgetUsed: -0.5, // INVÁLIDO
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar budgetRemaining negativo', () => {
      const invalidResponse = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
        budgetRemaining: -1.0, // INVÁLIDO
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('deve rejeitar null', () => {
      expect(isAnalyzeResponse(null)).toBe(false);
    });

    it('deve rejeitar undefined', () => {
      expect(isAnalyzeResponse(undefined)).toBe(false);
    });

    it('deve rejeitar string', () => {
      expect(isAnalyzeResponse('not an object')).toBe(false);
    });

    it('deve rejeitar número', () => {
      expect(isAnalyzeResponse(123)).toBe(false);
    });

    it('deve rejeitar array', () => {
      expect(isAnalyzeResponse([])).toBe(false);
    });
  });

  describe('REQUIRED_FIELDS e OPTIONAL_FIELDS', () => {
    it('deve ter os 5 campos obrigatórios corretos', () => {
      expect(REQUIRED_FIELDS).toEqual([
        'summary',
        'inputLength',
        'outputLength',
        'requestId',
        'timestamp',
      ]);
    });

    it('deve ter os 2 campos opcionais corretos', () => {
      expect(OPTIONAL_FIELDS).toEqual(['budgetUsed', 'budgetRemaining']);
    });

    it('não deve haver overlap entre campos obrigatórios e opcionais', () => {
      // Converter para Set de strings para evitar problemas de tipo
      const requiredSet = new Set<string>(REQUIRED_FIELDS as readonly string[]);
      const optionalSet = new Set<string>(OPTIONAL_FIELDS as readonly string[]);

      const intersection = [...requiredSet].filter((field) => optionalSet.has(field));

      expect(intersection.length).toBe(0);
    });
  });

  describe('Validação de tipos dos campos', () => {
    it('summary deve ser string', () => {
      const invalidResponse = {
        summary: 123, // TIPO ERRADO
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('inputLength deve ser number', () => {
      const invalidResponse = {
        summary: 'Resumo',
        inputLength: '100', // TIPO ERRADO
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('outputLength deve ser number', () => {
      const invalidResponse = {
        summary: 'Resumo',
        inputLength: 100,
        outputLength: '50', // TIPO ERRADO
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('requestId deve ser string', () => {
      const invalidResponse = {
        summary: 'Resumo',
        inputLength: 100,
        outputLength: 50,
        requestId: 12345, // TIPO ERRADO
        timestamp: '2024-11-16T14:30:00.000Z',
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });

    it('timestamp deve ser string', () => {
      const invalidResponse = {
        summary: 'Resumo',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: 1700145000000, // TIPO ERRADO
      };

      expect(isAnalyzeResponse(invalidResponse)).toBe(false);
    });
  });

  describe('Resiliência a campos extras (extensibilidade futura)', () => {
    it('deve aceitar objeto com campos extras não documentados', () => {
      const responseWithExtra = {
        summary: 'Resumo de teste',
        inputLength: 100,
        outputLength: 50,
        requestId: 'a1b2c3d4-e5f6-4789-a012-3456789abcde',
        timestamp: '2024-11-16T14:30:00.000Z',
        // Campos extras que podem ser adicionados no futuro
        modelUsed: 'deepseek-v3',
        processingTime: 150,
        cacheHit: false,
      };

      // O contrato é resiliente: campos extras não quebram a validação
      expect(isAnalyzeResponse(responseWithExtra)).toBe(true);
    });
  });
});
