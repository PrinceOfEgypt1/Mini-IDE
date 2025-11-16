/**
 * @file test-utils.ts
 * @description Utilitários para testes do servidor (API retrocompatível)
 *
 * CHANGELOG v1.0.17-patch3:
 * - API retrocompatível: aceita inject(server, opts) OU inject(opts)
 * - API retrocompatível: aceita shutdown(server) OU shutdown()
 * - jsonUnknown com suporte a type generics
 *
 * @version 1.0.17-patch3
 */

import type { FastifyInstance } from 'fastify';
import type { InjectOptions, Response } from 'light-my-request';
import { server } from '../src/index.js';

/**
 * Instância do servidor para uso nos testes
 */
let testServer: FastifyInstance | null = null;

/**
 * Inicializa o servidor para testes
 *
 * @returns Promise com instância do servidor pronta
 */
export async function build(): Promise<FastifyInstance> {
  if (!testServer) {
    testServer = server;
    await testServer.ready();
  }
  return testServer;
}

/**
 * Fecha o servidor após os testes
 * RETROCOMPATÍVEL: aceita shutdown(server) OU shutdown()
 *
 * @param _serverInstance - (Opcional) instância do servidor (ignorada, mantida por retrocompatibilidade)
 */
export async function shutdown(_serverInstance?: FastifyInstance): Promise<void> {
  // Ignora _serverInstance - mantido apenas para retrocompatibilidade
  if (testServer) {
    await testServer.close();
    testServer = null;
  }
}

/**
 * Helper para fazer requisições de teste
 * RETROCOMPATÍVEL: aceita inject(server, opts) OU inject(opts)
 *
 * @param serverOrOptions - Servidor (ignorado) OU opções da requisição
 * @param optionsIfServerProvided - Opções se primeiro param for servidor
 * @returns Promise com resposta da requisição
 */
export async function inject(
  serverOrOptions: FastifyInstance | InjectOptions,
  optionsIfServerProvided?: InjectOptions,
): Promise<Response> {
  if (!testServer) {
    await build();
  }

  // Detectar qual assinatura foi usada
  const options: InjectOptions = optionsIfServerProvided
    ? optionsIfServerProvided // inject(server, options) - API antiga
    : (serverOrOptions as InjectOptions); // inject(options) - API nova

  return testServer!.inject(options);
}

/**
 * Type guard para verificar se objeto é um Record válido
 */
function isRecord(obj: unknown): obj is Record<string, unknown> {
  return typeof obj === 'object' && obj !== null && !Array.isArray(obj);
}

/**
 * Helper para extrair status code de resposta
 */
export function status(response: Response): number {
  return response.statusCode;
}

/**
 * Helper para parsear JSON de resposta com type safety
 * SUPORTA GENERICS: jsonUnknown<Type>(response)
 *
 * @param response - Resposta da requisição
 * @returns Objeto parseado do JSON
 * @throws Error se o body não for JSON válido
 */
export function jsonUnknown<T = Record<string, unknown>>(response: Response): T {
  try {
    const parsed: unknown = JSON.parse(response.body);
    if (isRecord(parsed)) {
      return parsed as T;
    }
    throw new Error('Response body não é um objeto JSON válido');
  } catch (error) {
    throw new Error(
      `Falha ao parsear JSON: ${error instanceof Error ? error.message : 'Unknown error'}`,
    );
  }
}
