#!/usr/bin/env bash
# Script: packages/server/scripts/07_fix_eslint_issues.sh
# Objetivo: Corrigir problemas de ESLint detectados pelo pre-commit hook
# Uso: bash packages/server/scripts/07_fix_eslint_issues.sh

set -euo pipefail

echo "[info] Corrigindo problemas de ESLint no arquivo index.ts"

TARGET_FILE="packages/server/src/index.ts"

if [ ! -f "${TARGET_FILE}" ]; then
  echo "[erro] Arquivo ${TARGET_FILE} não encontrado"
  exit 1
fi

# Criar backup
cp "${TARGET_FILE}" "${TARGET_FILE}.bak"
echo "[info] Backup criado: ${TARGET_FILE}.bak"

# Reescrever arquivo com correções
cat > "${TARGET_FILE}" << 'EOF'
/**
 * Mini-IDE Server - HTTP API for analysis and code generation
 * 
 * @module server
 * @packageDocumentation
 */

import Fastify, { type FastifyInstance, type FastifyReply } from 'fastify';
import { randomUUID } from 'node:crypto';
import {
  MiniIDEError,
  ValidationError,
  ServiceUnavailableError,
} from './errors.js';
import { checkBudget, recordUsage, estimateCost } from './budget.js';

/**
 * Default server port
 */
const DEFAULT_PORT = 3200;

/**
 * Default maximum length for summary
 */
const DEFAULT_MAX_LEN = 100;

/**
 * Maximum allowed value for maxLen parameter
 */
const MAX_LEN_LIMIT = 1000;

/**
 * Minimum allowed value for maxLen parameter
 */
const MIN_MAX_LEN = 1;

/**
 * Response structure for /analyze endpoint
 * 
 * @public
 */
export interface AnalyzeResponse {
  /**
   * Summarized text (truncated to maxLen)
   */
  summary: string;

  /**
   * Number of tokens processed
   */
  tokensUsed: number;

  /**
   * Unique identifier for this analysis run
   */
  runId: string;

  /**
   * ISO timestamp of the analysis
   */
  timestamp: string;
}

/**
 * Request structure for /analyze endpoint
 * 
 * @public
 */
export interface AnalyzeRequest {
  /**
   * Text to analyze
   */
  text: string;

  /**
   * Maximum length for summary (optional, default: 100)
   */
  maxLen?: number;
}

/**
 * Error response structure
 * 
 * @public
 */
export interface ErrorResponse {
  /**
   * Error message in Portuguese
   */
  error: string;

  /**
   * Error code for categorization
   */
  code: string;

  /**
   * Request ID for tracing
   */
  requestId: string;

  /**
   * ISO timestamp of the error
   */
  timestamp: string;

  /**
   * Retry-after delay in seconds (for 503 errors)
   */
  retryAfter?: number;
}

/**
 * Simulate LLM processing (mock for current implementation)
 * In production, this would call actual LLM service
 * 
 * @param text - Text to process
 * @param maxLen - Maximum length for summary
 * @returns Analysis response
 * @throws {ServiceUnavailableError} When LLM service is unavailable
 * 
 * @internal
 */
function simulateLLMProcessing(text: string, maxLen: number): AnalyzeResponse {
  // Simulate potential LLM failures (for testing purposes)
  // In production, this would be actual network calls to LLM API

  const runId = `run-${randomUUID()}`;
  const timestamp = new Date().toISOString();
  const summary = text.slice(0, maxLen);
  const tokensUsed = text.trim().split(/\s+/).length;

  return { summary, tokensUsed, runId, timestamp };
}

/**
 * Process analysis request with budget control and error handling
 * 
 * @param text - Text to analyze
 * @param maxLen - Maximum length for summary
 * @returns Analysis response
 * @throws {BudgetExceededError} When budget is insufficient
 * @throws {ServiceUnavailableError} When LLM service is unavailable
 * 
 * @internal
 */
