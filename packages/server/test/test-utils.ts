import Fastify, { type FastifyInstance } from 'fastify';
import { registerRoutes } from '../src/index';

/**
 * Constrói o app e registra as rotas, sem aguardar `ready()`.
 * Útil para specs que fazem: `const app = build(); await app.ready();`
 */
export function build(): FastifyInstance {
  const app = Fastify({ logger: false });
  registerRoutes(app);
  return app;
}

/**
 * Versão conveniência que já garante `await app.ready()`.
 * Útil para specs que fazem: `const app = await buildServer();`
 */
export async function buildServer(): Promise<FastifyInstance> {
  const app = build();
  await app.ready();
  return app;
}

/** Encerra o servidor de testes. */
export async function shutdown(app: FastifyInstance): Promise<void> {
  await app.close();
}

/** Opções aceitas pelo helper de injeção. */
export type InjectOpts = {
  method?: string;
  url: string;
  payload?: unknown;
  headers?: Record<string, string>;
};

/** Tipo da resposta de injeção do Fastify. */
export type TestResponse = Awaited<ReturnType<FastifyInstance['inject']>>;

/**
 * Helper de injeção usado pelos testes.
 * Aceita string (atalho GET) ou objeto com { method, url, payload, headers }.
 */
export async function inject(
  app: FastifyInstance,
  opts: InjectOpts | string,
): Promise<TestResponse> {
  const normalized = typeof opts === 'string' ? { method: 'GET', url: opts } : opts;
  return app.inject(normalized);
}

/** Extrai o status code da resposta. */
export function status(res: TestResponse): number {
  return res.statusCode;
}

/** Converte o corpo para objeto desconhecido (sem `any`). */
export function jsonUnknown(res: TestResponse): unknown {
  return res.json();
}
