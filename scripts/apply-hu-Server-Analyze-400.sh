#!/usr/bin/env bash
# apply-hu-Server-Analyze-400.sh
# Embute os códigos da HU-Server-Analyze-400 (validações + respostas 400) direto no repo.
# Uso: bash apply-hu-Server-Analyze-400.sh
set -euo pipefail

# 0) Verificações rápidas
git rev-parse --git-dir >/dev/null 2>&1 || { echo "[erro] Não é um repositório Git."; exit 1; }
[[ -f pnpm-workspace.yaml ]] || { echo "[erro] Rode na RAIZ do monorepo (pnpm-workspace.yaml não encontrado)."; exit 1; }
[[ -d packages/server/src && -d packages/server/test ]] || { echo "[erro] Estrutura esperada em packages/server não encontrada."; exit 1; }

# 1) Preparar branch
BASE_BRANCH="main"
FEATURE_BRANCH="feat/server-analyze-400"
echo "[info] Atualizando $BASE_BRANCH e criando/switch para $FEATURE_BRANCH…"
git fetch --all --prune >/dev/null 2>&1 || true
git checkout "$BASE_BRANCH"
git pull --ff-only || true
if git rev-parse --verify "$FEATURE_BRANCH" >/dev/null 2>&1; then
  git checkout "$FEATURE_BRANCH"
  git rebase "$BASE_BRANCH" || { echo "[warn] Rebase falhou; tentando merge..."; git merge --no-edit "$BASE_BRANCH"; }
else
  git checkout -b "$FEATURE_BRANCH"
fi

# 2) Escrever arquivo de testes (packages/server/test/analyze-400.spec.ts)
TEST_PATH="packages/server/test/analyze-400.spec.ts"
cat > "$TEST_PATH" <<'TS'
// packages/server/test/analyze-400.spec.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { build } from '../src/index'

let app: ReturnType<typeof build>

beforeAll(async () => {
  app = build()
  await app.ready()
})

afterAll(async () => {
  await app.close()
})

describe('HU-Server-Analyze-400 - validações e respostas 400', () => {
  it('AC1: text ausente -> 400', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload: {} // sem text
    })
    expect(res.statusCode).toBe(400)
    const body = res.json() as any
    expect(body).toMatchObject({ error: 'Bad Request' })
    expect(typeof body.details).toBe('string')
  })

  it('AC2: text vazio/whitespace -> 400', async () => {
    const samples = ['', '   ', '\n\t ']
    for (const s of samples) {
      const res = await app.inject({
        method: 'POST',
        url: '/analyze',
        payload: { text: s }
      })
      expect(res.statusCode).toBe(400)
      const body = res.json() as any
      expect(body).toMatchObject({ error: 'Bad Request' })
    }
  })

  it('AC3: text não-string -> 400 (number/array/obj/bool/null)', async () => {
    const invalids = [123, true, false, null, { a: 1 }, [1,2,3]]
    for (const v of invalids) {
      const res = await app.inject({
        method: 'POST',
        url: '/analyze',
        payload: { text: v as any }
      })
      expect(res.statusCode).toBe(400)
      const body = res.json() as any
      expect(body).toMatchObject({ error: 'Bad Request' })
    }
  })

  it('AC4: maxLen inválido (<1, >1000, não-inteiro, tipo errado) -> 400', async () => {
    const invalids = [0, -1, 1001, 1.5, '10', true, null, {}, []]
    for (const v of invalids) {
      const res = await app.inject({
        method: 'POST',
        url: '/analyze',
        payload: { text: 'ok', maxLen: v as any }
      })
      expect(res.statusCode).toBe(400)
      const body = res.json() as any
      expect(body).toMatchObject({ error: 'Bad Request' })
    }
  })

  it('AC5: 400 sempre com shape padronizado e content-type', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload: { maxLen: 10 } // text ausente
    })
    expect(res.statusCode).toBe(400)
    expect(res.headers['content-type']?.toLowerCase()).toContain('application/json')
    const body = res.json() as any
    expect(Object.keys(body).sort()).toEqual(['details','error'].sort())
  })

  it('Happy path 200 segue intacto', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/analyze',
      payload: { text: 'hello world from tests', maxLen: 5 }
    })
    expect(res.statusCode).toBe(200)
    const body = res.json() as any
    expect(typeof body.summary).toBe('string')
    expect(body.summary.length).toBe(5)
    expect(typeof body.tokensUsed).toBe('number')
    expect(typeof body.runId).toBe('string')
    expect(typeof body.ts).toBe('string')
  })
})
TS
echo "[ok] Teste criado: $TEST_PATH"

