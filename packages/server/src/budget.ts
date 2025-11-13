/**
 * Budget management for Mini-IDE Server
 *
 * @module budget
 * @packageDocumentation
 */

import { BudgetExceededError } from './errors.js';

/**
 * Default budget limit in BRL (R$)
 */
const DEFAULT_BUDGET_LIMIT = 5.0;

/**
 * Estimated cost per 1000 tokens in BRL (DeepSeek-V3 pricing example)
 */
const COST_PER_1K_TOKENS = 0.001;

/**
 * Budget state for a session
 *
 * @public
 */
export interface BudgetState {
  /**
   * Total budget available in BRL
   */
  limit: number;

  /**
   * Budget already used in BRL
   */
  used: number;

  /**
   * Budget remaining in BRL
   */
  remaining: number;
}

/**
 * In-memory budget tracker (simplified for current scope)
 * In production, this would be persisted per user/session
 */
let globalBudgetUsed = 0;

/**
 * Estimate cost for a given number of tokens
 *
 * @param tokens - Number of tokens to estimate
 * @returns Estimated cost in BRL
 *
 * @public
 */
export function estimateCost(tokens: number): number {
  return (tokens / 1000) * COST_PER_1K_TOKENS;
}

/**
 * Get current budget state
 *
 * @param budgetLimit - Budget limit (default: R$ 5.00)
 * @returns Current budget state
 *
 * @public
 */
export function getBudgetState(budgetLimit = DEFAULT_BUDGET_LIMIT): BudgetState {
  return {
    limit: budgetLimit,
    used: globalBudgetUsed,
    remaining: Math.max(0, budgetLimit - globalBudgetUsed),
  };
}

/**
 * Check if budget allows processing the request
 *
 * @param estimatedTokens - Estimated tokens for the request
 * @param budgetLimit - Budget limit (default: R$ 5.00)
 * @throws {BudgetExceededError} When budget is insufficient
 *
 * @public
 */
export function checkBudget(estimatedTokens: number, budgetLimit = DEFAULT_BUDGET_LIMIT): void {
  const estimatedCost = estimateCost(estimatedTokens);
  const state = getBudgetState(budgetLimit);

  if (estimatedCost > state.remaining) {
    throw new BudgetExceededError(
      `Orçamento insuficiente. Necessário: R$ ${estimatedCost.toFixed(4)}, Disponível: R$ ${state.remaining.toFixed(4)}`,
    );
  }
}

/**
 * Record budget usage after processing
 *
 * @param tokensUsed - Actual tokens used
 *
 * @public
 */
export function recordUsage(tokensUsed: number): void {
  const cost = estimateCost(tokensUsed);
  globalBudgetUsed += cost;
}

/**
 * Reset budget (for testing purposes)
 *
 * @internal
 */
export function resetBudget(): void {
  globalBudgetUsed = 0;
}
