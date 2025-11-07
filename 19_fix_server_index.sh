#!/usr/bin/env bash
set -euo pipefail
echo "== MINI-IDE :: 19_fix_server_index =="

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"

# 1) Reescrever o index.ts COMPLETO (corrigido)
cat > "$SRV/src/index.ts" <<'EOF'
import Fastify from 'fastify';
import { compactPrompt } from '@mini-ide/analysis-agent';
import { checkPortFree } from './portGuard';

export function buildServer() {
  const app = Fastify({ logger: false });

  app.get('/healthz', async () => {
    return { status: 'ok', service: 'mini-ide-server', uptime: process.uptime() };
  });

  app.post('/analyze', async (request) => {
    const body = (request.body ?? {}) as { input?: string; maxLen?: number };
    const input = typeof body.input === 'string' ? body.input : '';
    const maxLen = typeof body.maxLen === 'number' ? body.maxLen : undefined;

    const result = compactPrompt(input, { maxLen });
    return {
      ok: true,
      inputLen: input.length,
      outputLen: result.length,
      result,
    };
  });

  return app;
}

// start only if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    const app = buildServer();
    const port = Number(process.env['PORT'] ?? 3000);

    const free = await checkPortFree(port);
    if (!free) {
      console.error(`[mini-ide] porta ${port} já está em uso. Defina PORT para outra porta.`);
      process.exit(1);
    }

    await app.listen({ port, host: '0.0.0.0' });
    console.log(`[mini-ide] server running on http://localhost:${port}`);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
EOF
echo "[ok] server/src/index.ts reescrito com sucesso."

# 2) Build + Test do pacote server
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: server corrigido, compila e testes passam =="
echo "Para subir: pnpm -F @mini-ide/server run dev  (POST /analyze e GET /healthz prontos)"
