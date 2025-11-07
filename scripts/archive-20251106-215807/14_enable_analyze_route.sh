#!/usr/bin/env bash
set -euo pipefail
echo "== MINI-IDE :: 14_enable_analyze_route =="

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"

# 1) Garantir dependência interna já existe (deve existir desde o scaffold)
#    @mini-ide/analysis-agent já estava em server/package.json como workspace:*
#    Se quiser reforçar idempotência, descomente a linha abaixo:
# pnpm -F @mini-ide/server add @mini-ide/analysis-agent@workspace:*

# 2) Atualizar o servidor para expor POST /analyze
cat > "$SRV/src/index.ts" <<'EOF'
import Fastify from 'fastify';
import { compactPrompt } from '@mini-ide/analysis-agent';

export function buildServer() {
  const app = Fastify({ logger: false });

  app.get('/healthz', async () => {
    return { status: 'ok', service: 'mini-ide-server', uptime: process.uptime() };
  });

  app.post('/analyze', async (request) => {
    // Expecta JSON: { "input": string, "maxLen"?: number }
    // Fail-soft: se não vier JSON válido, tratamos com padrão seguro.
    const body = (request.body ?? {}) as { input?: string; maxLen?: number };
    const input = typeof body.input === 'string' ? body.input : '';
    const maxLen = typeof body.maxLen === 'number' ? body.maxLen : undefined;

    const result = compactPrompt(input, { maxLen });
    return {
      ok: true,
      inputLen: input.length,
      outputLen: result.length,
      result
    };
  });

  return app;
}

// start only if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  const app = buildServer();
  const port = Number(process.env['PORT'] ?? 3000);
  app.listen({ port, host: '0.0.0.0' })
    .then(() => console.log(`[mini-ide] server running on http://localhost:${port}`))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
EOF
echo "[ok] server/src/index.ts atualizado com POST /analyze"

# 3) Teste e2e do /analyze
cat > "$SRV/test/analyze.spec.ts" <<'EOF'
import request from 'supertest';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildServer } from '../src/index';

describe('POST /analyze', () => {
  const app = buildServer();

  beforeAll(async () => { await app.ready(); });
  afterAll(async () => { await app.close(); });

  it('compacta prompt com quebras e espaços', async () => {
    const input = "Linha 1   com   espaços \r\n\r\n\r\n   Linha 2\t\tok";
    const res = await request(app.server)
      .post('/analyze')
      .send({ input })
      .set('content-type', 'application/json')
      .expect(200);

    expect(res.body.ok).toBe(true);
    expect(res.body.result).toBe("Linha 1 com espaços\n\nLinha 2 ok");
    expect(res.body.outputLen).toBe(res.body.result.length);
  });

  it('respeita maxLen quando informado', async () => {
    const input = "A".repeat(50);
    const res = await request(app.server)
      .post('/analyze')
      .send({ input, maxLen: 10 })
      .set('content-type', 'application/json')
      .expect(200);

    expect(res.body.ok).toBe(true);
    expect(typeof res.body.result).toBe('string');
    expect(res.body.result.endsWith(' …')).toBe(true);
    expect(res.body.result.length).toBeLessThanOrEqual(12);
  });
});
EOF
echo "[ok] server/test/analyze.spec.ts criado"

# 4) Build + Test do pacote server
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: /analyze disponível e testado =="
echo "Para experimentar:"
echo "  pnpm -F @mini-ide/server run dev"
echo "  curl -s http://localhost:3000/healthz | jq"
echo "  curl -s -X POST http://localhost:3000/analyze -H 'content-type: application/json' \\"
echo "       -d '{\"input\":\"Linha 1   com   espaços\\n\\n\\n   Linha 2\\tok\"}' | jq"
