import Fastify, { type FastifyRequest, type FastifyReply, type FastifyInstance } from "fastify";
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
export function registerRoutes(app: FastifyInstance): FastifyInstance {
  /**
   * GET /healthz - Health check do servidor
   */
  app.get("/healthz", () => {
    return { status: "ok", timestamp: new Date().toISOString() };
  });

  /**
   * POST /analyze - Endpoint de análise de texto
   * Aceita { text: string, maxLen?: number }
   * Retorna { summary, tokensUsed, runId, ts }
   */
  app.post(
    "/analyze",
    (
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
