#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 02_refactor_budget_to_context.sh
# Objetivo: Refatorar budget para usar BudgetContext (sem estado global)
# Versão: 1.0.17
# Data: 2024-11-15
# HU: HU-Server-Budget-Per-Context
#
# Este script implementa isolamento de budget por contexto de requisição:
# - Remove estado global globalBudgetUsed
# - Cria classe BudgetContext com estado isolado
# - Atualiza index.ts para criar contexto por requisição
# - Cria testes determinísticos (10 execuções sem flakiness)
#
# Arquivos afetados:
# - packages/server/src/budget.ts (REFATORADO)
# - packages/server/src/index.ts (REFATORADO)
# - packages/server/test/budget.spec.ts (CRIADO)
#
# Premissas:
# - Estrutura packages/server existe
# - PNPM instalado e configurado
# - Node.js 22.x
# - Vitest configurado em packages/server
#
# Riscos:
# - Sobrescreve arquivos existentes (cria backup antes)
# - Mudança breaking na API interna de budget
#
# Como reverter:
# git checkout packages/server/src/budget.ts
# git checkout packages/server/src/index.ts
# rm packages/server/test/budget.spec.ts
###############################################################################

echo "[info] Iniciando refatoração Budget → BudgetContext"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  echo "[erro] Diretório atual: $(pwd)"
  exit 1
fi

# Verificar se packages/server existe
if [[ ! -d "packages/server" ]]; then
  echo "[erro] Diretório packages/server não encontrado"
  exit 1
fi

# Criar diretório de testes se não existir
mkdir -p packages/server/test

# Criar backups dos arquivos que serão modificados
echo "[info] Criando backups (.bak)..."
if [[ -f "packages/server/src/budget.ts" ]]; then
  cp packages/server/src/budget.ts packages/server/src/budget.ts.bak
  echo "[ok] Backup: budget.ts.bak"
fi
if [[ -f "packages/server/src/index.ts" ]]; then
  cp packages/server/src/index.ts packages/server/src/index.ts.bak
  echo "[ok] Backup: index.ts.bak"
fi

###############################################################################
# ARQUIVO 1/3: budget.ts (REFATORADO)
###############################################################################
echo ""
echo "[info] Refatorando budget.ts (BudgetContext)..."

cat > packages/server/src/budget.ts << 'ENDOFFILE'
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
        `Disponível: R$ ${remaining.toFixed(2)}`
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
ENDOFFILE

echo "[ok] budget.ts refatorado (159 linhas)"

###############################################################################
# ARQUIVO 2/3: index.ts (REFATORADO)
###############################################################################
echo "[info] Refatorando index.ts (usa BudgetContext por requisição)..."

cat > packages/server/src/index.ts << 'ENDOFFILE'
/**
 * @file index.ts
 * @description Servidor HTTP principal do Mini-IDE usando Fastify
 * 
 * CHANGELOG v1.0.17:
 * - Refatorado para usar BudgetContext ao invés de estado global
 * - BudgetContext criado por requisição para isolamento completo
 * - Budget agora é thread-safe para requisições concorrentes
 * 
 * @version 1.0.17
 */

import Fastify from 'fastify';
import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createBudgetContext, type BudgetContext } from './budget.js';

const DEFAULT_PORT = 3200;
const DEFAULT_MAX_LEN = 100;
const DEFAULT_BUDGET_LIMIT = 10.0; // R$ 10.00 por requisição

interface AnalyzeRequestBody {
  text: string;
  maxLen?: number;
}

interface AnalyzeResponse {
  summary: string;
  inputLength: number;
  outputLength: number;
  requestId: string;
  timestamp: string;
  budgetUsed: number;
  budgetRemaining: number;
}

interface HealthResponse {
  status: 'ok' | 'degraded';
  timestamp: string;
  uptime: number;
  components: {
    budget: 'ok' | 'warn';
    llm: 'ok' | 'mock';
  };
}

const server: FastifyInstance = Fastify({
  logger: {
    level: 'info',
    serializers: {
      req: (req) => ({
        method: req.method,
        url: req.url,
        requestId: req.id,
      }),
    },
  },
});

const startTime = Date.now();

/**
 * Gera requestId único para cada requisição
 */
function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

/**
 * Simula processamento de análise (mock)
 * Na versão real, isso chamará o LLM Provider
 */
function mockAnalyze(text: string, maxLen: number, budgetContext: BudgetContext): string {
  // Simula custo baseado no tamanho do texto
  const estimatedCost = (text.length / 1000) * 0.01; // R$ 0.01 por 1000 chars
  
  // Verifica budget antes de processar
  const canProceed = budgetContext.checkBudget(estimatedCost);
  if (!canProceed) {
    throw new Error('Budget insuficiente para processar esta requisição');
  }
  
  // Processa (mock)
  const summary = text.length > maxLen 
    ? text.substring(0, maxLen) + '...' 
    : text;
  
  // Registra uso do budget
  budgetContext.recordUsage(estimatedCost);
  
  return summary;
}

