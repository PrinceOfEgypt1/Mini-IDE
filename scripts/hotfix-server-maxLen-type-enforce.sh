#!/usr/bin/env bash
# scripts/hotfix-server-maxLen-type-enforce.sh
set -euo pipefail

SRV_INDEX="packages/server/src/index.ts"
[[ -f "$SRV_INDEX" ]] || { echo "[erro] não achei $SRV_INDEX"; exit 1; }

cp -f "$SRV_INDEX" "${SRV_INDEX}.bak.maxlen_$(date +%Y%m%d-%H%M%S)"

cat > "$SRV_INDEX" <<'TS'
// packages/server/src/index.ts
import Fastify, { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify'
import { randomUUID } from 'crypto'

type AnalyzeBody = {
  text?: unknown
  maxLen?: unknown
}

/** Registra rotas exigidas pelos testes e HUs */
export function registerRoutes(app: FastifyInstance): FastifyInstance {
  // /healthz -> { status: "ok", timestamp: "<ISO>" }
  app.get('/healthz', async (_req: FastifyRequest, reply: FastifyReply) => {
    const timestamp = new Date().toISOString()
    return reply
      .code(200)
      .type('application/json; charset=utf-8')
      .send({ status: 'ok', timestamp })
  })

  // POST /analyze
  app.post(
    '/analyze',
    async (req: FastifyRequest<{ Body: AnalyzeBody }>, reply: FastifyReply) => {
      const body = (req.body ?? {}) as AnalyzeBody
      const { text, maxLen } = body

      // === Validações 400 (HU-Server-Analyze-400) ===
      if (typeof text !== 'string') {
        return reply
          .code(400)
          .type('application/json; charset=utf-8')
          .send({ error: 'Bad Request', details: 'Campo "text" é obrigatório e deve ser string.' })
      }
      if (text.trim().length < 1) {
        return reply
          .code(400)
          .type('application/json; charset=utf-8')
          .send({ error: 'Bad Request', details: 'Campo "text" não pode ser vazio.' })
      }

      // >>> ENFORCE: maxLen deve ser NUMBER inteiro [1..1000]. Strings não são aceitas.
      let limit = 100
      if (maxLen !== undefined) {
        if (typeof maxLen !== 'number' || !Number.isInteger(maxLen) || maxLen < 1 || maxLen > 1000) {
          return reply
            .code(400)
            .type('application/json; charset=utf-8')
            .send({ error: 'Bad Request', details: 'Campo "maxLen" deve ser number inteiro no intervalo [1..1000].' })
        }
        limit = maxLen
      }

      // === Caminho 200 (preservado) ===
      const tokensUsed = String(text).split(/\s+/).filter(Boolean).length
      const summary = String(text).slice(0, Math.min(limit, String(text).length))
      const runId = `run-${randomUUID()}` // formato exigido pelo teste
      const ts = new Date().toISOString()

      // Log estruturado usado nos testes
      // eslint-disable-next-line no-console
      console.log(JSON.stringify({
        event: 'analyze.200',
        runId, ts,
        textLen: String(text).length,
        maxLen: limit,
        summaryLen: summary.length,
        tokensUsed
      }))

      return reply
        .code(200)
        .type('application/json; charset=utf-8')
        .send({ summary, tokensUsed, runId, ts })
    }
  )

  return app
}

/** Constrói a aplicação (usado pelos testes e execução standalone) */
export function build(): FastifyInstance {
  const app = Fastify({ logger: false })
  registerRoutes(app)
  return app
}

// Execução standalone opcional
if (require.main === module) {
  const app = build()
  const port = Number((process.env as Record<string, string | undefined>)['PORT'] ?? 3000)
  app
    .listen({ port, host: '0.0.0.0' })
    .then(() => {
      // eslint-disable-next-line no-console
      console.log(`[server] listening on :${port}`)
    })
    .catch((err) => {
      // eslint-disable-next-line no-console
      console.error(err)
      process.exit(1)
    })
}
TS

echo "[ok] server/index.ts atualizado (maxLen exige number inteiro)."

echo "[info] Build + testes do @mini-ide/server…"
pnpm -w --filter @mini-ide/server build
pnpm -w --filter @mini-ide/server test

echo
echo "✅ Se tudo verde:"
echo "   git add $SRV_INDEX"
echo '   git commit -m "fix(server): HU-400 — maxLen exige number inteiro (strings rejeitadas)"; git push -u origin feat/server-analyze-400'
