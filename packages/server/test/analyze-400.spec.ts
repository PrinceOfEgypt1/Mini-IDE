/**
 * Test suite for request validation (400)
 */

import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';
import { resetBudget } from '../src/budget.js';
import type { ErrorResponse } from '../src/index.js';

describe('POST /analyze - Error Cases (400)', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await build();
  });

  afterAll(async () => {
    await shutdown(app);
  });

  beforeEach(() => {
    resetBudget();
  });

  it('AC1: should return 400 when text is missing', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { maxLen: 10 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toContain('text');
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC2: should return 400 when text is empty string', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: '', maxLen: 10 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toContain('text');
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC3: should return 400 when text is not a string', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 123, maxLen: 10 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toBeDefined();
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC4: should return 400 when maxLen is not a number', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Valid text', maxLen: 'invalid' },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toBeDefined();
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC5: should return 400 when maxLen is negative', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Valid text', maxLen: -10 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toContain('maxLen');
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC6: should return 400 when maxLen is zero', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Valid text', maxLen: 0 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toContain('maxLen');
    expect(body.code).toBe('VALIDATION_ERROR');
  });

  it('AC7: should return 400 when maxLen exceeds limit', async () => {
    const response = await inject(app, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Valid text', maxLen: 1001 },
    });

    expect(status(response)).toBe(400);
    const body = jsonUnknown<ErrorResponse>(response);
    expect(body.error).toContain('maxLen');
    expect(body.code).toBe('VALIDATION_ERROR');
  });
});
