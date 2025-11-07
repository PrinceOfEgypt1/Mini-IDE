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
