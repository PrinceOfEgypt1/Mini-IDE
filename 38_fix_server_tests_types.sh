# 38_fix_server_tests_types.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
#
# Propósito:
#   Corrigir os erros de lint nos testes do @mini-ide/server
#   (@typescript-eslint/no-unsafe-member-access / no-unsafe-call) tipando
#   explicitamente as respostas de /healthz e /analyze.
#
# O que faz:
#   1) Reescreve packages/server/test/healthz.spec.ts com tipos seguros.
#   2) Reescreve packages/server/test/analyze.spec.ts com tipos seguros.
#   3) Roda build + lint + test do pacote server para validar.
#
# Seguro para rodar várias vezes (idempotente). Cria backups *.bak uma única vez.
# Requisitos: Node 22+, pnpm, vitest/eslint já instalados no repo.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV_DIR="$ROOT/packages/server"
TEST_DIR="$SRV_DIR/test"

cd "$ROOT" || { echo "[erro] raiz do projeto não encontrada: $ROOT"; exit 1; }
test -d "$TEST_DIR" || { echo "[erro] diretório de testes não encontrado: $TEST_DIR"; exit 1; }

# Backups (primeira execução)
for f in "healthz.spec.ts" "analyze.spec.ts"; do
  [ -f "$TEST_DIR/$f" ] || { echo "[erro] arquivo não encontrado: $TEST_DIR/$f"; exit 1; }
  if [ ! -f "$TEST_DIR/$f.bak" ]; then
    cp -f "$TEST_DIR/$f" "$TEST_DIR/$f.bak"
  fi
done

# 1) Reescreve healthz.spec.ts com tipos seguros
cat > "$TEST_DIR/healthz.spec.ts" <<'TS'
/**
 * Testes do endpoint /healthz com tipagem segura.
 * Evita uso de `any` para satisfazer eslint (@typescript-eslint/*).
 */
import { describe, it, expect } from 'vitest';

type HealthzResponse = {
  status: 'ok';
  service: string;
  uptime: number;
};

const BASE =
  process.env['TEST_BASE_URL'] ??
  process.env['BASE_URL'] ??
  'http://localhost:3000';

describe('server :: /healthz', () => {
  it('retorna status ok, service e uptime numérico', async () => {
    const res = await fetch(`${BASE}/healthz`, { method: 'GET' });
    expect(res.ok).toBe(true);

    const bodyUnknown = await res.json();
    // Converte de unknown → HealthzResponse (sem permitir any nas asserções)
    const body = bodyUnknown as HealthzResponse;

    expect(body.status).toBe('ok');
    expect(typeof body.service).toBe('string');
    expect(typeof body.uptime).toBe('number');
  });
});
TS

# 2) Reescreve analyze.spec.ts com tipos seguros
cat > "$TEST_DIR/analyze.spec.ts" <<'TS'
/**
 * Testes do endpoint /analyze com tipagem segura.
 * Evita uso de `any` (member-access/call) e valida shape esperado.
 */
import { describe, it, expect } from 'vitest';

type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

const BASE =
  process.env['TEST_BASE_URL'] ??
  process.env['BASE_URL'] ??
  'http://localhost:3000';

describe('server :: /analyze', () => {
  it('compacta o texto e retorna ok=true', async () => {
    const payload = {
      input: '  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ',
      maxLen: 80,
    };

    const res = await fetch(`${BASE}/analyze`, {
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
    const payload = {
      input: 'Linha  1   com   espaços\r\n\r\n   Linha  2\ttabs',
      maxLen: 32,
    };

    const res = await fetch(`${BASE}/analyze`, {
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

# 3) Validação rápida do pacote server
echo "[info] validando @mini-ide/server (build/lint/test)…"
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run lint
pnpm -F @mini-ide/server run test

echo "== OK :: testes do server tipados e lint resolvido =="
echo "Se desejar commit:"
echo "  git add -A && git commit -m \"test(server): tipagem segura para respostas /healthz e /analyze\""