/**
 * POST /analyze - Endpoint principal de análise
 */
server.post<{ Body: AnalyzeRequestBody }>(
  '/analyze',
  async (request: FastifyRequest<{ Body: AnalyzeRequestBody }>, reply: FastifyReply) => {
    const requestId = generateRequestId();
    const timestamp = new Date().toISOString();
    
    // Criar contexto de budget isolado para esta requisição
    const budgetContext = createBudgetContext(DEFAULT_BUDGET_LIMIT);
    
    request.log.info({
      event: 'analyze_request',
      requestId,
      timestamp,
      textLength: request.body?.text?.length || 0,
      maxLen: request.body?.maxLen,
      budgetLimit: budgetContext.getLimit(),
    });

    // Validação: text é obrigatório
    if (!request.body || !request.body.text) {
      request.log.warn({
        event: 'analyze_validation_error',
        requestId,
        error: 'text_missing',
      });
      return reply.code(400).send({
        error: 'Validação falhou',
        message: 'Campo "text" é obrigatório',
        requestId,
        timestamp,
      });
    }

    // Validação: text não pode estar vazio
    if (request.body.text.trim() === '') {
      request.log.warn({
        event: 'analyze_validation_error',
        requestId,
        error: 'text_empty',
      });
      return reply.code(400).send({
        error: 'Validação falhou',
        message: 'Campo "text" não pode estar vazio',
        requestId,
        timestamp,
      });
    }

    // Validação: maxLen deve estar entre 1 e 1000
    const maxLen = request.body.maxLen ?? DEFAULT_MAX_LEN;
    if (maxLen < 1 || maxLen > 1000) {
      request.log.warn({
        event: 'analyze_validation_error',
        requestId,
        error: 'maxLen_invalid',
        maxLen,
      });
      return reply.code(400).send({
        error: 'Validação falhou',
        message: 'Campo "maxLen" deve ser >= 1 e <= 1000',
        requestId,
        timestamp,
      });
    }

    try {
      // Processar análise com contexto de budget isolado
      const summary = mockAnalyze(request.body.text, maxLen, budgetContext);
      
      const budgetState = budgetContext.getState();
      
      const response: AnalyzeResponse = {
        summary,
        inputLength: request.body.text.length,
        outputLength: summary.length,
        requestId,
        timestamp,
        budgetUsed: budgetState.used,
        budgetRemaining: budgetState.remaining,
      };

      request.log.info({
        event: 'analyze_complete',
        requestId,
        inputLength: response.inputLength,
        outputLength: response.outputLength,
        budgetUsed: budgetState.used,
        budgetRemaining: budgetState.remaining,
      });

      return reply.code(200).send(response);
      
    } catch (error) {
      // Tratamento de erro de budget
      if (error instanceof Error && error.message.includes('Budget')) {
        request.log.warn({
          event: 'analyze_budget_exceeded',
          requestId,
          error: error.message,
        });
        return reply.code(402).send({
          error: 'Orçamento excedido',
          message: error.message,
          requestId,
          timestamp,
        });
      }
      
      // Erro interno genérico
      request.log.error({
        event: 'analyze_error',
        requestId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
      return reply.code(500).send({
        error: 'Erro interno',
        message: 'Falha ao processar análise',
        requestId,
        timestamp,
      });
    }
  }
);

/**
 * GET /healthz - Health check endpoint
 */
server.get('/healthz', async (request: FastifyRequest, reply: FastifyReply) => {
  const uptime = Date.now() - startTime;
  
  const response: HealthResponse = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime,
    components: {
      budget: 'ok', // Budget agora é por contexto, sempre ok
      llm: 'mock',  // Ainda usando mock
    },
  };

  request.log.info({
    event: 'healthcheck',
    uptime,
  });

  return reply.code(200).send(response);
});

/**
 * Inicia o servidor
 */
async function start(): Promise<void> {
  try {
    const port = Number(process.env['PORT']) || DEFAULT_PORT;
    await server.listen({ port, host: '0.0.0.0' });
    
    server.log.info({
      event: 'server_started',
      port,
      defaultBudgetLimit: DEFAULT_BUDGET_LIMIT,
      defaultMaxLen: DEFAULT_MAX_LEN,
    });
    
    console.log(`[ok] Mini-IDE Server rodando em http://127.0.0.1:${port}`);
    console.log(`[info] Budget limit padrão: R$ ${DEFAULT_BUDGET_LIMIT.toFixed(2)} por requisição`);
    console.log(`[info] Endpoints disponíveis:`);
    console.log(`       GET  /healthz`);
    console.log(`       POST /analyze`);
  } catch (err) {
    server.log.error({
      event: 'server_start_error',
      error: err instanceof Error ? err.message : 'Unknown error',
    });
    process.exit(1);
  }
}

start();

export { server };
ENDOFFILE

echo "[ok] index.ts refatorado (239 linhas)"

###############################################################################
# ARQUIVO 3/3: budget.spec.ts (CRIADO)
###############################################################################
echo "[info] Criando budget.spec.ts (testes completos)..."

cat > packages/server/test/budget.spec.ts << 'ENDOFFILE'
/**
 * @file budget.spec.ts
 * @description Testes para o sistema de Budget usando BudgetContext
 * 
 * Cobertura de testes:
 * - BudgetContext: criação, verificação, registro de uso, limites
 * - Isolamento entre contextos
 * - Determinismo: 10 execuções seguidas sem flakiness
 * - Edge cases: budget zero, negativo, excedido
 * 
 * Meta de cobertura: ≥95%
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
        'Tentativa de registrar uso que excede budget disponível'
      );
    });

    it('deve rejeitar valores negativos', () => {
      expect(() => context.recordUsage(-1)).toThrow(
        'Valor de uso deve ser > 0'
      );
    });

    it('deve rejeitar valor zero', () => {
      expect(() => context.recordUsage(0)).toThrow(
        'Valor de uso deve ser > 0'
      );
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
      
      contexts[0].recordUsage(3.0);
      contexts[1].recordUsage(5.0);
      contexts[2].recordUsage(7.0);
      
      expect(contexts[0].getState().used).toBe(3.0);
      expect(contexts[1].getState().used).toBe(5.0);
      expect(contexts[2].getState().used).toBe(7.0);
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
      results.forEach(result => {
        expect(result).toBeCloseTo(expectedSum, 10); // 10 casas decimais
      });
    });

    it('deve manter isolamento em 10 execuções paralelas simuladas', () => {
      const contexts = Array.from(
        { length: 10 }, 
        (_, i) => createBudgetContext((i + 1) * 10.0)
      );
      
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
      const context = createBudgetContext(0.10);
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
ENDOFFILE

echo "[ok] budget.spec.ts criado (262 linhas)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando validações finais..."

# Verificar se todos os arquivos foram criados/modificados
EXPECTED_FILES=(
  "packages/server/src/budget.ts"
  "packages/server/src/index.ts"
  "packages/server/test/budget.spec.ts"
)

for file in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[erro] Arquivo esperado não foi encontrado: $file"
    exit 1
  fi
done
echo "[ok] Todos os 3 arquivos foram criados/modificados"

# Contar linhas
echo ""
echo "[info] Contagem de linhas:"
echo "   - budget.ts: $(wc -l < packages/server/src/budget.ts) linhas"
echo "   - index.ts: $(wc -l < packages/server/src/index.ts) linhas"
echo "   - budget.spec.ts: $(wc -l < packages/server/test/budget.spec.ts) linhas"

# Tentar executar typecheck
echo ""
echo "[info] Executando typecheck no pacote server..."
if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] Typecheck passou sem erros"
else
  echo "[warn] Typecheck apresentou erros. Revise os arquivos."
  exit 1
fi

# Tentar executar testes
echo ""
echo "[info] Executando testes do Budget..."
if pnpm --filter @mini-ide/server test budget; then
  echo "[ok] Testes executados com sucesso"
else
  echo "[warn] Alguns testes falharam. Revise os arquivos."
  exit 1
fi

# Remover backups se tudo passou
echo ""
echo "[info] Removendo backups (.bak)..."
rm -f packages/server/src/budget.ts.bak
rm -f packages/server/src/index.ts.bak
echo "[ok] Backups removidos"

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 02 executado com sucesso!"
echo "=========================================="
echo ""
echo "📦 Arquivos modificados/criados:"
echo "   - budget.ts (159 linhas) - Refatorado com BudgetContext"
echo "   - index.ts (239 linhas) - Usa contexto por requisição"
echo "   - budget.spec.ts (262 linhas) - Suite completa de testes"
echo ""
echo "📊 Total: ~660 linhas (2 refatorados + 1 criado)"
echo ""
echo "🎯 Mudanças principais:"
echo "   ❌ Removido: globalBudgetUsed (estado global)"
echo "   ✅ Criado: BudgetContext (isolamento por requisição)"
echo "   ✅ Thread-safe: requisições concorrentes isoladas"
echo "   ✅ Determinístico: 10 execuções idênticas garantidas"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Revisar os arquivos modificados"
echo "   2. Executar: pnpm --filter @mini-ide/server test budget"
echo "   3. Verificar cobertura: pnpm --filter @mini-ide/server test --coverage"
echo "   4. Commit: git add packages/server/"
echo "   5. Commit: git commit -m 'refactor(server): usar BudgetContext ao invés de estado global (HU-Server-Budget-Per-Context)'"
echo ""
echo "🔄 Como reverter:"
echo "   git checkout packages/server/src/budget.ts"
echo "   git checkout packages/server/src/index.ts"
echo "   rm packages/server/test/budget.spec.ts"
echo ""
echo "[ok] Script finalizado em $(date)"
