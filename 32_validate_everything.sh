# 32_validate_everything.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Validar, ponta a ponta, o monorepo Mini-IDE:
#       1) Ambiente (node/pnpm), estrutura e binário do CLI
#       2) Install → Build → Typecheck → Lint → Test de todos os pacotes
#       3) Geração das docs (TypeDoc) e verificação de artefato
#       4) Subir o Server em porta livre (3100 por padrão), checar /healthz
#       5) Exercitar o endpoint /analyze via curl + validar JSON (com jq, se disponível)
#       6) Exercitar o CLI `mini-ide analyze` e validar saída em bundles/v1.0.12
#       7) Relatório final e códigos de saída consistentes
#   - Idempotente e verboso, com traps para limpeza do server temporário.
# Requisitos:
#   - Node 22+, pnpm; jq é opcional (melhora as validações de JSON).
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
BUND="$ROOT/bundles/v1.0.12"
SRV_DIR="$ROOT/packages/server"
CLI_PKG="@mini-ide/cli"
PORT_DEFAULT=3100
PORT="${PORT:-$PORT_DEFAULT}"

echo "== MINI-IDE :: 32_validate_everything =="

# 0) Checagens básicas de diretório e ferramentas
cd "$ROOT" || { echo "[erro] não encontrei o diretório do projeto: $ROOT"; exit 1; }
command -v node >/dev/null || { echo "[erro] Node não encontrado no PATH"; exit 1; }
command -v pnpm >/dev/null || { echo "[erro] pnpm não encontrado no PATH"; exit 1; }
echo "[info] Node: $(node -v) | PNPM: $(pnpm -v)"
mkdir -p "$BUND"

# 1) Estrutura mínima esperada
for path in "packages/shared" "packages/analysis-agent" "packages/server" "packages/ui" "packages/cli"; do
  test -d "$ROOT/$path" || { echo "[erro] pasta exigida não encontrada: $path"; exit 1; }
done
echo "[ok] estrutura básica encontrada"

# 2) Garantir dependências (rápido com lockfile)
echo "-- install --"
pnpm install --frozen-lockfile
echo "[ok] install"

# 3) Pipeline: Build / Typecheck / Lint / Test (todos os pacotes)
echo "-- build --";      pnpm -r run build
echo "-- typecheck --";  pnpm -r run typecheck
echo "-- lint --";       pnpm -r run lint
echo "-- test --";       pnpm -r run test
echo "[ok] pipeline básica passou em todos os pacotes"

# 4) Geração de documentação (TypeDoc) e verificação do artefato principal
echo "-- docs --"
pnpm run docs
DOC_MAIN="$ROOT/docs/api/index.html"
if [ -f "$DOC_MAIN" ]; then
  echo "[ok] docs geradas: $DOC_MAIN"
else
  echo "[erro] documentação não gerada em $DOC_MAIN"; exit 1
fi

# 5) Subir server temporário se não houver um em 3000/PORT
#    - Se já houver em :3000, usa; senão tenta :$PORT
USE_PORT="$PORT"
if curl -sf "http://localhost:3000/healthz" >/dev/null 2>&1; then
  echo "[info] server detectado em :3000 — usarei essa instância"
  USE_PORT=3000