function processAnalyze(text: string, maxLen: number): AnalyzeResponse {
  // Estimate tokens for budget check
  const estimatedTokens = text.trim().split(/\s+/).length;

  // Check budget before processing
  checkBudget(estimatedTokens);

  try {
    // Simulate LLM call
    const result = simulateLLMProcessing(text, maxLen);

    // Record actual usage
    recordUsage(result.tokensUsed);

    // Log successful analysis
    console.log(
      JSON.stringify({
        event: 'analyze.200',
        runId: result.runId,
        ts: result.timestamp,
        textLen: text.length,
        maxLen,
        summaryLen: result.summary.length,
        tokensUsed: result.tokensUsed,
        estimatedCost: estimateCost(result.tokensUsed),
      }),
    );

    return result;
  } catch (error) {
    // Fallback: return partial result even on LLM failure
    if (error instanceof ServiceUnavailableError) {
      const runId = `run-${randomUUID()}`;
      const timestamp = new Date().toISOString();

      console.log(
        JSON.stringify({
          event: 'analyze.fallback',
          runId,
          ts: timestamp,
          reason: 'LLM unavailable, using local truncation',
        }),
      );

      return {
        summary: text.slice(0, Math.min(maxLen, 50)), // Fallback: limit to 50 chars
        tokensUsed: 0, // No tokens used in fallback
        runId,
        timestamp,
      };
    }

    throw error;
  }
}

/**
 * Validate request body for /analyze endpoint
 * 
 * @param body - Request body to validate
 * @throws {ValidationError} When validation fails
 * 
 * @internal
 */
function validateAnalyzeRequest(body: unknown): asserts body is AnalyzeRequest {
  // Type guard: ensure body is an object
  if (typeof body !== 'object' || body === null) {
    throw new ValidationError('Request body must be a JSON object');
  }

  const req = body as Record<string, unknown>;

  // Validate text field - use bracket notation for index signature
  if (req['text'] === undefined || req['text'] === null) {
    throw new ValidationError('Campo obrigatório ausente: text');
  }

  if (typeof req['text'] !== 'string') {
    throw new ValidationError('Campo "text" deve ser uma string');
  }

  const textValue = req['text'];
  if (textValue.trim() === '') {
    throw new ValidationError('Campo "text" não pode estar vazio');
  }

  // Validate maxLen field (optional) - use bracket notation for index signature
  if (req['maxLen'] !== undefined && req['maxLen'] !== null) {
    if (typeof req['maxLen'] !== 'number') {
      throw new ValidationError('Campo "maxLen" deve ser um número');
    }

    const maxLenValue = req['maxLen'];
    if (maxLenValue < MIN_MAX_LEN) {
      throw new ValidationError(`Campo "maxLen" deve ser >= ${MIN_MAX_LEN}`);
    }

    if (maxLenValue > MAX_LEN_LIMIT) {
      throw new ValidationError(`Campo "maxLen" deve ser <= ${MAX_LEN_LIMIT}`);
    }
  }
}

/**
 * Register HTTP routes on Fastify instance
 * 
 * @param app - Fastify instance
 * @returns Fastify instance with registered routes
 * 
 * @public
 */