# 3) Substituir o handler com validações 400 (backup do anterior)
INDEX_PATH="packages/server/src/index.ts"
if [[ -f "$INDEX_PATH" ]]; then
  cp -f "$INDEX_PATH" "${INDEX_PATH}.bak"
  echo "[info] Backup do index.ts em ${INDEX_PATH}.bak"
fi

cat > "$INDEX_PATH" <<'TS'
// packages/server/src/index.ts
import Fastify from 'fastify'

// Node 18+ tem crypto.randomUUID nativo
import { randomUUID } from 'crypto'

export function build() {
  const app = Fastify({ logger: false })

  app.get('/healthz', async (_req, reply) => {
    return reply.code(200).send({ ok: true })
  })

  app.post('/analyze', async (req, reply) => {
    // Expect: JSON { text: string, maxLen?: number }
    const body = (req.body ?? {}) as any
    const { text, maxLen } = body

    // --- Validações 400 (HU-Server-Analyze-400) ---
    // text: obrigatório, string, trim >= 1
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

    // maxLen: opcional, inteiro em [1..1000]
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

    // --- Caminho 200 (mantido intacto) ---
    const tokensUsed = text.split(/\s+/).filter(Boolean).length
    const summary = text.slice(0, Math.min(limit, text.length))
    const runId = randomUUID()
    const ts = new Date().toISOString()

    // Log estruturado (mantém contrato dos testes anteriores)
    // (Logs usados nos testes existentes são apenas stdout; manter chave "analyze.200" ajuda)
    // eslint-disable-next-line no-console
    console.log(JSON.stringify({ event: 'analyze.200', runId, ts, textLen: text.length, maxLen: limit, summaryLen: summary.length, tokensUsed }))

    return reply
      .code(200)
      .type('application/json; charset=utf-8')
      .send({ summary, tokensUsed, runId, ts })
  })

  return app
}

// Permite executar standalone se for chamado diretamente
if (require.main === module) {
  const app = build()
  const port = Number(process.env.PORT ?? 3000)
  app.listen({ port, host: '0.0.0.0' })
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
echo "[ok] Handler atualizado: $INDEX_PATH"

# 4) Testes + checklist
echo "[info] Rodando testes do server (vitest)…"
pnpm -w --filter @mini-ide/server test

echo "[info] Rodando checklist sem CLI global…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh

# 5) Commit + push
git add "$TEST_PATH" "$INDEX_PATH"
if ! git diff --cached --quiet; then
  git commit -m "feat(server): HU-Server-Analyze-400 — validações e respostas 400 (AC1..AC5) + mantém caminho 200"
  git push -u origin "$FEATURE_BRANCH"
  echo "[ok] Branch enviada: $FEATURE_BRANCH"
else
  echo "[info] Sem mudanças a commitar (já está aplicado)."
fi

# 6) URL para criar PR
ORIGIN_URL="$(git remote get-url origin)"
PR_URL="$(echo "$ORIGIN_URL" | sed 's#^git@github\.com:#https://github.com/#; s#\.git$##')/compare/${BASE_BRANCH}...${FEATURE_BRANCH}?expand=1"
echo "--------------------------------------------"
echo "[ok] Tudo pronto. Abra o PR:"
echo "  $PR_URL"
echo "--------------------------------------------"
