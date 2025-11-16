#!/usr/bin/env bash
set -euo pipefail

echo "[info] Ajustando no-floating-promises em packages/server/src/index.ts"
echo "[info] Data: $(date)"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX_FILE="${ROOT_DIR}/packages/server/src/index.ts"

if [[ ! -f "${INDEX_FILE}" ]]; then
  echo "[erro] Arquivo não encontrado: ${INDEX_FILE}"
  exit 1
fi

BACKUP_SUFFIX=".bak.no_floating_promises.$(date +%Y%m%d-%H%M%S)"
cp "${INDEX_FILE}" "${INDEX_FILE}${BACKUP_SUFFIX}"
echo "[ok] Backup criado: ${INDEX_FILE}${BACKUP_SUFFIX}"

echo "[info] Reescrevendo index.ts com correção em start()..."

cat <<'EOF' > "${INDEX_FILE}"
/**
 * @file index.ts
 * @version 1.0.17-patch6
 * CORREÇÃO CIENTÍFICA: Validações separadas para texto ausente vs vazio
 */

import Fastify from 'fastify';
import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createBudgetContext, type BudgetContext } from './budget.js';

const DEFAULT_PORT = 3200;
const DEFAULT_MAX_LEN = 100;
const DEFAULT_BUDGET_LIMIT = 10.0;

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
  bodyLimit: 10 * 1024 * 1024, // 10MB
});

const startTime = Date.now();

function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

function mockAnalyze(text: string, maxLen: number, budgetContext: BudgetContext): string {
  const estimatedCost = (text.length / 1000) * 0.01;
  
  const canProceed = budgetContext.checkBudget(estimatedCost);
  if (!canProceed) {
    throw new Error('Budget insuficiente para processar esta requisição');
  }
  
  let summary: string;
  if (text.length > maxLen) {
    summary = text.substring(0, maxLen - 3) + '...';
  } else {
    summary = text;
  }
  
  budgetContext.recordUsage(estimatedCost);
  
  return summary;
}

server.post<{ Body: AnalyzeRequestBody }>(
  '/analyze',
  async (request: FastifyRequest<{ Body: AnalyzeRequestBody }>, reply: FastifyReply) => {
    const requestId = generateRequestId();
    const timestamp = new Date().toISOString();
    
    const budgetContext = createBudgetContext(DEFAULT_BUDGET_LIMIT);
    
    request.log.info({
      event: 'analyze_request',
      requestId,
      timestamp,
      textLength: request.body?.text?.length || 0,
      maxLen: request.body?.maxLen,
      budgetLimit: budgetContext.getLimit(),
    });

    // CORREÇÃO CIENTÍFICA v1.0.17-patch6:
    // Separar validações para evitar !'' === true
    
    // Validação 1: text ausente (undefined ou null)
    if (!request.body || request.body.text === undefined || request.body.text === null) {
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

    // Validação 2: text vazio (string vazia ou apenas espaços)
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

server.get('/healthz', async (request: FastifyRequest, reply: FastifyReply) => {
  const uptime = Date.now() - startTime;
  
  const response: HealthResponse = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime,
    components: {
      budget: 'ok',
      llm: 'mock',
    },
  };

  request.log.info({
    event: 'healthcheck',
    uptime,
  });

  return reply.code(200).send(response);
});

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
    
    if (process.env['NODE_ENV'] !== 'test') {
      process.exit(1);
    }
  }
}

if (process.env['NODE_ENV'] !== 'test') {
  void start();
}

export { server };
EOF

echo "[ok] index.ts reescrito com sucesso."

echo "[info] Rodando lint em @mini-ide/server..."
pnpm --filter @mini-ide/server lint

echo "[info] Rodando typecheck em @mini-ide/server..."
pnpm --filter @mini-ide/server typecheck

echo "[info] Rodando testes em @mini-ide/server..."
pnpm --filter @mini-ide/server test

echo "=========================================="
echo "✅ Correção no-floating-promises concluída com sucesso!"
echo "=========================================="
echo "[dica] Agora, na raiz, execute:"
echo "       pnpm lint"
echo "       pnpm test"
echo "       pnpm typecheck"
echo "       pnpm build"
