# 50_expose_register_routes.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Objetivo:
# - Reescrever packages/server/src/index.ts para expor registerRoutes(app)
# - Manter boot isolado (somente fora de testes)
# - Passar nos testes que importam { registerRoutes } de '../src/index'
# - Rodar build/lint/test do pacote @mini-ide/server

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
SRV="$ROOT/packages/server"
SRC="$SRV/src"
IDX="$SRC/index.ts"
PG="$SRC/portGuard.ts"

echo "== 50 :: EXPOSE registerRoutes(app) =="

[[ -d "$SRC" ]] || { echo "[erro] diretório não encontrado: $SRC"; exit 1; }
[[ -f "$PG"  ]] || { echo "[erro] portGuard.ts não encontrado: $PG"; exit 1; }

# Backup do index.ts atual (se existir)
if [[ -f "$IDX" ]]; then
  cp -f "$IDX" "$IDX.bak_$(date +%Y%m%d-%H%M%S)"
fi

# Reescreve index.ts com export registerRoutes + boot isolado
cat > "$IDX" <<'TSCODE'
/**
 * Mini-IDE :: Server (Fastify)
 *
 * @remarks
 * Este módulo expõe a função {@link registerRoutes} (usada pelos testes)
 * e, fora de ambiente de testes, realiza o boot do servidor HTTP.
 */

import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { compactPrompt } from '@mini-ide/analysis-agent';
import { checkPortFree } from './portGuard';

/**
 * Registra as rotas públicas do servidor no app fornecido.
 *
 * @param app - Instância Fastify onde as rotas serão registradas.
 */
export function registerRoutes(app: FastifyInstance): void {
  // GET /healthz
  app.get('/healthz', async () => {
    return {
      status: 'ok' as const,
      service: 'mini-ide-server',
      uptime: process.uptime(),
    };
  });

  // POST /analyze
  app.post('/analyze', async (request) => {
    // Tipos de entrada e saída simples para segurança mínima
    type AnalyzeBody = { input?: string; maxLen?: number };
    type AnalyzeResponse = { ok: true; inputLen: number; outputLen: number; result: string } |
                           { ok: false; error: string };

    const body = (request.body ?? {}) as AnalyzeBody;
    const input = typeof body.input === 'string' ? body.input : '';
    const maxLen = typeof body.maxLen === 'number' && Number.isFinite(body.maxLen) && body.maxLen > 0
      ? Math.floor(body.maxLen)
      : undefined;

    if (!input) {
      const resp: AnalyzeResponse = { ok: false, error: 'input vazio' };
      return resp;
    }

    const result = compactPrompt(input, maxLen ? { maxLen } : undefined);
    const resp: AnalyzeResponse = {
      ok: true,
      inputLen: input.length,
      outputLen: result.length,
      result,
    };
    return resp;
  });
}

/**
 * Executa o servidor HTTP quando não estiver em ambiente de testes.
 * - Respeita PORT do ambiente (com acesso por index signature)
 * - Garante porta livre antes de iniciar
 * - Registra CORS (origin: true) para desenvolvimento
 */
async function boot(): Promise<void> {
  const portEnv = process.env['PORT'];
  const port = Number(portEnv ?? 3000);

  const app = Fastify({ logger: false });
  await app.register(cors, { origin: true });

  registerRoutes(app);

  const free = await checkPortFree(port);
  if (!free) {
    throw new Error(`Porta ${port} indisponível`);
  }

  await app.listen({ host: '0.0.0.0', port });
  // eslint-disable-next-line no-console
  console.log(`[mini-ide] server running on http://localhost:${port}`);
}

// Somente faz boot quando não for ambiente de testes (Vitest)
if (!process.env['VITEST']) {
  boot().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[mini-ide] boot error:', err);
    process.exit(1);
  });
}
TSCODE

# Normaliza finais de linha para LF
sed -i 's/\r$//' "$IDX"

echo "[info] validando @mini-ide/server…"
( cd "$SRV" && pnpm -s build && pnpm -s lint && pnpm -s test )

echo "== 50 :: OK — registerRoutes exposto e pipeline do server verde ✅ =="
