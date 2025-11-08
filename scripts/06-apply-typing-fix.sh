#!/usr/bin/env bash
# scripts/06-apply-typing-fix.sh
#
# Descrição: Aplica correção de tipagem no index.ts e revalida
# Uso: bash scripts/06-apply-typing-fix.sh
# Pré-requisitos: bash, pnpm
# Efeitos colaterais: Corrige index.ts e roda build/typecheck

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "CORREÇÃO DE TIPAGEM - index.ts"
echo "========================================="
echo ""

# 1. Aplicar correção no index.ts
TARGET_FILE="packages/server/src/index.ts"

echo "[1] Corrigindo ${TARGET_FILE}..."
echo ""

# Backup
cp "${TARGET_FILE}" "${TARGET_FILE}.bak-typing"

# Aplicar código corrigido
cat > "${TARGET_FILE}" << 'TYPESCRIPT_CODE'
import Fastify, { FastifyRequest, FastifyReply } from "fastify";
import { randomUUID } from "node:crypto";

/**
 * Configuração padrão do servidor Mini-IDE
 */
const DEFAULT_PORT = 3200;
const DEFAULT_MAX_LEN = 100;
const MAX_LEN_LIMIT = 1000;
const MIN_MAX_LEN = 1;

/**
 * Interface de resposta do endpoint /analyze
 * @property summary - Texto resumido até maxLen caracteres
 * @property tokensUsed - Estimativa de tokens (split por espaço)
 * @property runId - ID de correlação da requisição
 * @property ts - Timestamp ISO-8601 UTC
 */
export interface AnalyzeResponse {
  summary: string;
  tokensUsed: number;
  runId: string;
  ts: string;
}

/**
 * Interface de requisição do endpoint /analyze
 */
export interface AnalyzeRequest {
  text: string;
  maxLen?: number;
}

/**
 * Processa texto e retorna resumo com metadados
 * @param text - Texto a ser analisado
 * @param maxLen - Comprimento máximo do resumo (default: 100)
 * @returns Objeto AnalyzeResponse com summary, tokensUsed, runId e ts
 */
function processAnalyze(text: string, maxLen: number): AnalyzeResponse {
  const runId = `run-${randomUUID()}`;
  const ts = new Date().toISOString();

  // Aplica maxLen ao texto (trunca se necessário)
  const summary = text.slice(0, maxLen);

  // Estimativa determinística de tokens (split por espaço)
  const tokensUsed = text.trim().split(/\s+/).length;

  // Log de observabilidade (JSON estruturado)
  console.log(
    JSON.stringify({
      event: "analyze.200",
      runId,
      ts,
      textLen: text.length,
      maxLen,
      summaryLen: summary.length,
      tokensUsed,
    })
  );

  return { summary, tokensUsed, runId, ts };
}

/**
 * Registra rotas do servidor Mini-IDE
 * @param app - Instância do Fastify
 */
export function registerRoutes(
  app: ReturnType<typeof Fastify>
): ReturnType<typeof Fastify> {
  /**
   * GET /healthz - Health check do servidor
   */
  app.get("/healthz", async () => {
    return { status: "ok", timestamp: new Date().toISOString() };
  });

  /**
   * POST /analyze - Endpoint de análise de texto
   * Aceita { text: string, maxLen?: number }
   * Retorna { summary, tokensUsed, runId, ts }
   */
  app.post(
    "/analyze",
    async (
      request: FastifyRequest<{ Body: AnalyzeRequest }>,
      reply: FastifyReply
    ) => {
      const { text, maxLen } = request.body;

      // Validação básica: text deve ser string não-vazia
      if (typeof text !== "string") {
        return reply.code(400).send({
          error: "Invalid request",
          message: "Field 'text' must be a string",
        });
      }

      // Aplica default de maxLen se não fornecido
      const effectiveMaxLen = maxLen ?? DEFAULT_MAX_LEN;

      // Validação de range de maxLen
      if (effectiveMaxLen < MIN_MAX_LEN || effectiveMaxLen > MAX_LEN_LIMIT) {
        return reply.code(400).send({
          error: "Invalid maxLen",
          message: `maxLen must be between ${MIN_MAX_LEN} and ${MAX_LEN_LIMIT}`,
        });
      }

      // Processa análise e retorna 200
      const result = processAnalyze(text, effectiveMaxLen);
      return reply.code(200).send(result);
    }
  );

  return app;
}

/**
 * Inicializa e inicia o servidor Mini-IDE
 */
async function main(): Promise<void> {
  const port = parseInt(process.env["PORT"] || String(DEFAULT_PORT), 10);

  const app = Fastify({
    logger: false,
  });

  registerRoutes(app);

  try {
    await app.listen({ port, host: "127.0.0.1" });
    console.log(
      JSON.stringify({
        event: "server.started",
        port,
        ts: new Date().toISOString(),
      })
    );
  } catch (err) {
    console.error(
      JSON.stringify({
        event: "server.error",
        error: String(err),
        ts: new Date().toISOString(),
      })
    );
    process.exit(1);
  }
}

// Executa apenas se for o módulo principal
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
  });
}
TYPESCRIPT_CODE

echo "[ok] Arquivo corrigido com tipagens Fastify"
echo ""

# 2. Remover arquivos .bak que causam erro
echo "[2] Removendo arquivos .bak do diretório test..."
find packages/server/test -name "*.bak*.ts" -delete 2>/dev/null || true
echo "[ok] Cleanup concluído"
echo ""

# 3. Build
echo "[3] Building server..."
if pnpm --filter @mini-ide/server build; then
  echo "[ok] Build OK"
else
  echo "[erro] Build failed"
  exit 1
fi
echo ""

# 4. Typecheck
echo "[4] Running typecheck..."
if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] Typecheck OK"
else
  echo "[erro] Typecheck failed"
  exit 1
fi
echo ""

# 5. Testes
echo "[5] Running tests..."
if pnpm --filter @mini-ide/server test; then
  echo "[ok] Tests OK"
else
  echo "[erro] Tests failed"
  exit 1
fi
echo ""

# 6. Smoke test
echo "[6] Running smoke test..."
if bash scripts/smoke-analyze-200.sh; then
  echo "[ok] Smoke test OK"
else
  echo "[erro] Smoke test failed"
  exit 1
fi
echo ""

echo "========================================="
echo "[ok] CORREÇÃO COMPLETA - SUCESSO!"
echo "========================================="
echo ""
echo "Mudanças aplicadas:"
echo "  ✓ Importa FastifyRequest e FastifyReply"
echo "  ✓ Tipagem explícita: request/reply com tipos corretos"
echo "  ✓ Usa process.env['PORT'] em vez de .PORT"
echo "  ✓ Remove generic type de app.post()"
echo "  ✓ Build/typecheck/tests/smoke passaram"
echo ""
echo "Próximo: REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