export function registerRoutes(app: FastifyInstance): FastifyInstance {
  /**
   * Health check endpoint
   * 
   * @route GET /healthz
   * @returns {object} 200 - Health status
   */
  app.get('/healthz', () => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  /**
   * Analyze text endpoint with budget control and error handling
   * 
   * @route POST /analyze
   * @param {AnalyzeRequest} request.body - Text and optional maxLen
   * @returns {AnalyzeResponse} 200 - Analysis result
   * @returns {ErrorResponse} 400 - Validation error
   * @returns {ErrorResponse} 402 - Budget exceeded
   * @returns {ErrorResponse} 500 - Internal server error
   * @returns {ErrorResponse} 503 - Service unavailable
   */
  app.post<{ Body: AnalyzeRequest }>('/analyze', async (request, reply) => {
    const requestId = `req-${randomUUID()}`;
    const timestamp = new Date().toISOString();

    try {
      // Validate request
      validateAnalyzeRequest(request.body);

      const { text, maxLen = DEFAULT_MAX_LEN } = request.body;

      // Process analysis
      const result = processAnalyze(text, maxLen);

      return reply.code(200).send(result);
    } catch (error) {
      return handleError(error, requestId, timestamp, reply);
    }
  });

  return app;
}

/**
 * Handle errors and return appropriate HTTP response
 * 
 * @param error - Error to handle
 * @param requestId - Request ID for tracing
 * @param timestamp - Timestamp of the error
 * @param reply - Fastify reply object
 * @returns Fastify reply with error response
 * 
 * @internal
 */
function handleError(
  error: unknown,
  requestId: string,
  timestamp: string,
  reply: FastifyReply,
): FastifyReply {
  // Handle known Mini-IDE errors
  if (error instanceof MiniIDEError) {
    const errorResponse: ErrorResponse = {
      error: error.message,
      code: error.code,
      requestId,
      timestamp,
    };

    // Add retry-after header for 503 errors
    if (error instanceof ServiceUnavailableError && error.retryAfter) {
      errorResponse.retryAfter = error.retryAfter;
      void reply.header('Retry-After', String(error.retryAfter));
    }

    // Log structured error
    console.log(
      JSON.stringify({
        event: 'analyze.error',
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        requestId,
        ts: timestamp,
      }),
    );

    return reply.code(error.statusCode).send(errorResponse);
  }

  // Handle unknown errors
  const errorResponse: ErrorResponse = {
    error: 'Erro interno do servidor',
    code: 'INTERNAL_ERROR',
    requestId,
    timestamp,
  };

  // Log with stack trace for debugging
  console.error(
    JSON.stringify({
      event: 'analyze.error.unknown',
      statusCode: 500,
      error: String(error),
      stack: error instanceof Error ? error.stack : undefined,
      requestId,
      ts: timestamp,
    }),
  );

  return reply.code(500).send(errorResponse);
}

/**
 * Initialize server with routes
 * 
 * @param app - Fastify instance
 * 
 * @public
 */
export function createServer(app: FastifyInstance): void {
  registerRoutes(app);
}

/**
 * Main entry point - start HTTP server
 * 
 * @internal
 */
async function main(): Promise<void> {
  const port = parseInt(process.env['PORT'] || String(DEFAULT_PORT), 10);
  const app = Fastify({ logger: false });
  createServer(app);

  try {
    await app.listen({ port, host: '127.0.0.1' });
    console.log(JSON.stringify({ event: 'server.started', port, ts: new Date().toISOString() }));
  } catch (err) {
    console.error(
      JSON.stringify({ event: 'server.error', error: String(err), ts: new Date().toISOString() }),
    );
    process.exit(1);
  }
}

// Auto-start server when executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  void main();
}
EOF

echo "[ok] Arquivo ${TARGET_FILE} corrigido"
echo "[info] Principais correções:"
echo "  ✓ Removido import 'FastifyRequest' não usado"
echo "  ✓ Removido import 'InternalServerError' não usado"
echo "  ✓ Removidas type assertions desnecessárias (as string, as number)"
echo "  ✓ Variáveis intermediárias criadas para evitar assertions"

# Executar ESLint para validar
echo ""
echo "[info] Validando com ESLint..."
pnpm exec eslint --max-warnings=0 "${TARGET_FILE}"

if [ $? -eq 0 ]; then
  echo "[ok] ESLint passou sem erros ou warnings!"
  
  # Executar testes para garantir que nada quebrou
  echo ""
  echo "[info] Executando testes para garantir que nada quebrou..."
  pnpm --filter @mini-ide/server test
  
  if [ $? -eq 0 ]; then
    echo "[ok] Testes passaram! Correções aplicadas com sucesso."
    echo "[info] Backup mantido em: ${TARGET_FILE}.bak"
  else
    echo "[erro] Testes falharam. Restaurando backup..."
    mv "${TARGET_FILE}.bak" "${TARGET_FILE}"
    exit 1
  fi
else
  echo "[erro] ESLint ainda encontrou problemas. Restaurando backup..."
  mv "${TARGET_FILE}.bak" "${TARGET_FILE}"
  exit 1
fi
EOF

chmod +x packages/server/scripts/07_fix_eslint_issues.sh

# Executar correção
bash packages/server/scripts/07_fix_eslint_issues.sh
