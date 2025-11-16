/**
 * @file budget.spec.ts
 * @description Testes para o sistema de Budget usando BudgetContext
 *
 * CHANGELOG v1.0.17-patch1:
 * - Adicionados non-null assertions (!) nos arrays para TypeScript strict
 *
 * Cobertura de testes:
 * - BudgetContext: criação, verificação, registro de uso, limites
 * - Isolamento entre contextos
 * - Determinismo: 10 execuções seguidas sem flakiness
 * - Edge cases: budget zero, negativo, excedido
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { createBudgetContext, type BudgetContext } from '../src/budget.js';

describe('BudgetContext', () => {
  describe('Criação de contexto', () => {
    it('deve criar contexto com limite válido', () => {
      const context = createBudgetContext(10.0);
      const state = context.getState();

      expect(state.limit).toBe(10.0);
      expect(state.used).toBe(0);
      expect(state.remaining).toBe(10.0);
    });

    it('deve rejeitar limite zero', () => {
      expect(() => createBudgetContext(0)).toThrow('Budget limit deve ser > 0');
    });

    it('deve rejeitar limite negativo', () => {
      expect(() => createBudgetContext(-5)).toThrow('Budget limit deve ser > 0');
    });

    it('deve aceitar limites decimais precisos', () => {
      const context = createBudgetContext(0.01);
      expect(context.getLimit()).toBe(0.01);
    });
  });

  describe('Verificação de budget (checkBudget)', () => {
    let context: BudgetContext;

    beforeEach(() => {
      context = createBudgetContext(10.0);
    });

    it('deve permitir quando budget é suficiente', () => {
      expect(context.checkBudget(5.0)).toBe(true);
    });

    it('deve permitir quando custo exato igual ao disponível', () => {
      expect(context.checkBudget(10.0)).toBe(true);
    });

    it('deve negar quando custo excede disponível', () => {
      expect(context.checkBudget(15.0)).toBe(false);
    });

    it('deve considerar budget já usado', () => {
      context.recordUsage(7.0);
      expect(context.checkBudget(4.0)).toBe(false);
      expect(context.checkBudget(3.0)).toBe(true);
    });

    it('deve negar custo negativo', () => {
      expect(context.checkBudget(-1)).toBe(false);
    });

    it('deve negar custo zero', () => {
      expect(context.checkBudget(0)).toBe(false);
    });
  });

  describe('Registro de uso (recordUsage)', () => {
    let context: BudgetContext;

    beforeEach(() => {
      context = createBudgetContext(10.0);
    });

    it('deve registrar uso corretamente', () => {
      context.recordUsage(3.5);
      const state = context.getState();

      expect(state.used).toBe(3.5);
      expect(state.remaining).toBe(6.5);
    });

    it('deve acumular múltiplos usos', () => {
      context.recordUsage(2.0);
      context.recordUsage(3.5);
      context.recordUsage(1.5);

      const state = context.getState();
      expect(state.used).toBe(7.0);
      expect(state.remaining).toBe(3.0);
    });

    it('deve permitir registrar até o limite exato', () => {
      context.recordUsage(10.0);
      const state = context.getState();

      expect(state.used).toBe(10.0);
      expect(state.remaining).toBe(0);
    });

    it('deve lançar erro ao exceder limite', () => {
      context.recordUsage(7.0);

      expect(() => context.recordUsage(4.0)).toThrow(
        'Tentativa de registrar uso que excede budget disponível',
      );
    });

    it('deve rejeitar valores negativos', () => {
      expect(() => context.recordUsage(-1)).toThrow('Valor de uso deve ser > 0');
    });

    it('deve rejeitar valor zero', () => {
      expect(() => context.recordUsage(0)).toThrow('Valor de uso deve ser > 0');
    });
  });

  describe('Isolamento entre contextos', () => {
    it('contextos diferentes devem ter budgets isolados', () => {
      const context1 = createBudgetContext(10.0);
      const context2 = createBudgetContext(20.0);

      context1.recordUsage(5.0);

      expect(context1.getState().used).toBe(5.0);
      expect(context1.getState().remaining).toBe(5.0);

      expect(context2.getState().used).toBe(0);
      expect(context2.getState().remaining).toBe(20.0);
    });

    it('múltiplos contextos simultâneos devem ser independentes', () => {
      const contexts = [
        createBudgetContext(10.0),
        createBudgetContext(15.0),
        createBudgetContext(20.0),
      ];

      // CORRIGIDO: non-null assertions para TypeScript strict
      contexts[0]!.recordUsage(3.0);
      contexts[1]!.recordUsage(5.0);
      contexts[2]!.recordUsage(7.0);

      expect(contexts[0]!.getState().used).toBe(3.0);
      expect(contexts[1]!.getState().used).toBe(5.0);
      expect(contexts[2]!.getState().used).toBe(7.0);
    });
  });

  describe('Getters', () => {
    let context: BudgetContext;

    beforeEach(() => {
      context = createBudgetContext(10.0);
    });

    it('getLimit deve retornar limite correto', () => {
      expect(context.getLimit()).toBe(10.0);
    });

    it('getUsed deve refletir uso acumulado', () => {
      expect(context.getUsed()).toBe(0);
      context.recordUsage(4.5);
      expect(context.getUsed()).toBe(4.5);
    });

    it('getState deve retornar snapshot completo', () => {
      context.recordUsage(3.0);
      const state = context.getState();

      expect(state).toEqual({
        limit: 10.0,
        used: 3.0,
        remaining: 7.0,
      });
    });
  });

  describe('Determinismo (10 execuções)', () => {
    it('deve produzir resultados idênticos em 10 execuções', () => {
      const results: number[] = [];

      for (let i = 0; i < 10; i++) {
        const context = createBudgetContext(100.0);
        context.recordUsage(25.5);
        context.recordUsage(10.3);
        context.recordUsage(15.7);

        results.push(context.getUsed());
      }

      // Todas as 10 execuções devem ter o mesmo resultado
      const expectedSum = 25.5 + 10.3 + 15.7;
      results.forEach((result) => {
        expect(result).toBeCloseTo(expectedSum, 10); // 10 casas decimais
      });
    });

    it('deve manter isolamento em 10 execuções paralelas simuladas', () => {
      const contexts = Array.from({ length: 10 }, (_, i) => createBudgetContext((i + 1) * 10.0));

      contexts.forEach((context, i) => {
        context.recordUsage((i + 1) * 2.5);
      });

      contexts.forEach((context, i) => {
        expect(context.getUsed()).toBeCloseTo((i + 1) * 2.5, 10);
        expect(context.getLimit()).toBe((i + 1) * 10.0);
      });
    });
  });

  describe('Edge cases e precisão numérica', () => {
    it('deve lidar com valores decimais pequenos', () => {
      const context = createBudgetContext(0.1);
      context.recordUsage(0.03);
      context.recordUsage(0.05);

      const state = context.getState();
      expect(state.used).toBeCloseTo(0.08, 10);
      expect(state.remaining).toBeCloseTo(0.02, 10);
    });

    it('deve lidar com limite grande e usos pequenos', () => {
      const context = createBudgetContext(10000.0);
      for (let i = 0; i < 100; i++) {
        context.recordUsage(0.01);
      }

      expect(context.getUsed()).toBeCloseTo(1.0, 10);
      expect(context.getState().remaining).toBeCloseTo(9999.0, 10);
    });

    it('deve prevenir erros de arredondamento em somas repetidas', () => {
      const context = createBudgetContext(1.0);

      // 10 vezes 0.1 deveria dar exatamente 1.0
      for (let i = 0; i < 10; i++) {
        context.recordUsage(0.1);
      }

      expect(context.getUsed()).toBeCloseTo(1.0, 10);
      expect(context.getState().remaining).toBeCloseTo(0, 10);
    });
  });
});