else
  if curl -sf "http://localhost:$PORT/healthz" >/dev/null 2>&1; then
    echo "[info] server detectado em :$PORT — usarei essa instância"
  else
    echo "[info] subindo server temporário em :$PORT…"
    ( cd "$SRV_DIR" && PORT="$PORT" pnpm run dev ) >/tmp/mini-ide-server.log 2>&1 &
    SRV_PID=$!
    cleanup() {
      if ps -p "${SRV_PID:-0}" >/dev/null 2>&1; then
        echo "[info] encerrando server temporário (pid=$SRV_PID)…"
        kill "$SRV_PID" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup EXIT

    # Aguardar pronto
    for i in $(seq 1 40); do
      if curl -sf "http://localhost:$PORT/healthz" >/dev/null 2>&1; then
        echo "[ok] server temporário pronto em :$PORT"
        break
      fi
      sleep 0.5
      if ! ps -p "${SRV_PID:-0}" >/dev/null 2>&1; then
        echo "[erro] server saiu prematuramente. Veja /tmp/mini-ide-server.log"
        exit 1
      fi
      if [ "$i" -eq 40 ]; then
        echo "[erro] timeout ao subir server temporário. Veja /tmp/mini-ide-server.log"
        exit 1
      fi
    done
  fi
fi

BASE_URL="http://localhost:$USE_PORT"

# 6) Valida /healthz (conteúdo esperado)
echo "-- validar /healthz --"
HZ="$(curl -sf "$BASE_URL/healthz" || true)"
if [ -z "$HZ" ]; then
  echo "[erro] /healthz não respondeu"; exit 1
fi
if command -v jq >/dev/null 2>&1; then
  STATUS="$(printf '%s' "$HZ" | jq -r '.status // empty')"
  SERVICE="$(printf '%s' "$HZ" | jq -r '.service // empty')"
  test "$STATUS" = "ok" && test "$SERVICE" = "mini-ide-server" || {
    echo "[erro] /healthz JSON inesperado: $HZ"; exit 1;
  }
else
  echo "$HZ" | grep -q '"status":"ok"' || { echo "[erro] /healthz sem status ok: $HZ"; exit 1; }
  echo "$HZ" | grep -q '"service":"mini-ide-server"' || { echo "[erro] /healthz sem service mini-ide-server: $HZ"; exit 1; }
fi
echo "[ok] /healthz válido"

# 7) Exercitar /analyze via curl e validar o JSON
echo "-- validar /analyze --"
AN_RES="$(curl -sf -X POST "$BASE_URL/analyze" -H 'content-type: application/json' \
  -d '{"input":"  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ","maxLen":60}' || true)"
if [ -z "$AN_RES" ]; then
  echo "[erro] /analyze não respondeu"; exit 1
fi
if command -v jq >/dev/null 2>&1; then
  OK="$(printf '%s' "$AN_RES" | jq -r '.ok // false')"
  OUTLEN="$(printf '%s' "$AN_RES" | jq -r '.outputLen // -1')"
  RESULT="$(printf '%s' "$AN_RES" | jq -r '.result // empty')"
  test "$OK" = "true" || { echo "[erro] /analyze ok=false: $AN_RES"; exit 1; }
  test "$OUTLEN" -ge 1 || { echo "[erro] /analyze outputLen inválido: $AN_RES"; exit 1; }
  test -n "$RESULT" || { echo "[erro] /analyze result vazio: $AN_RES"; exit 1; }
else
  echo "$AN_RES" | grep -q '"ok":true' || { echo "[erro] /analyze sem ok=true: $AN_RES"; exit 1; }
  echo "$AN_RES" | grep -Eq '"outputLen":[1-9][0-9]*' || { echo "[erro] /analyze sem outputLen válido: $AN_RES"; exit 1; }
  echo "$AN_RES" | grep -q '"result":"' || { echo "[erro] /analyze sem result"; exit 1; }
fi
echo "[ok] /analyze válido"

# 8) Exercitar CLI (mini-ide analyze) e validar artefato salvo
echo "-- validar CLI (mini-ide analyze) --"
if ! command -v mini-ide >/dev/null 2>&1; then
  echo "[info] binário global não encontrado; tentando linkar…"
  pnpm link --global "$CLI_PKG" >/dev/null
fi

mini-ide analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 60 --url "$BASE_URL"

LAST="$(ls -1t "$BUND"/analysis-*.json 2>/dev/null | head -n1 || true)"
if [ -z "${LAST:-}" ]; then
  echo "[erro] o CLI não gerou arquivo em $BUND"; exit 1
fi
echo "[ok] arquivo gerado pelo CLI: $LAST"

# Validação rápida do JSON gerado
if command -v jq >/dev/null 2>&1; then
  JOK="$(jq -r '.response.ok // false' "$LAST")"
  test "$JOK" = "true" || { echo "[erro] arquivo do CLI não contém ok=true"; exit 1; }
fi

# 9) Relatório final
echo "----------------------------------------"
echo "VALIDAÇÃO GERAL: SUCESSO ✅"
echo "Server base: $BASE_URL"
echo "Docs:        $DOC_MAIN"
echo "CLI output:  $LAST"
echo "----------------------------------------"
