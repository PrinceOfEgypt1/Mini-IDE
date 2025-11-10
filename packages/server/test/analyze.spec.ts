import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('POST /analyze - Happy Path (200)', () => {
  let server: FastifyInstance;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('AC1: should return 200 with valid text and maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      tokensUsed: number;
      runId: string;
      timestamp: string;
    }>(response);
    expect(body.summary).toBeDefined();
    expect(body.summary.length).toBeLessThanOrEqual(10);
    expect(body.tokensUsed).toBeGreaterThan(0);
    expect(body.runId).toMatch(/^run-/);
    expect(body.timestamp).toBeDefined();
  });

  it('AC2: should use default maxLen (100) when omitted', async () => {
    const longText = 'a'.repeat(150);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBeLessThanOrEqual(100);
  });

  it('AC3: should include all required fields in response', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test analysis', maxLen: 50 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      tokensUsed: number;
      runId: string;
      timestamp: string;
    }>(response);
    expect(body).toHaveProperty('summary');
    expect(body).toHaveProperty('tokensUsed');
    expect(body).toHaveProperty('runId');
    expect(body).toHaveProperty('timestamp');
  });

  it('should handle text with multiple tokens correctly', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'One two three four five', maxLen: 100 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ tokensUsed: number }>(response);
    expect(body.tokensUsed).toBeGreaterThan(1);
  });

  it('should handle maxLen at minimum boundary (1)', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello', maxLen: 1 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBe(1);
  });

  it('should handle maxLen at maximum boundary (1000)', async () => {
    const longText = 'a'.repeat(2000);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText, maxLen: 1000 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body.summary.length).toBeLessThanOrEqual(1000);
  });
});
