/**
 * @file analyze.spec.ts
 * @description Testes do endpoint /analyze
 *
 * CHANGELOG v1.0.17-patch4:
 * - Tipos corrigidos para corresponder a AnalyzeResponse real
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('POST /analyze', () => {
  let server: Awaited<ReturnType<typeof build>>;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('deve processar texto com maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      inputLength: number;
      outputLength: number;
      requestId: string;
      timestamp: string;
      budgetUsed: number;
      budgetRemaining: number;
    }>(response);

    expect(body['summary']).toBeDefined();
    expect(body['summary'].length).toBeLessThanOrEqual(10);
    expect(body['inputLength']).toBeDefined();
    expect(body['outputLength']).toBeDefined();
    expect(body['requestId']).toBeDefined();
    expect(body['timestamp']).toBeDefined();
  });

  it('deve aplicar maxLen padrão quando não especificado', async () => {
    const longText = 'a'.repeat(200);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body['summary'].length).toBeLessThanOrEqual(100);
  });

  it('deve incluir requestId e timestamp na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test analysis', maxLen: 50 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      requestId: string;
      timestamp: string;
    }>(response);
    expect(body['requestId']).toBeDefined();
    expect(String(body['requestId'])).toMatch(/^req_/u);
    expect(body['timestamp']).toBeDefined();
  });

  it('deve incluir informações de budget na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test budget tracking', maxLen: 100 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown(response);
    expect(body['budgetUsed']).toBeDefined();
    expect(body['budgetRemaining']).toBeDefined();
    expect(typeof body['budgetUsed']).toBe('number');
    expect(typeof body['budgetRemaining']).toBe('number');
  });
});
