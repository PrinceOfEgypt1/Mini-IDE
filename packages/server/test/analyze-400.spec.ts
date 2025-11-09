import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils';

/**
 * HU-Server-Analyze-400 - validações e respostas 400
 *
 * Objetivo: garantir que /analyze responda 400 para entradas inválidas
 * e mantenha o happy path sólido para comparação.
 */
describe('HU-Server-Analyze-400 - validações e respostas 400', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    // harness padronizado: build() retorna FastifyInstance
    app = build();
    await app.ready();
  });

  afterAll(async () => {
    await shutdown(app);
  });

  // AC1: text ausente -> 400
  it('AC1: text ausente -> 400', async () => {
    const res = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: {}, // sem "text"
    });
    expect(status(res)).toBe(400);

    const body = jsonUnknown(res) as { error?: string; details?: string };
    expect(body.error).toBe('Bad Request');
    expect(body.details).toBeDefined();
  });

  // AC2: text vazio/whitespace -> 400
  it('AC2: text vazio/whitespace -> 400', async () => {
    const res = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: '   ' },
    });
    expect(status(res)).toBe(400);

    const body = jsonUnknown(res) as { error?: string; details?: string };
    expect(body.error).toBe('Bad Request');
  });

  // AC3: text não-string -> 400 (number/array/obj/bool/null)
  it('AC3: text não-string -> 400 (number/array/obj/bool/null)', async () => {
    const invalids: unknown[] = [123, ['a'], { t: 'x' }, false, null];
    for (const v of invalids) {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: v },
      });
      expect(status(res)).toBe(400);

      const body = jsonUnknown(res) as { error?: string; details?: string };
      expect(body.error).toBe('Bad Request');
    }
  });

  // AC4: maxLen inválido (<1, >1000, não-inteiro, tipo errado) -> 400
  it('AC4: maxLen inválido (<1, >1000, não-inteiro, tipo errado) -> 400', async () => {
    const invalids: unknown[] = [0, -1, 1001, 3.14, '10', 'a', null, false, {}, []];

    for (const v of invalids) {
      const res = await inject(app, {
        method: 'POST',
        url: '/analyze',
        payload: { text: 'ok', maxLen: v },
      });
      expect(status(res)).toBe(400);

      const body = jsonUnknown(res) as { error?: string; details?: string };
      expect(body.error).toBe('Bad Request');
    }
  });

  // AC5: 400 sempre com shape padronizado e content-type
  it('AC5: 400 sempre com shape padronizado e content-type', async () => {
    const res = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { maxLen: 10 }, // sem text
    });
    expect(status(res)).toBe(400);

    // @note: headers acessíveis normalmente pelo helper/status, aqui checamos o content-type
    const ct = res.headers['content-type'] ?? res.headers['Content-Type'];
    expect(String(ct)).toContain('application/json');

    const body = jsonUnknown(res) as Record<string, unknown>;
    expect(body).toMatchObject({ error: 'Bad Request' });
  });

  // Happy path 200 segue intacto (sanidade dentro da suíte 400)
  it('Happy path 200 segue intacto', async () => {
    const res = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'lorem ipsum', maxLen: 5 },
    });
    expect(status(res)).toBe(200);

    const body = jsonUnknown(res) as {
      summary?: string;
      tokensUsed?: number;
      runId?: string;
      ts?: string;
    };

    expect(typeof body.summary).toBe('string');
    expect(typeof body.tokensUsed).toBe('number');
    expect(typeof body.runId).toBe('string');
    expect(typeof body.ts).toBe('string');
  });
});
