# 20_enable_cors_fastify.sh
# -------------------------------------------------------------------------------------------------
# Mini-IDE • Habilitar CORS no Fastify com melhores práticas + TSDoc
# Execução: rodar ESTE script no diretório raiz do projeto:  ~/workspace/Mini-IDE
# Idempotente: pode ser executado mais de uma vez sem efeito colateral.
# -------------------------------------------------------------------------------------------------
# O que faz:
#  1) Adiciona a dependência @fastify/cors no pacote @mini-ide/server (se ainda não existir)
#  2) Sobrescreve server/src/index.ts com versão padronizada, documentada (TSDoc) e com CORS habilitado
#  3) Mantém a rota /healthz e a rota /analyze (usando compactPrompt do analysis-agent)
#  4) Compila e executa testes do pacote server para validar
# -------------------------------------------------------------------------------------------------
# Observações:
#  - CORS configurado para aceitar requisições a partir de http://localhost:5173 (Vite/React dev)
#  - Ajuste a lista "origin" abaixo conforme necessário para produção
# -------------------------------------------------------------------------------------------------

set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"

echo "== MINI-IDE :: 20_enable_cors_fastify =="

# 1) Garantir dependência do CORS no pacote server
pnpm -F @mini-ide/server add @fastify/cors >/dev/null

# 2) Reescrever server/src/index.ts com CORS e TSDoc
cat > "$SRV/src/index.ts" <<'EOF'
/**
 * @module Server
 * @description
 * Servidor HTTP do Mini-IDE baseado em Fastify, com:
 *  - Healthcheck (`GET /healthz`)
 *  - Endpoint de análise de prompt (`POST /analyze`) usando `compactPrompt`
 *  - CORS habilitado para origens confiáveis (por padrão, `http://localhost:5173`)
 *
 * Boas práticas aplicadas:
 *  - Tipagem estrita (TS) e TSDoc para geração de documentação automática
 *  - Inicialização encapsulada em `buildServer()` para facilitar testes/e2e
 *  - Execução condicional quando o arquivo é rodado diretamente (CLI/dev)
 */

import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { compactPrompt } from '@mini-ide/analysis-agent';
import { checkPortFree } from './portGuard';

/**
 * Constrói e configura uma instância do servidor Fastify.
 *
 * @remarks
 * - CORS é registrado com origem restrita para `http://localhost:5173` por padrão.
 * - Ajuste a lista `origin` conforme ambientes (dev/stage/prod).
 *
 * @returns {FastifyInstance} Instância configurada do Fastify
 */
export function buildServer(): FastifyInstance {
  const app = Fastify({ logger: false });

  // --- CORS ---
  // Restrinja as origens confiáveis. Em produção, evite `origin: true` ou `*`.
  app.register(cors, {
    origin: ['http://localhost:5173'],
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false,
    maxAge: 86_400, // 24h (em segundos)
  });

  // --- Healthcheck ---
  app.get('/healthz', async () => {
    return { status: 'ok', service: 'mini-ide-server', uptime: process.uptime() };
  });

  // --- Analyze ---
  /**
   * Analisa/compacta um prompt de entrada, normalizando espaços/linhas e aplicando um limite opcional.
   * @route POST /analyze
   * @bodyParam input {string} Texto de entrada (prompt) a ser compactado.
   * @bodyParam maxLen {number} [opcional] Tamanho máximo do resultado; corta e acrescenta " …".
   * @returns Objeto com `ok`, `inputLen`, `outputLen` e `result`.
   */
  app.post('/analyze', async (request) => {
    const body = (request.body ?? {}) as { input?: string; maxLen?: number };
    const input = typeof body.input === 'string' ? body.input : '';
    const maxLen = typeof body.maxLen === 'number' ? body.maxLen : undefined;

    const result = compactPrompt(input, { maxLen });
    return {
      ok: true,
      inputLen: input.length,
      outputLen: result.length,
      result,
    };
  });

  return app;
}

// Executa o servidor somente quando o arquivo é chamado diretamente (ex.: pnpm -F @mini-ide/server run dev)
if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    const app = buildServer();
    const port = Number(process.env['PORT'] ?? 3000);

    const free = await checkPortFree(port);
    if (!free) {
      console.error(`[mini-ide] porta ${port} já está em uso. Defina PORT para outra porta.`);
      process.exit(1);
    }

    await app.listen({ port, host: '0.0.0.0' });
    console.log(`[mini-ide] server running on http://localhost:${port}`);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
EOF
echo "[ok] server/src/index.ts atualizado com CORS + TSDoc"

# 3) Build + Test do pacote server
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: CORS habilitado e validado com build+test =="
echo "Subir em dev: pnpm -F @mini-ide/server run dev"
echo "Frontend padrão (Vite): http://localhost:5173 (origem liberada)"
