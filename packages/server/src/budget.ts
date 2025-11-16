/**
 * @file budget.ts
 * @description Sistema de controle de orçamento por contexto
 *
 * CHANGELOG v1.0.17:
 * - Removido estado global globalBudgetUsed
 * - Criada classe BudgetContext para isolamento por requisição
 * - Budget agora é thread-safe para requisições concorrentes
 * - Testes determinísticos sem flakiness
 *
 * @version 1.0.17
 * @since 2024-11-15
 */

/**
 * Estado do orçamento em um dado momento
 */
export interface BudgetState {
  /**
   * Limite total de orçamento disponível (R$)
   */
  limit: number;

  /**
   * Quanto já foi utilizado (R$)
   */
  used: number;

  /**
   * Quanto ainda resta disponível (R$)
   */
  remaining: number;
}

/**
 * Contexto de orçamento isolado por requisição
 *
 * Cada requisição deve ter seu próprio BudgetContext, garantindo:
 * - Isolamento completo entre requisições concorrentes
 * - Testes determinísticos sem estado compartilhado
 * - Thread-safety sem necessidade de locks
 *
 * @example
 * ```typescript
 * const context = createBudgetContext(10.0);
 *
 * if (context.checkBudget(2.5)) {
 *   // Processar operação
 *   context.recordUsage(2.5);
 * }
 *
 * const state = context.getState();
 * console.log(`Usado: R$ ${state.used}, Restante: R$ ${state.remaining}`);
 * ```
 */
export interface BudgetContext {
  /**
   * Retorna snapshot do estado atual do budget
   *
   * @returns Estado completo (limit, used, remaining)
   */
  getState(): BudgetState;

  /**
   * Verifica se há orçamento suficiente para um custo estimado
   *
   * @param estimatedCost - Custo estimado da operação (R$)
   * @returns true se há budget suficiente, false caso contrário
   */
  checkBudget(estimatedCost: number): boolean;

  /**
   * Registra uso efetivo do orçamento
   *
   * @param actualCost - Custo real da operação executada (R$)
   * @throws Error se o custo exceder o budget disponível
   */
  recordUsage(actualCost: number): void;

  /**
   * Retorna limite total do budget
   *
   * @returns Limite em R$
   */
  getLimit(): number;

  /**
   * Retorna quanto já foi usado
   *
   * @returns Uso acumulado em R$
   */
  getUsed(): number;
}

/**
 * Implementação interna de BudgetContext
 */
class BudgetContextImpl implements BudgetContext {
  private limit: number;
  private used: number;

  constructor(limit: number) {
    if (limit <= 0) {
      throw new Error('Budget limit deve ser > 0');
    }
    this.limit = limit;
    this.used = 0;
  }

  getState(): BudgetState {
    return {
      limit: this.limit,
      used: this.used,
      remaining: this.limit - this.used,
    };
  }

  checkBudget(estimatedCost: number): boolean {
    // Validar entrada
    if (estimatedCost <= 0) {
      return false;
    }

    const remaining = this.limit - this.used;
    return estimatedCost <= remaining;
  }

  recordUsage(actualCost: number): void {
    // Validar entrada
    if (actualCost <= 0) {
      throw new Error('Valor de uso deve ser > 0');
    }

    // Verificar se não excede limite
    const remaining = this.limit - this.used;
    if (actualCost > remaining) {
      throw new Error(
        `Tentativa de registrar uso que excede budget disponível. ` +
          `Tentou usar: R$ ${actualCost.toFixed(2)}, ` +
          `Disponível: R$ ${remaining.toFixed(2)}`,
      );
    }

    this.used += actualCost;
  }

  getLimit(): number {
    return this.limit;
  }

  getUsed(): number {
    return this.used;
  }
}

/**
 * Factory para criar contextos de budget isolados
 *
 * @param limit - Limite de orçamento em R$
 * @returns Nova instância de BudgetContext
 * @throws Error se limit <= 0
 *
 * @example
 * ```typescript
 * const context = createBudgetContext(10.0);
 * ```
 */
export function createBudgetContext(limit: number): BudgetContext {
  return new BudgetContextImpl(limit);
}
