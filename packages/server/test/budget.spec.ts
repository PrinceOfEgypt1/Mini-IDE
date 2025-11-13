/**
 * Test suite for budget management
 */

import { describe, it, expect, beforeEach } from 'vitest';
import {
  estimateCost,
  getBudgetState,
  checkBudget,
  recordUsage,
  resetBudget,
} from '../src/budget.js';
import { BudgetExceededError } from '../src/errors.js';

describe('Budget Management', () => {
  beforeEach(() => {
    // Reset budget before each test
    resetBudget();
  });

  describe('estimateCost', () => {
    it('should calculate cost for 1000 tokens', () => {
      const cost = estimateCost(1000);
      expect(cost).toBe(0.001);
    });

    it('should calculate cost for 500 tokens', () => {
      const cost = estimateCost(500);
      expect(cost).toBe(0.0005);
    });

    it('should handle zero tokens', () => {
      const cost = estimateCost(0);
      expect(cost).toBe(0);
    });
  });

  describe('getBudgetState', () => {
    it('should return initial budget state', () => {
      const state = getBudgetState();
      expect(state.limit).toBe(5.0);
      expect(state.used).toBe(0);
      expect(state.remaining).toBe(5.0);
    });

    it('should reflect used budget', () => {
      recordUsage(1000); // R$ 0.001
      const state = getBudgetState();
      expect(state.used).toBeCloseTo(0.001);
      expect(state.remaining).toBeCloseTo(4.999);
    });

    it('should support custom budget limit', () => {
      const state = getBudgetState(10.0);
      expect(state.limit).toBe(10.0);
      expect(state.remaining).toBe(10.0);
    });
  });

  describe('checkBudget', () => {
    it('should allow request within budget', () => {
      expect(() => checkBudget(1000)).not.toThrow();
    });

    it('should throw when budget exceeded', () => {
      recordUsage(5000000); // Use up entire budget
      expect(() => checkBudget(1000)).toThrow(BudgetExceededError);
    });

    it('should include budget details in error message', () => {
      recordUsage(5000000); // Use up budget
      try {
        checkBudget(1000);
        expect.fail('Should have thrown BudgetExceededError');
      } catch (error) {
        expect(error).toBeInstanceOf(BudgetExceededError);
        const budgetError = error as BudgetExceededError;
        expect(budgetError.message).toContain('Orçamento insuficiente');
        expect(budgetError.message).toContain('R$');
      }
    });
  });

  describe('recordUsage', () => {
    it('should accumulate usage', () => {
      recordUsage(1000); // R$ 0.001
      recordUsage(500); // R$ 0.0005
      const state = getBudgetState();
      expect(state.used).toBeCloseTo(0.0015);
    });

    it('should handle zero usage', () => {
      recordUsage(0);
      const state = getBudgetState();
      expect(state.used).toBe(0);
    });
  });
});
