# 47_fix_server_tests_any.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Objetivo: eliminar @typescript-eslint/no-unsafe-assignment nos testes do server,
# tipando parse de JSON como `unknown` + _type guards_ antes do cast.
# Também roda build/lint/test do pacote @mini-ide/server para confirmar.

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
SRV="$ROOT/packages/server"
TEST="$SRV/test"

echo "== 47 :: FIX SERVER TESTS (safe JSON, type guards) =="

[[ -d "$TEST" ]] || { echo "[erro] diretório de testes não encontrado: $TEST"; exit 1; }

# healthz.spec.ts
cat > "$TEST/healthz.spec.ts" <<'TS'
/**
 * Testes do endpoint /healthz com tipagem segura e guards.
 */
import { describe, it, expect } from 'vitest';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import type { FastifyInstance } from 'fastify';
import { registerRoutes } from '../src/index';

/** Modelo de resposta /healthz */
type HealthzResponse = {
  status: 'ok';
  service: string;
  uptime: number;
};

function isHealthzResponse(u: unknown): u is HealthzResponse {
  if (typeof u !== 'object' || u === null) return false;
  const o = u as Record<string, unknown>;
  return o.status === 'ok'
    && typeof o.service === 'string'
    && typeof o.uptime === 'number';
}

describe('server :: /healthz', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify({ logger: false });
    await app.register(cors, { origin: true });
    registerRoutes(app);
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('retorna status ok, service e uptime numérico', async () => {
    const res = await app.inject({ method: 'GET', url: '/healthz' });
    expect(res.statusCode).toBe(200);

    const dataUnknown: unknown = await res.json();
    if (!isHealthzResponse(dataUnknown)) throw new Error('payload inválido de /healthz');

    const data = dataUnknown; // tipado por guard
    expect(data.status).toBe('ok');
    expect(typeof data.service).toBe('string');
    expect(typeof data.uptime).toBe('number');
  });
});
TS

# analyze.spec.ts
cat > "$TEST/analyze.spec.ts" <<'TS'
/**
 * Testes do endpoint /analyze com tipagem segura e guards.
 */
import { describe, it, expect } from 'vitest';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import type { FastifyInstance } from 'fastify';
import { registerRoutes } from '../src/index';

/** Modelo de resposta /analyze */
type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

function isAnalyzeResponse(u: unknown): u is AnalyzeResponse {
  if (typeof u !== 'object' || u === null) return false;
  const o = u as Record<string, unknown>;
  return typeof o.ok === 'boolean'
    && typeof o.inputLen === 'number'
    && typeof o.outputLen === 'number'
    && typeof o.result === 'string';
}

describe('server :: /analyze', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = Fastify({ logger: false });
    await app.register(cors, { origin: true });
    registerRoutes(app);
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it('compacta o texto e retorna ok=true', async () => {
    const payload = { input: '  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ' };
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload,
      headers: { 'content-type': 'application/json' },
    });
    expect(res.statusCode).toBe(200);

    const dataUnknown: unknown = await res.json();
    if (!isAnalyzeResponse(dataUnknown)) throw new Error('payload inválido de /analyze');

    const data = dataUnknown;
    expect(data.ok).toBe(true);
    expect(data.result.includes('Olá Mini-IDE!')).toBe(true);
  });

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const payload = { input: 'AAAAA BBBBB CCCCC DDDDD EEEEE', maxLen: 10 };
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload,
      headers: { 'content-type': 'application/json' },
    });
    expect(res.statusCode).toBe(200);

    const dataUnknown: unknown = await res.json();
    if (!isAnalyzeResponse(dataUnknown)) throw new Error('payload inválido de /analyze');

    const data = dataUnknown;
    expect(data.ok).toBe(true);
    expect(data.outputLen).toBeLessThanOrEqual(10);
  });
});
TS

echo "[info] validando @mini-ide/server…"
( cd "$SRV" && pnpm -s build && pnpm -s lint && pnpm -s test )

echo "== 47 :: OK — testes tipados sem 'unsafe-*' ✅ =="
