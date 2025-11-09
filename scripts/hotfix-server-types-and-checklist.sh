#!/usr/bin/env bash
# scripts/hotfix-server-types-and-checklist.sh
set -euo pipefail

# 0) Arquivos-alvo
SRV_INDEX="packages/server/src/index.ts"
CHECKLIST="./42_pipeline_checklist.sh"

[[ -f "$SRV_INDEX" ]] || { echo "[erro] não achei $SRV_INDEX"; exit 1; }

# 1) Backup de segurança
cp -f "$SRV_INDEX" "${SRV_INDEX}.bak.types_$(date +%Y%m%d-%H%M%S)"
[[ -f "$CHECKLIST" ]] && cp -f "$CHECKLIST" "${CHECKLIST}.bak.grep_$(date +%Y%m%d-%H%M%S)" || true

# 2) Reescreve index.ts com tipagem forte + contrato preservado
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

      let limit = 100
      if (maxLen !== undefined) {
        const n = typeof maxLen === 'number' ? maxLen : Number(maxLen)
        const isInt = Number.isInteger(n)
        if (!isInt || n < 1 || n > 1000) {
          return reply
            .code(400)
            .type('application/json; charset=utf-8')
            .send({ error: 'Bad Request', details: 'Campo "maxLen" deve ser inteiro no intervalo [1..1000].' })
        }
        limit = n
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
  const port = Number((process.env as Record<string, string | undefined>)['PORT'] ?? 3000) // TS4111-safe
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

echo "[ok] server/index.ts reescrito com tipos."

# 3) (Opcional) Blindar guard do bloco 9) Resumo no checklist
if [[ -f "$CHECKLIST" ]]; then
  # Substitui qualquer grep -c com regex contendo parênteses por match exato -xF
  sed -i \
    "s|grep -c \"^# ---------- 9\\) Resumo ----------\\$\"|grep -xF -c '# ---------- 9) Resumo ----------'|g" \
    "$CHECKLIST" || true

  # Em caso de outra variante, força um guard único canônico (não é invasivo)
  if grep -nq "9) Resumo" "$CHECKLIST"; then
    # Garante que nenhuma contagem pegue substrings
    sed -i \
      "s|grep -cF '# ---------- 9) Resumo ----------'|grep -xF -c '# ---------- 9) Resumo ----------'|g" \
      "$CHECKLIST" || true
  fi
  echo "[ok] checklist (9) Resumo blindado (grep -xF)."
fi

# 4) Build + tests do pacote server
echo "[info] Rodando build e testes do @mini-ide/server…"
pnpm -w --filter @mini-ide/server build
pnpm -w --filter @mini-ide/server test

# 5) Checklist geral (sem CLI global) – só informativo
echo "[info] Checklist geral…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo
echo "✅ Pronto. Se tudo ok:"
echo "   git add $SRV_INDEX ${CHECKLIST:-} || true"
echo "   git commit -m \"fix(server): tipagem forte em rotas, acesso PORT seguro e guard do Resumo estável\""
echo "   git push -u origin feat/server-analyze-400"
