#!/usr/bin/env bash
# hotfix-server-runId-healthz-contract.sh
set -euo pipefail

INDEX="packages/server/src/index.ts"
[[ -f "$INDEX" ]] || { echo "[erro] não achei $INDEX"; exit 1; }

cp -f "$INDEX" "${INDEX}.bak.contract_$(date +%Y%m%d-%H%M%S)"

cat > "$INDEX" <<'TS'
// packages/server/src/index.ts
import Fastify from 'fastify'
import { randomUUID } from 'crypto'

/**
 * Exponha as rotas exigidas pelos testes.
 * Mantém o caminho 200 do /analyze e as validações 400 (HU-Server-Analyze-400).
 */
export function registerRoutes(app: ReturnType<typeof Fastify>) {
  // /healthz deve retornar { status: "ok", timestamp: "<ISO>" }
  app.get('/healthz', async (_req, reply) => {
    const timestamp = new Date().toISOString()
    return reply
      .code(200)
      .type('application/json; charset=utf-8')
      .send({ status: 'ok', timestamp })
  })

  app.post('/analyze', async (req, reply) => {
    // Espera JSON { text: string, maxLen?: number }
    const body = (req.body ?? {}) as any
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

    let limit = 100
    if (maxLen !== undefined) {
      const isInt = Number.isInteger(maxLen)
      if (!isInt || maxLen < 1 || maxLen > 1000) {
        return reply
          .code(400)
          .type('application/json; charset=utf-8')
          .send({ error: 'Bad Request', details: 'Campo "maxLen" deve ser inteiro no intervalo [1..1000].' })
      }
      limit = maxLen
    }

    // === Caminho 200 (inalterado, mas com runId no formato exigido) ===
    const tokensUsed = String(text).split(/\s+/).filter(Boolean).length
    const summary = String(text).slice(0, Math.min(limit, String(text).length))
    const runId = `run-${randomUUID()}` // <— prefixo exigido pelo teste
    const ts = new Date().toISOString()

    // Log estruturado compatível com os testes existentes
    // eslint-disable-next-line no-console
    console.log(JSON.stringify({
      event: 'analyze.200', runId, ts,
      textLen: String(text).length, maxLen: limit,
      summaryLen: summary.length, tokensUsed
    }))

    return reply
      .code(200)
      .type('application/json; charset=utf-8')
      .send({ summary, tokensUsed, runId, ts })
  })

  return app
}

/** Constrói o app e registra as rotas usadas nos testes */
export function build() {
  const app = Fastify({ logger: false })
  registerRoutes(app)
  return app
}

// Execução standalone opcional
if (require.main === module) {
  const app = build()
  const port = Number(process.env.PORT ?? 3000)
  app.listen({ port, host: '0.0.0.0' })
    .then(() => console.log(`[server] listening on :${port}`)) // eslint-disable-line no-console
    .catch((err) => { console.error(err); process.exit(1) })    // eslint-disable-line no-console
}
TS

echo "[ok] index.ts atualizado. Rodando testes do @mini-ide/server…"
pnpm -w --filter @mini-ide/server test

echo "[ok] Checklist (sem CLI global)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "✅ Se tudo verde:"
echo "   git add packages/server/src/index.ts"
echo "   git commit -m \"fix(server): adequa contrato runId (prefixo run-) e /healthz {status,timestamp}\""
echo "   git push -u origin feat/server-analyze-400"
