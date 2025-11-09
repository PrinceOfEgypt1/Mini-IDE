import Fastify, { type FastifyInstance, type FastifyReply, type FastifyRequest } from 'fastify';
import { randomUUID } from 'crypto';

/** Corpo do POST /analyze */
type AnalyzeBody = {
  text?: unknown;
  maxLen?: unknown;
};

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string' && v.trim().length >= 1;
}

function isValidMaxLen(v: unknown): v is number {
  return typeof v === 'number' && Number.isInteger(v) && v >= 1 && v <= 1000;
}

function countTokens(s: string): number {
  const t = s.trim();
  if (t === '') return 0;
  return t.split(/\s+/).length;
}

function bad(reply: FastifyReply, details: string) {
  return reply
    .code(400)
    .type('application/json; charset=utf-8')
    .send({ error: 'Bad Request', details });
}

/** Registra as rotas da aplicação para uso nos testes e no servidor real. */
export function registerRoutes(app: FastifyInstance): void {
  app.get('/healthz', async (_req: FastifyRequest, reply: FastifyReply) => {
    return reply
      .type('application/json; charset=utf-8')
      .send({ status: 'ok', timestamp: new Date().toISOString() });
  });

  app.post('/analyze', async (req: FastifyRequest<{ Body: AnalyzeBody }>, reply: FastifyReply) => {
    const { text, maxLen } = req.body ?? {};

    if (!isNonEmptyString(text)) {
      return bad(reply, 'text obrigatório (string não vazia)');
    }

    let limit = 100; // default
    if (maxLen !== undefined) {
      if (!isValidMaxLen(maxLen)) {
        return bad(reply, 'maxLen inválido: inteiro em [1..1000]');
      }
      limit = maxLen;
    }

    const summary = text.trim().slice(0, limit);
    const tokensUsed = countTokens(summary);
    const runId = `run-${randomUUID()}`;

    return reply
      .type('application/json; charset=utf-8')
      .send({ summary, tokensUsed, runId, ts: new Date().toISOString() });
  });
}

/** Bootstrap opcional: permite rodar como servidor real (fora dos testes). */
if (require.main === module) {
  const app = Fastify({ logger: true });
  registerRoutes(app);

  const port = Number(process.env['PORT'] ?? 3333);
  app
    .listen({ port, host: '0.0.0.0' })
    .then(() => {
      // noop
    })
    .catch((err) => {
      app.log.error(err);
      process.exit(1);
    });
}
