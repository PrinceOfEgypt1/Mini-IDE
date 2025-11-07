#!/usr/bin/env bash
set -euo pipefail

SRV_DIR="packages/server"
TEST_DIR="$SRV_DIR/test"

echo "== 56 :: FIX server tests (lint: unnecessary-type-assertion / base-to-string) =="

# healthz.spec.ts
cat > "$TEST_DIR/healthz.spec.ts" <<'TS'
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import Fastify, { type FastifyInstance } from 'fastify'
import cors from '@fastify/cors'
import { registerRoutes } from '../src/index'

type HealthzResponse = {
  status: 'ok'
  service: string
  uptime: number
}

function isHealthzResponse(x: unknown): x is HealthzResponse {
  if (!x || typeof x !== 'object') return false
  const o = x as Record<string, unknown>
  return (
    o['status'] === 'ok' &&
    typeof o['service'] === 'string' &&
    typeof o['uptime'] === 'number'
  )
}

function assertHealthzResponse(x: unknown): asserts x is HealthzResponse {
  if (!isHealthzResponse(x)) {
    throw new Error('Invalid HealthzResponse')
  }
}

describe('server :: /healthz', () => {
  let app: FastifyInstance

  beforeAll(async () => {
    app = Fastify({ logger: false })
    await app.register(cors, { origin: true })
    registerRoutes(app)
    await app.ready()
  })

  afterAll(async () => {
    await app.close()
  })

  it('retorna status ok, service e uptime numérico', async () => {
    const res = await app.inject({ method: 'GET', url: '/healthz' })
    expect(res.statusCode).toBe(200)

    const obj: unknown = res.json()
    assertHealthzResponse(obj)

    expect(obj.status).toBe('ok')
    expect(typeof obj.service).toBe('string')
    expect(typeof obj.uptime).toBe('number')
  })
})
TS

# analyze.spec.ts
cat > "$TEST_DIR/analyze.spec.ts" <<'TS'
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import Fastify, { type FastifyInstance } from 'fastify'
import cors from '@fastify/cors'
import { registerRoutes } from '../src/index'

type AnalyzeResponse = {
  ok: boolean
  inputLen: number
  outputLen: number
  result: string
}

function isAnalyzeResponse(x: unknown): x is AnalyzeResponse {
  if (!x || typeof x !== 'object') return false
  const o = x as Record<string, unknown>
  return (
    typeof o['ok'] === 'boolean' &&
    typeof o['inputLen'] === 'number' &&
    typeof o['outputLen'] === 'number' &&
    typeof o['result'] === 'string'
  )
}

function assertAnalyzeResponse(x: unknown): asserts x is AnalyzeResponse {
  if (!isAnalyzeResponse(x)) {
    throw new Error('Invalid AnalyzeResponse')
  }
}

describe('server :: /analyze', () => {
  let app: FastifyInstance

  beforeAll(async () => {
    app = Fastify({ logger: false })
    await app.register(cors, { origin: true })
    registerRoutes(app)
    await app.ready()
  })

  afterAll(async () => {
    await app.close()
  })

  it('compacta o texto e retorna ok=true', async () => {
    const payload = { text: '  Olá Mini-IDE!  \r\n\r\n   Demo de  compactação   ' }
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload
    })
    expect(res.statusCode).toBe(200)

    const obj: unknown = res.json()
    assertAnalyzeResponse(obj)

    expect(obj.ok).toBe(true)
    expect(obj.inputLen).toBeGreaterThan(0)
    expect(obj.outputLen).toBeGreaterThan(0)
    // evita no-base-to-string: garante string explicitamente
    const out = String(obj.result)
    expect(out.length).toBeGreaterThan(0)
  })

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const payload = { text: '  Olá Mini-IDE!  \r\n\r\n   Demo de  compactação   ', maxLen: 10 }
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload
    })
    expect(res.statusCode).toBe(200)

    const obj: unknown = res.json()
    assertAnalyzeResponse(obj)

    const out = String(obj.result)
    expect(out.length).toBeLessThanOrEqual(10)
  })
})
TS

echo "[info] Rodando lint + test do @mini-ide/server…"
pnpm --filter @mini-ide/server lint
pnpm --filter @mini-ide/server typecheck
pnpm --filter @mini-ide/server test

echo "== 56 :: OK — testes do server conformes ao ESLint ✅ =="
