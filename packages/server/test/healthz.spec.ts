import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('GET /healthz', () => {
  let server: FastifyInstance;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('should return 200 with status ok', async () => {
    const response = await inject(server, {
      method: 'GET',
      url: '/healthz',
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ status: string; timestamp: string }>(response);
    expect(body.status).toBe('ok');
    expect(body.timestamp).toBeDefined();
  });
});
