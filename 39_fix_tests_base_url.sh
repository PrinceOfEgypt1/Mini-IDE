# 39_fix_tests_base_url.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
#
# Objetivo
#   Corrigir os testes do @mini-ide/server para NÃO aceitarem BASE vazia (""), que
#   gerava URLs inválidas como "//healthz" e "//analyze". Passa a validar e normalizar
#   TEST_BASE_URL/BASE_URL, caindo para http://localhost:3000 quando:
#     - variável não definida,
#     - string vazia,
#     - formato sem protocolo http/https.
#
# O script:
#   1) Reescreve packages/server/test/healthz.spec.ts com helper resolveBase().
#   2) Reescreve packages/server/test/analyze.spec.ts com helper resolveBase().
#   3) Roda build + test do pacote server para validar.
#
# Requisitos: pnpm, Node 18+ (fetch nativo) ou 22+, vitest.
# Idempotente: pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV_DIR="$ROOT/packages/server"
TEST_DIR="$SRV_DIR/test"

cd "$ROOT" || { echo "[erro] não encontrei $ROOT"; exit 1; }
test -d "$TEST_DIR" || { echo "[erro] não encontrei $TEST_DIR"; exit 1; }

# Backup uma única vez
for f in healthz.spec.ts analyze.spec.ts; do
  if [ -f "$TEST_DIR/$f" ] && [ ! -f "$TEST_DIR/$f.pre39.bak" ]; then
    cp -f "$TEST_DIR/$f" "$TEST_DIR/$f.pre39.bak"
  fi
done

# Helper TS comum (inline em cada teste para manter arquivos autocontidos)
read -r -d '' COMMON_HELPER <<'TS'
/**
 * Normaliza a BASE a partir de TEST_BASE_URL/BASE_URL.
 * Regras:
 *  - aceita apenas http(s) com host e porta opcional;
 *  - se vier vazia, nula ou sem protocolo → cai no default;
 *  - remove barra final para evitar '//' ao concatenar.
 */
function resolveBase(): string {
  const raw =
    (process.env['TEST_BASE_URL'] && String(process.env['TEST_BASE_URL'])) ||
    (process.env['BASE_URL'] && String(process.env['BASE_URL'])) ||
    'http://localhost:3000';

  // Se for string vazia, invalida (cai no default)
  const candidate = raw.trim().length > 0 ? raw.trim() : 'http://localhost:3000';

  // Deve começar com http/https e conter host
  const ok = /^https?:\/\/[^/]+(:\d+)?(\/.*)?$/i.test(candidate);
  const base = ok ? candidate : 'http://localhost:3000';

  // Remove barra final (se houver) para evitar `//rota`
  return base.endsWith('/') ? base.slice(0, -1) : base;
}
TS

# 1) healthz.spec.ts
cat > "$TEST_DIR/healthz.spec.ts" <<TS
/**
 * Testes do endpoint /healthz com tipagem segura + base URL robusta.
 */
import { describe, it, expect } from 'vitest';

type HealthzResponse = {
  status: 'ok';
  service: string;
  uptime: number;
};

${COMMON_HELPER}

describe('server :: /healthz', () => {
  it('retorna status ok, service e uptime numérico', async () => {
    const BASE = resolveBase();
    const res = await fetch(\`\${BASE}/healthz\`, { method: 'GET' });
    expect(res.ok).toBe(true);

    const bodyUnknown = await res.json();
    const body = bodyUnknown as HealthzResponse;

    expect(body.status).toBe('ok');
    expect(typeof body.service).toBe('string');
    expect(typeof body.uptime).toBe('number');
  });
});
TS

# 2) analyze.spec.ts
cat > "$TEST_DIR/analyze.spec.ts" <<TS
/**
 * Testes do endpoint /analyze com tipagem segura + base URL robusta.
 */
import { describe, it, expect } from 'vitest';

type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

${COMMON_HELPER}

describe('server :: /analyze', () => {
  it('compacta o texto e retorna ok=true', async () => {
    const BASE = resolveBase();
    const payload = {
      input: '  Olá   Mini-IDE!  \\r\\n\\r\\n Demo de   compactação ',
      maxLen: 80,
    };

    const res = await fetch(\`\${BASE}/analyze\`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
    });
    expect(res.ok).toBe(true);

    const bodyUnknown = await res.json();
    const body = bodyUnknown as AnalyzeResponse;

    expect(body.ok).toBe(true);
    expect(typeof body.result).toBe('string');
    expect(typeof body.outputLen).toBe('number');
    expect(body.outputLen).toBe(body.result.length);
  });

  it('respeita o limite maxLen (quando fornecido)', async () => {
    const BASE = resolveBase();
    const payload = {
      input: 'Linha  1   com   espaços\\r\\n\\r\\n   Linha  2\\ttabs',
      maxLen: 32,
    };

    const res = await fetch(\`\${BASE}/analyze\`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
    });
    expect(res.ok).toBe(true);

    const bodyUnknown = await res.json();
    const body = bodyUnknown as AnalyzeResponse;

    expect(body.ok).toBe(true);
    expect(typeof body.result).toBe('string');
    expect(body.result.length).toBeLessThanOrEqual(payload.maxLen);
  });
});
TS

echo "[info] validando @mini-ide/server (build/test)…"
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: testes do server corrigidos (BASE robusta) =="
echo "Dica:"
echo "  # Se quiser forçar outro host/porta em CI:"
echo "  TEST_BASE_URL='http://127.0.0.1:3100' pnpm -F @mini-ide/server test"
