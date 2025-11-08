import type { FastifyInstance } from "fastify";
import Fastify from "fastify";
import { registerRoutes } from "../src/index.js";

/**
 * Tipo local para injeção de requisições
 */
export type Injectable =
  | string
  | {
      method: string;
      url: string;
      payload?: unknown;
      headers?: Record<string, string>;
    };

/**
 * Tipo de resposta simplificado (sem depender de light-my-request)
 */
export interface TestResponse {
  statusCode: number;
  body: string;
  headers: Record<string, string>;
  json(): unknown;
}

/**
 * Cria instância do servidor Fastify
 */
export async function buildServer(): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });
  registerRoutes(app);
  await app.ready();
  return app;
}

/**
 * Fecha servidor
 */
export async function shutdown(app: FastifyInstance): Promise<void> {
  await app.close();
}

/**
 * Injeta requisição
 */
export async function inject(
  app: FastifyInstance,
  opts: Injectable
): Promise<TestResponse> {
  const responder = app as { inject: (o: unknown) => Promise<unknown> };
  const resUnknown = await responder.inject(opts as unknown);
  return resUnknown as TestResponse;
}

/**
 * Extrai status code
 */
export function status(res: TestResponse): number {
  return res.statusCode;
}

/**
 * Retorna corpo como unknown
 */
export function jsonUnknown(res: TestResponse): unknown {
  return res.json();
}
