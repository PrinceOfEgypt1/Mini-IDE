#!/usr/bin/env bash
set -euo pipefail

echo "[info] Adicionando função createServer para compatibilidade com testes"

# Backup
cp packages/server/src/index.ts packages/server/src/index.ts.backup_$(date +%Y%m%d_%H%M%S)

# Adicionar createServer após registerRoutes
cat > packages/server/src/index.ts << 'EOF'
// packages/server/src/index.ts
// Implementação do servidor com POST /analyze

import Fastify, { type FastifyInstance } from "fastify";
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
 */
function processAnalyze(text: string, maxLen: number): AnalyzeResponse {
  const runId = `run-${randomUUID()}`;
  const ts = new Date().toISOString();
  const summary = text.slice(0, maxLen);
  const tokensUsed = text.trim().split(/\s+/).length;

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
 * @deprecated Use createServer() para compatibilidade com testes
 */
export function registerRoutes(
  app: FastifyInstance
): FastifyInstance {
  app.get("/healthz", async () => {
    return { status: "ok", timestamp: new Date().toISOString() };
  });

  app.post<{ Body: AnalyzeRequest }>("/analyze", async (request, reply) => {
    const { text, maxLen } = request.body;

    if (typeof text !== "string" || text.trim() === "") {
      return reply.code(400).send({ error: "Bad Request" });
    }

    const effectiveMaxLen = maxLen ?? DEFAULT_MAX_LEN;

    if (typeof effectiveMaxLen !== "number" || effectiveMaxLen < MIN_MAX_LEN || effectiveMaxLen > MAX_LEN_LIMIT) {
      return reply.code(400).send({ error: "Bad Request" });
    }

    const result = processAnalyze(text, effectiveMaxLen);
    return reply.code(200).send(result);
  });

  return app;
}

/**
 * Configura rotas do servidor (compatível com testes)
 */
export function createServer(app: FastifyInstance): void {
  registerRoutes(app);
}

/**
 * Inicializa e inicia o servidor Mini-IDE
 */
async function main() {
  const port = parseInt(process.env['PORT'] || String(DEFAULT_PORT), 10);

  const app = Fastify({ logger: false });

  createServer(app);

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

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
EOF

echo "[ok] Arquivo atualizado"

# Validar
echo "[info] Validando..."

if pnpm -C packages/server run lint; then
  echo "[ok] Lint OK"
else
  echo "[fail] Lint falhou"
  exit 1
fi

if pnpm -C packages/server run test 2>&1 | grep -q "13 passed"; then
  echo "[ok] Testes OK (13/13)"
else
  echo "[fail] Testes falharam"
  exit 1
fi

echo ""
echo "[ok] Concluído ✅"
echo ""
echo "[info] Checklist:"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
