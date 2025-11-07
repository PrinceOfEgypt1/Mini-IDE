#!/usr/bin/env bash
# 53_fix_tests_index_signature.sh
# Local: executar NA RAIZ do projeto (~/workspace/Mini-IDE)
# Objetivo: corrigir TS4111 nos testes do @mini-ide/server
# - Substitui acessos com '.' por acesso com ['...'] em objetos tipados por index signature
# - Reescreve os testes com parsing seguro do JSON (unknown -> Record<string, unknown>)
# - Garante beforeAll/afterAll com app.inject()
# - Valida build/typecheck/lint/test do pacote server

set -euo pipefail

ROOT="$(pwd)"
SRV_DIR="$ROOT/packages/server"
TEST_DIR="$SRV_DIR/test"

echo "== 53 :: FIX TESTS (index-signature / TS4111) =="
echo "[ctx] ROOT=$ROOT"
echo "[ctx] SRV_DIR=$SRV_DIR"
echo "[ctx] TEST_DIR=$TEST_DIR"

[[ -d "$SRV_DIR" ]] || { echo "[erro] Pacote server não encontrado em $SRV_DIR"; exit 1; }
[[ -d "$TEST_DIR" ]] || mkdir -p "$TEST_DIR"

# -------------------------------------------------------------------
# healthz.spec.ts
# -------------------------------------------------------------------
cat > "$TEST_DIR/healthz.spec.ts" <<'TS'
/**
 * Testes do endpoint /healthz com tipagem segura e app.inject().
 */
import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { registerRoutes } from '../src/index';

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

    const json = res.json() as unknown;
    const obj = (json ?? {}) as Record<string, unknown>;

    expect(obj['status']).toBe('ok');
    expect(typeof obj['service']).toBe('string');
    expect(typeof obj['uptime']).toBe('number');
  });
});
TS

# -------------------------------------------------------------------
# analyze.spec.ts
# -------------------------------------------------------------------
cat > "$TEST_DIR/analyze.spec.ts" <<'TS'
/**
 * Testes do endpoint /analyze com tipagem segura e app.inject().
 */
import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { registerRoutes } from '../src/index';

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

    const json = res.json() as unknown;
    const obj = (json ?? {}) as Record<string, unknown>;

    expect(obj['ok']).toBe(true);
    expect(typeof obj['result']).toBe('string');
    expect(typeof obj['outputLen']).toBe('number');
  });

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const payload = { input: '  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ', maxLen: 10 };

    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload,
      headers: { 'content-type': 'application/json' },
    });
    expect(res.statusCode).toBe(200);

    const json = res.json() as unknown;
    const obj = (json ?? {}) as Record<string, unknown>;

    expect(obj['ok']).toBe(true);
    expect(typeof obj['result']).toBe('string');

    const result = String(obj['result'] ?? '');
    expect(result.length).toBeLessThanOrEqual(10);
  });
});
TS

# -------------------------------------------------------------------
# Validação do pacote server
# -------------------------------------------------------------------
echo "[info] build/lint/typecheck/test do @mini-ide/server…"
( cd "$SRV_DIR" && pnpm run build && pnpm run lint && pnpm run typecheck && pnpm run test )

echo "== 53 :: OK — testes corrigidos e pacote server validado ✅ =="
