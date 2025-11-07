# 41_fix_inject_tests_undeclared_app.sh
# =========================================================================================
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do repo)
#
# Objetivo:
#   - Corrigir testes do @mini-ide/server que usavam destructuring com getter
#     antes do beforeAll, causando 'app undefined'.
#   - Migrar para padrão robusto: let app; beforeAll cria, afterAll fecha, e
#     cada teste usa app já inicializado.
#
# Resultado esperado:
#   - `pnpm -F @mini-ide/server test` passa sem depender de porta/processo externo.
#
# Boas práticas:
#   - Testes em memória via fastify.inject()
#   - Tipagem explícita de respostas
#   - Finais de linha normalizados (LF)
# =========================================================================================
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV_DIR="$ROOT/packages/server"
SRC_DIR="$SRV_DIR/src"
TEST_DIR="$SRV_DIR/test"

echo "== 41 :: FIX INJECT TESTS (beforeAll/afterAll) =="

[ -d "$TEST_DIR" ] || { echo "[erro] Não achei $TEST_DIR"; exit 1; }

# healthz.spec.ts
cat > "$TEST_DIR/healthz.spec.ts" <<'TS'
/**
 * Testes do endpoint /healthz usando fastify.inject (sem rede/porta real).
 * Padrão robusto: let app; beforeAll/afterAll garantem ciclo de vida.
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildServer } from '../src/index';

type HealthzResponse = {
  status: 'ok';
  service: string;
  uptime: number;
};

describe('server :: /healthz', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildServer();
  });

  afterAll(async () => {
    await app.close();
  });

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
cat > "$TEST_DIR/analyze.spec.ts" <<'TS'
/**
 * Testes do endpoint /analyze usando fastify.inject (sem rede/porta real).
 * Padrão robusto: let app; beforeAll/afterAll garantem ciclo de vida.
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { buildServer } from '../src/index';

type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

describe('server :: /analyze', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('compacta o texto e retorna ok=true', async () => {
    const payload = {
      input: '  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ',
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
      input: 'Linha  1   com   espaços\r\n\r\n   Linha  2\ttabs',
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

# Normaliza finais de linha
sed -i 's/\r$//' "$TEST_DIR/healthz.spec.ts" "$TEST_DIR/analyze.spec.ts"

echo "[info] build @mini-ide/server…"
pnpm -F @mini-ide/server run build

echo "[info] test @mini-ide/server…"
pnpm -F @mini-ide/server run test

echo "== 41 :: OK — testes usando beforeAll/afterAll e app.inject() =="
