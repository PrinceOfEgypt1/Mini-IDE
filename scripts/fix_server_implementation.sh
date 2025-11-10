#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: fix_server_implementation.sh
# Objetivo: Reimplementar servidor com lógica completa que os testes esperam
# ==============================================================================

echo "[info] Reimplementando servidor com lógica completa"

# ==============================================================================
# Backup do arquivo atual
# ==============================================================================
if [ -f packages/server/src/index.ts ]; then
  cp packages/server/src/index.ts packages/server/src/index.ts.backup_$(date +%Y%m%d_%H%M%S)
  echo "[ok] Backup criado"
fi

# ==============================================================================
# Reimplementar packages/server/src/index.ts com TODA a lógica
# ==============================================================================
cat > packages/server/src/index.ts << 'EOF'
import Fastify, { type FastifyInstance, type FastifyRequest, type FastifyReply } from 'fastify';
import { randomUUID } from 'node:crypto';

/**
 * Interface para o body do POST /analyze
 */
interface AnalyzeBody {
  text: string;
  maxLen?: number;
}

/**
 * Valida e normaliza o body do /analyze
 */
function validateAnalyzeBody(body: unknown): { valid: true; data: { text: string; maxLen: number } } | { valid: false; error: string } {
  // Verificar se body existe
  if (!body || typeof body !== 'object') {
    return { valid: false, error: 'Request body must be a JSON object' };
  }

  const reqBody = body as Partial<AnalyzeBody>;

  // Validar text
  if (reqBody.text === undefined || reqBody.text === null) {
    return { valid: false, error: 'Missing required field: text' };
  }

  if (typeof reqBody.text !== 'string') {
    return { valid: false, error: 'Field "text" must be a string' };
  }

  if (reqBody.text.trim() === '') {
    return { valid: false, error: 'Field "text" cannot be empty' };
  }

  // Validar maxLen
  let maxLen = 100; // default
  if (reqBody.maxLen !== undefined) {
    if (typeof reqBody.maxLen !== 'number') {
      return { valid: false, error: 'Field "maxLen" must be a number' };
    }
    if (reqBody.maxLen <= 0) {
      return { valid: false, error: 'Field "maxLen" must be greater than 0' };
    }
    maxLen = reqBody.maxLen;
  }

  return { valid: true, data: { text: reqBody.text, maxLen } };
}

/**
 * Função simples para contar tokens (espaços)
 */
function countTokens(text: string): number {
  return text.trim().split(/\s+/).length;
}

/**
 * Configura as rotas do servidor
 */
export async function createServer(app: FastifyInstance): Promise<void> {
  // GET /healthz
  app.get('/healthz', async (_request: FastifyRequest, reply: FastifyReply) => {
    return reply.status(200).send({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  });

  // POST /analyze
  app.post('/analyze', async (request: FastifyRequest, reply: FastifyReply) => {
    const validation = validateAnalyzeBody(request.body);

    if (!validation.valid) {
      return reply.status(400).send({
        error: validation.error,
      });
    }

    const { text, maxLen } = validation.data;
    const tokensUsed = countTokens(text);
    const runId = `run-${randomUUID()}`;
    const timestamp = new Date().toISOString();

    // Truncar texto se necessário
    let summary = text;
    if (text.length > maxLen) {
      summary = text.substring(0, maxLen);
    }

    // Log estruturado
    console.log(JSON.stringify({
      event: 'analyze.200',
      runId,
      ts: timestamp,
      textLen: text.length,
      maxLen,
      summaryLen: summary.length,
      tokensUsed,
    }));

    return reply.status(200).send({
      summary,
      tokensUsed,
      runId,
      timestamp,
    });
  });
}

/**
 * Inicia o servidor (para execução standalone)
 */
async function main(): Promise<void> {
  const app = Fastify({
    logger: {
      level: 'info',
      transport: {
        target: 'pino-pretty',
        options: {
          translateTime: 'HH:MM:ss Z',
          ignore: 'pid,hostname',
        },
      },
    },
  });

  await createServer(app);

  const port = Number(process.env.PORT) || 3200;
  const host = process.env.HOST || '0.0.0.0';

  try {
    await app.listen({ port, host });
    console.log(`[ok] Server listening on ${host}:${port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
}

// Executar se for o módulo principal
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error('[fail]', err);
    process.exit(1);
  });
}
EOF

echo "[ok] Servidor reimplementado com lógica completa"

# ==============================================================================
# Validar
# ==============================================================================
echo ""
echo "[info] Validando implementação..."

echo "[info] 1/4: Typecheck..."
if pnpm -C packages/server run typecheck 2>&1 | tee /tmp/typecheck.log; then
  echo "[ok] Typecheck passou"
else
  echo "[fail] Typecheck falhou"
  cat /tmp/typecheck.log
  exit 1
fi

echo "[info] 2/4: Build..."
if pnpm -C packages/server run build; then
  echo "[ok] Build passou"
else
  echo "[fail] Build falhou"
  exit 1
fi

echo "[info] 3/4: Testes..."
if pnpm -C packages/server run test 2>&1 | tee /tmp/tests.log; then
  echo "[ok] Todos os testes passaram!"
else
  echo "[fail] Alguns testes falharam"
  echo ""
  echo "[info] Resumo dos testes:"
  grep -E "(FAIL|✓|Test Files)" /tmp/tests.log || true
  exit 1
fi

echo "[info] 4/4: Checklist completo..."
if REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh 2>&1 | tail -20; then
  echo "[ok] Checklist passou!"
else
  echo "[warn] Checklist teve problemas (mas testes passaram)"
fi

echo ""
echo "[ok] =========================================="
echo "[ok] SERVIDOR REIMPLEMENTADO ✅"
echo "[ok] =========================================="
echo "[ok] ✓ Lógica completa implementada"
echo "[ok] ✓ Validações robustas"
echo "[ok] ✓ maxLen funcionando"
echo "[ok] ✓ Campos obrigatórios presentes"
echo "[ok] ✓ Mensagens de erro específicas"
echo "[ok] ✓ Typecheck OK"
echo "[ok] ✓ Build OK"
echo "[ok] ✓ Testes OK"
echo ""
echo "[info] Commitar mudanças:"
echo "  git add packages/server/src/index.ts packages/server/test/"
echo "  git commit -m 'fix(server): reimplementar lógica completa após merge'"
echo "  git push"
echo ""
