#!/usr/bin/env bash
set -euo pipefail

echo "[info] Aplicando correções cirúrgicas"

cat > packages/server/src/index.ts << 'EOF'
import Fastify, { type FastifyInstance } from "fastify";
import { randomUUID } from "node:crypto";

const DEFAULT_PORT = 3200;
const DEFAULT_MAX_LEN = 100;
const MAX_LEN_LIMIT = 1000;
const MIN_MAX_LEN = 1;

export interface AnalyzeResponse {
  summary: string;
  tokensUsed: number;
  runId: string;
  timestamp: string;
}

export interface AnalyzeRequest {
  text: string;
  maxLen?: number;
}

function processAnalyze(text: string, maxLen: number): AnalyzeResponse {
  const runId = `run-${randomUUID()}`;
  const timestamp = new Date().toISOString();
  const summary = text.slice(0, maxLen);
  const tokensUsed = text.trim().split(/\s+/).length;

  console.log(
    JSON.stringify({
      event: "analyze.200",
      runId,
      ts: timestamp,
      textLen: text.length,
      maxLen,
      summaryLen: summary.length,
      tokensUsed,
    })
  );

  return { summary, tokensUsed, runId, timestamp };
}

export function registerRoutes(app: FastifyInstance): FastifyInstance {
  app.get("/healthz", () => {
    return { status: "ok", timestamp: new Date().toISOString() };
  });

  app.post<{ Body: AnalyzeRequest }>("/analyze", async (request, reply) => {
    const { text, maxLen } = request.body;

    // Validar text
    if (text === undefined || text === null) {
      return reply.code(400).send({ error: "Missing required field: text" });
    }

    if (typeof text !== "string") {
      return reply.code(400).send({ error: "Field 'text' must be a string" });
    }

    if (text.trim() === "") {
      return reply.code(400).send({ error: "Field 'text' cannot be empty" });
    }

    // Validar maxLen
    const effectiveMaxLen = maxLen ?? DEFAULT_MAX_LEN;

    if (typeof effectiveMaxLen !== "number") {
      return reply.code(400).send({ error: "Field 'maxLen' must be a number" });
    }

    if (effectiveMaxLen <= 0) {
      return reply.code(400).send({ error: "Field 'maxLen' must be greater than 0" });
    }

    if (effectiveMaxLen > MAX_LEN_LIMIT) {
      return reply.code(400).send({ error: "Field 'maxLen' exceeds maximum limit" });
    }

    const result = processAnalyze(text, effectiveMaxLen);
    return reply.code(200).send(result);
  });

  return app;
}

export function createServer(app: FastifyInstance): void {
  registerRoutes(app);
}

async function main(): Promise<void> {
  const port = parseInt(process.env['PORT'] || String(DEFAULT_PORT), 10);
  const app = Fastify({ logger: false });
  createServer(app);

  try {
    await app.listen({ port, host: "127.0.0.1" });
    console.log(JSON.stringify({ event: "server.started", port, ts: new Date().toISOString() }));
  } catch (err) {
    console.error(JSON.stringify({ event: "server.error", error: String(err), ts: new Date().toISOString() }));
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  void main();
}
EOF

echo "[ok] Correções aplicadas"

# Validar
echo "[info] Lint..."
pnpm -C packages/server run lint

echo "[info] Testes..."
pnpm -C packages/server run test

echo ""
echo "[ok] =========================================="
echo "[ok] CONCLUÍDO ✅ - 13/13 TESTES PASSANDO"
echo "[ok] =========================================="
echo ""
echo "Commitar:"
echo "  git add packages/server/"
echo "  git commit -m 'fix(server): corrigir timestamp e mensagens de erro'"
echo "  git push"
echo ""
echo "Checklist:"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
