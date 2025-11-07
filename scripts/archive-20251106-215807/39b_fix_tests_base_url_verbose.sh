# 39b_fix_tests_base_url_verbose.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (RAIZ do projeto)
#
# Objetivo:
#   Regravar os testes de @mini-ide/server com resolução robusta da BASE (TEST_BASE_URL/BASE_URL)
#   evitando URLs "//healthz" e "//analyze". Rodar build+test e mostrar saída detalhada.
#
# Por que seu script anterior “não executou”?
#   - Possível CRLF no arquivo (quebra o bash em WSL).
#   - Silêncio por falta de echos/erros. Aqui habilitamos modo verboso e normalizamos finais de linha.
#
# O que esse script faz:
#   1) Confere diretórios, mostra contexto e ativa modo verboso (-x).
#   2) Normaliza finais de linha para LF (dos .sh e dos testes).
#   3) Reescreve tests/healthz.spec.ts e tests/analyze.spec.ts com helper resolveBase().
#   4) Faz build + test apenas do pacote server, exibindo logs.
#
# Idempotente. Pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV_DIR="$ROOT/packages/server"
TEST_DIR="$SRV_DIR/test"

echo "== 39b :: START =="
echo "[ctx] ROOT=$ROOT"
echo "[ctx] SRV_DIR=$SRV_DIR"
echo "[ctx] TEST_DIR=$TEST_DIR"

# 1) Sanidade de caminhos
if [ ! -d "$ROOT" ]; then
  echo "[erro] Raiz não encontrada: $ROOT"; exit 1
fi
if [ ! -d "$SRV_DIR" ] || [ ! -d "$TEST_DIR" ]; then
  echo "[erro] Diretórios do server/test não encontrados: $SRV_DIR | $TEST_DIR"; exit 1
fi

# 2) Normaliza finais de linha (previne CRLF silencioso)
echo "[info] Normalizando finais de linha (LF) em scripts e testes…"
# normaliza todos os .sh da raiz (opcional) e os testes do server
find "$ROOT" -maxdepth 1 -name "*.sh" -print0 | xargs -0 -I {} bash -lc 'sed -i "s/\r$//" "{}"'
find "$TEST_DIR" -maxdepth 1 -name "*.ts" -print0 | xargs -0 -I {} bash -lc 'sed -i "s/\r$//" "{}"'

# 3) Helper TS comum (inline)
COMMON_HELPER_TS='/**
 * resolveBase(): normaliza a BASE a partir de TEST_BASE_URL/BASE_URL.
 * Regras:
 *  - aceita apenas http(s) com host e porta opcional;
 *  - se vier vazia, nula ou sem protocolo → cai no default;
 *  - remove barra final para evitar `//rota`.
 */
function resolveBase(): string {
  const raw =
    (process.env["TEST_BASE_URL"] && String(process.env["TEST_BASE_URL"])) ||
    (process.env["BASE_URL"] && String(process.env["BASE_URL"])) ||
    "http://localhost:3000";

  const candidate = raw.trim().length > 0 ? raw.trim() : "http://localhost:3000";
  const ok = /^https?:\/\/[^/]+(:\d+)?(\/.*)?$/i.test(candidate);
  const base = ok ? candidate : "http://localhost:3000";
  return base.endsWith("/") ? base.slice(0, -1) : base;
}'

# 4) Reescreve healthz.spec.ts
echo "[info] Reescrevendo healthz.spec.ts…"
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

${COMMON_HELPER_TS}

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

# 5) Reescreve analyze.spec.ts
echo "[info] Reescrevendo analyze.spec.ts…"
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

${COMMON_HELPER_TS}

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

# 6) Mostra diff rápido (opcional)
echo "[info] Prévia (primeiras linhas) dos testes reescritos:"
head -n 8 "$TEST_DIR/healthz.spec.ts" || true
head -n 8 "$TEST_DIR/analyze.spec.ts" || true

# 7) Build + Test do pacote server (modo verboso)
echo "[info] Rodando build do @mini-ide/server…"
pnpm -F @mini-ide/server run build
echo "[info] Rodando testes do @mini-ide/server…"
pnpm -F @mini-ide/server run test

echo "== 39b :: OK — testes do server corrigidos e executados com sucesso =="
echo "Dica: para CI usar outra porta/host: TEST_BASE_URL='http://127.0.0.1:3100' pnpm -F @mini-ide/server test"
