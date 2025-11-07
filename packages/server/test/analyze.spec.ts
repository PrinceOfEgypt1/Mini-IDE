import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import Fastify, { type FastifyInstance } from 'fastify'
import cors from '@fastify/cors'
import { registerRoutes } from '../src/index'

type NumLike = number | string

type AnalyzeResponse = {
  ok: boolean
  inputLen: NumLike
  outputLen: NumLike
  result: string
}

function isNumLike(v: unknown): v is NumLike {
  return typeof v === 'number' || (typeof v === 'string' && v.trim() !== '' && !Number.isNaN(Number(v)))
}

function isAnalyzeResponse(x: unknown): x is AnalyzeResponse {
  if (!x || typeof x !== 'object') return false
  const o = x as Record<string, unknown>
  return (
    typeof o['ok'] === 'boolean' &&
    isNumLike(o['inputLen']) &&
    isNumLike(o['outputLen']) &&
    Object.prototype.hasOwnProperty.call(o, 'result')
  )
}

function coerceLen(v: NumLike): number {
  return typeof v === 'number' ? v : Number(v)
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
    const payload = { input: '  Olá Mini-IDE!  \r\n\r\n   Demo de  compactação   ' }
    const res = await app.inject({ method: 'POST', url: '/analyze', payload })
    expect(res.statusCode).toBe(200)

    const raw: unknown = res.json()
    if (!isAnalyzeResponse(raw)) {
      console.error('DEBUG /analyze body:', raw)
      throw new Error('Invalid AnalyzeResponse')
    }

    const outStr = String(raw.result)
    const inLen = coerceLen(raw.inputLen)
    const outLen = coerceLen(raw.outputLen)

    expect(raw.ok).toBe(true)
    expect(inLen).toBeGreaterThan(0)
    expect(outLen).toBeGreaterThan(0)
    expect(outStr.length).toBeGreaterThan(0)
  })

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const payload = { input: '  Olá Mini-IDE!  \r\n\r\n   Demo de  compactação   ', maxLen: 10 }
    const res = await app.inject({ method: 'POST', url: '/analyze', payload })
    expect(res.statusCode).toBe(200)

    const raw: unknown = res.json()
    if (!isAnalyzeResponse(raw)) {
      console.error('DEBUG /analyze body:', raw)
      throw new Error('Invalid AnalyzeResponse')
    }

    const outStr = String(raw.result)
    const outLen = coerceLen(raw.outputLen)
    expect(outStr.length).toBeLessThanOrEqual(10)
    expect(outLen).toBeLessThanOrEqual(10)
  })
})
