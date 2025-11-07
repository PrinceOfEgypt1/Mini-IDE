# 40_fix_server_tests_inject.sh
# =========================================================================================
# Diretório de execução: ~/workspace/Mini-IDE  (RAIZ do projeto)
#
# Objetivo:
#   - Tornar os testes do @mini-ide/server independentes de porta/servidor externo
#     usando fastify.inject().
#   - Exportar buildServer() em src/index.ts e manter execução CLI quando chamado via tsx/node.
#   - Reescrever tests para beforeAll/afterAll com app.inject().
#
# Resultado esperado:
#   - `pnpm -F @mini-ide/server test` passa sem depender de `PORT=3000` estar livre/ligado.
#
# Idempotente: pode rodar mais de uma vez.
# =========================================================================================
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV_DIR="$ROOT/packages/server"
SRC_DIR="$SRV_DIR/src"
TEST_DIR="$SRV_DIR/test"

echo "== 40 :: FIX SERVER TESTS (inject) =="

# 0) Sanidade
[ -d "$SRC_DIR" ] || { echo "[erro] Não achei $SRC_DIR"; exit 1; }
[ -d "$TEST_DIR" ] || { echo "[erro] Não achei $TEST_DIR"; exit 1; }

# 1) Reescreve src/index.ts com buildServer() + modo CLI
cat > "$SRC_DIR/index.ts" <<'TS'
/**
 * @module server
 * @remarks
 * Servidor Fastify do Mini-IDE.
 * Exporta {@link buildServer} para uso em testes (in-memory, via `fastify.inject()`),
 * e mantém o bootstrap CLI quando executado diretamente (tsx/node).
 */
import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { compactPrompt } from '@mini-ide/analysis-agent';
import { checkPortFree } from './portGuard';

/**
 * Cria e configura uma instância do Fastify com rotas e plugins.
 * @returns {Promise<FastifyInstance>} Instância configurada do Fastify (ainda não "listen").
 */
export async function buildServer(): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });

  // CORS restrito a dev local; ajuste conforme necessidade.
  await app.register(cors, {
    origin: (origin, cb) => {
      if (!origin) return cb(null, true);
      try {
        const url = new URL(origin);
        const ok =
          (url.hostname === 'localhost' || url.hostname === '127.0.0.1') &&
          (url.port === '3000' || url.port === '3100' || url.port === '');
        cb(null, ok);
      } catch {
        cb(null, false);
      }
    },
    methods: ['GET', 'POST', 'OPTIONS'],
    credentials: true,
  });

  // Healthz
  app.get('/healthz', async (_req, _reply) => {
    return {
      status: 'ok' as const,
      service: 'mini-ide-server',
      uptime: process.uptime(),
    };
  });

  // Analyze
  app.post('/analyze', async (req, reply) => {
    const body = (req.body ?? {}) as { input?: string; maxLen?: number };
    const input = typeof body.input === 'string' ? body.input : '';
    const maxLen = typeof body.maxLen === 'number' ? body.maxLen : undefined;

    const result = compactPrompt(input, { maxLen });
    const payload = {
      ok: true,
      inputLen: input.length,
      outputLen: result.length,
      result,
    };
    return reply.send(payload);
  });

  return app;
}

// -----------------------------------------------------------------------------------------
// CLI bootstrap: roda somente se este arquivo for o entrypoint do processo (não em testes).
// -----------------------------------------------------------------------------------------
if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    const port = Number(process.env['PORT'] ?? 3000);
    const host = process.env['HOST'] ?? '127.0.0.1';

    // guarda porto livre se possível (não lança)
    const free = await checkPortFree(port);
    if (!free) {
      console.warn(`[mini-ide] aviso: porta ${port} ocupada; tente outra via PORT=xxxx`);
    }

    const app = await buildServer();
    await app.listen({ port, host });
    console.log(`[mini-ide] server running on http://${host}:${port}`);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
TS

# 2) Reescreve tests para usar app.inject()
COMMON_HELPER_TS='/**
 * Cria o servidor para testes em memória (fastify.inject()).
 * @returns {Promise<import("fastify").FastifyInstance>}
 */
import type { FastifyInstance } from "fastify";
import { beforeAll, afterAll } from "vitest";
import { buildServer } from "../src/index";

let app: FastifyInstance;

export function useTestApp() {
  beforeAll(async () => {
    app = await buildServer();
  });

  afterAll(async () => {
    await app.close();
  });

  return {
    get app() {
      return app;
    },
  };
}'

# healthz.spec.ts
cat > "$TEST_DIR/healthz.spec.ts" <<TS
/**
 * Testes do endpoint /healthz usando fastify.inject (sem rede/porta real).
 */
import { describe, it, expect } from 'vitest';
${COMMON_HELPER_TS}

type HealthzResponse = {
  status: 'ok';
  service: string;
  uptime: number;
};

describe('server :: /healthz', () => {
  const { app } = useTestApp();

  it('retorna status ok, service e uptime numérico', async () => {
    const res = await app.inject({ method: 'GET', url: '/healthz' });
    expect(res.statusCode).toBe(200);

    const bodyUnknown = res.json();
    const body = bodyUnknown as HealthzResponse;

    expect(body.status).toBe('ok');
    expect(typeof body.service).toBe('string');
    expect(typeof body.uptime).toBe('number');
  });
});
TS

# analyze.spec.ts
cat > "$TEST_DIR/analyze.spec.ts" <<TS
/**
 * Testes do endpoint /analyze usando fastify.inject (sem rede/porta real).
 */
import { describe, it, expect } from 'vitest';
${COMMON_HELPER_TS}

type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

describe('server :: /analyze', () => {
  const { app } = useTestApp();

  it('compacta o texto e retorna ok=true', async () => {
    const payload = {
      input: '  Olá   Mini-IDE!  \\r\\n\\r\\n Demo de   compactação ',
      maxLen: 80,
    };

    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload,
      headers: { 'content-type': 'application/json' },
    });
    expect(res.statusCode).toBe(200);

    const bodyUnknown = res.json();
    const body = bodyUnknown as AnalyzeResponse;

    expect(body.ok).toBe(true);
    expect(typeof body.result).toBe('string');
    expect(typeof body.outputLen).toBe('number');
    expect(body.outputLen).toBe(body.result.length);
  });

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const payload = {
      input: 'Linha  1   com   espaços\\r\\n\\r\\n   Linha  2\\ttabs',
      maxLen: 32,
    };

    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload,
      headers: { 'content-type': 'application/json' },
    });
    expect(res.statusCode).toBe(200);

    const bodyUnknown = res.json();
    const body = bodyUnknown as AnalyzeResponse;

    expect(body.ok).toBe(true);
    expect(typeof body.result).toBe('string');
    expect(body.result.length).toBeLessThanOrEqual(payload.maxLen);
  });
});
TS

# 3) Normaliza finais de linha (se veio CRLF de editor)
sed -i 's/\r$//' "$SRC_DIR/index.ts" "$TEST_DIR/healthz.spec.ts" "$TEST_DIR/analyze.spec.ts"

# 4) Build + test do pacote server
echo "[info] build @mini-ide/server…"
pnpm -F @mini-ide/server run build
echo "[info] test @mini-ide/server…"
pnpm -F @mini-ide/server run test

echo "== 40 :: OK — testes do server agora usam fastify.inject e não dependem de porta =="
