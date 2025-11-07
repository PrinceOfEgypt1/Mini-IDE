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
  app.get('/healthz', () => {
    return {
      status: 'ok' as const,
      service: 'mini-ide-server',
      uptime: process.uptime(),
    };
  });

  // POST /analyze
  app.post('/analyze', (request) => {
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
  console.log(`[mini-ide] server running on http://localhost:${port}`);
}

// Somente faz boot quando não for ambiente de testes (Vitest)
if (!process.env['VITEST']) {
  boot().catch((err) => {
    console.error('[mini-ide] boot error:', err);
    process.exit(1);
  });
}
