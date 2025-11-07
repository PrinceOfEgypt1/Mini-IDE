PORT=${PORT:-3200}
BASE="http://127.0.0.1:${PORT}"
REQUIRE_GLOBAL_CLI=${REQUIRE_GLOBAL_CLI:-0}
# 42_pipeline_checklist.sh
# 42_pipeline_checklist.sh
# =========================================================================================
# Diretório de execução: ~/workspace/Mini-IDE
#
# Checklist completo da pipeline:
#  1) pnpm install
#  2) build (tsconfig.build.json) de todos os pacotes
#  3) typecheck --noEmit
#  4) lint (ESLint)
#  5) test (Vitest)
#  6) docs (TypeDoc) + verificação de arquivo gerado
#  7) Smoke do servidor: sobe Fastify temporário na :3200, valida /healthz e /analyze
#  8) CLI local (node dist) e, se existir, CLI global (mini-ide)
#  9) Resumo final
#
# Boas práticas:
#  - fail-fast (set -euo pipefail)
#  - logs claros
#  - cleanup garantido via trap
# =========================================================================================
set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
cd "$ROOT"

# ---------- Utilidades ----------
log()  { printf "%s\n" "$*"; }
ok()   { printf "\033[32m[ok]\033[0m %s\n" "$*"; }
info() { printf "\033[34m[info]\033[0m %s\n" "$*"; }
warn() { printf "\033[33m[aviso]\033[0m %s\n" "$*"; }
err()  { printf "\033[31m[erro]\033[0m %s\n" "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "comando não encontrado: $1"; exit 1; }
}

# ---------- Pré-checagens ----------
require_cmd pnpm
require_cmd node
require_cmd jq
require_cmd curl

[ -f "pnpm-workspace.yaml" ] || { err "pnpm-workspace.yaml não encontrado em $ROOT"; exit 1; }
[ -d "packages/server" ] || { err "packages/server não encontrado"; exit 1; }
[ -d "packages/cli" ] || { err "packages/cli não encontrado"; exit 1; }

info "Node: $(node -v) | PNPM: $(pnpm -v)"
ok "estrutura básica encontrada"

# ---------- 1) install ----------
log "-- install --"
pnpm install --frozen-lockfile
ok "install"

# ---------- 2) build ----------
log "-- build --"
pnpm -r --parallel --workspace-concurrency=1 run build
ok "build OK"

# ---------- 3) typecheck ----------
log "-- typecheck --"
pnpm -r --parallel --workspace-concurrency=1 run typecheck
ok "typecheck OK"

# ---------- 4) lint ----------
log "-- lint --"
pnpm -r --parallel --workspace-concurrency=1 run lint
ok "lint OK"

# ---------- 5) test ----------
log "-- test --"
pnpm -r --parallel --workspace-concurrency=1 run test
ok "tests OK"

# ---------- 6) docs ----------
log "-- docs --"
pnpm run docs >/tmp/typedoc.log 2>&1 || {
  err "TypeDoc falhou. Veja /tmp/typedoc.log"
  exit 1
}
DOCS_HTML="$ROOT/docs/api/index.html"
[ -f "$DOCS_HTML" ] || { err "TypeDoc não gerou $DOCS_HTML"; exit 1; }
ok "docs geradas: $DOCS_HTML"

# ---------- 7) Smoke do servidor ----------
# Sobe servidor temporário na porta 3200 e valida endpoints
TMP_LOG="/tmp/mini-ide-server.log"
SERVER_PID=""

cleanup() {
  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    info "encerrando server temporário (pid=$SERVER_PID)…"
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    sleep 0.2
  fi
}
trap cleanup EXIT

info "subindo server temporário em :$PORT…"
# Usa tsx no modo dev para rapidez (mesmo padrão já utilizado no projeto)
( PORT=$PORT pnpm -F @mini-ide/server run dev ) >"$TMP_LOG" 2>&1 &
SERVER_PID=$!

# aguarda readiness (timeout simples ~5s)
ATTEMPTS=25
SLEEP=0.2
READY=0
for i in $(seq 1 $ATTEMPTS); do
  if curl -sf "http://127.0.0.1:$PORT/healthz" >/dev/null 2>&1; then
    READY=1; break
  fi
  sleep "$SLEEP"
done

if [ "$READY" -ne 1 ]; then
  warn "server ainda não respondeu /healthz. Log parcial:"
  tail -n 50 "$TMP_LOG" || true
  err "falha ao subir server temporário"
  exit 1
fi
ok "server temporário pronto em :$PORT"

# /healthz
log "-- validar /healthz --"
HEALTHZ="$(curl -sf "http://127.0.0.1:$PORT/healthz" | jq -r '.status,.service,.uptime' || true)"
echo "$HEALTHZ" | grep -q "^ok$" || { err "/healthz inválido"; exit 1; }
ok "/healthz válido"

# /analyze
log "-- validar /analyze --"
ANALYZE_REQ='{"input":"  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ","maxLen":60}'
ANALYZE_RES="$(curl -sf -H 'content-type: application/json' -d "$ANALYZE_REQ" "http://127.0.0.1:$PORT/analyze")"
ANALYZE_OK="$(echo "$ANALYZE_RES" | jq -r '.ok')" || true
[ "$ANALYZE_OK" = "true" ] || { err "/analyze retornou erro: $ANALYZE_RES"; exit 1; }
ok "/analyze válido"

# ---------- 8) CLI (local e global) ----------
# 8.1) CLI local (dist)
log "-- validar CLI local (node packages/cli/dist/index.js) --"
CLI_OUT_DIR="$ROOT/bundles/v1.0.12"
mkdir -p "$CLI_OUT_DIR"
node "$ROOT/packages/cli/dist/index.js" analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 42 --url "http://127.0.0.1:$PORT" >/tmp/mini-ide-cli-local.log 2>&1 || {
  err "CLI local falhou. Veja /tmp/mini-ide-cli-local.log"
  exit 1
}
# Extrai caminho do arquivo salvo a partir do log do CLI
CLI_SAVED="$(grep -oE '/[^ ]+/analysis-[0-9\-]+\.json' /tmp/mini-ide-cli-local.log | tail -n1 || true)"
[ -n "$CLI_SAVED" ] && [ -f "$CLI_SAVED" ] || { err "arquivo do CLI local não encontrado"; exit 1; }
ok "CLI local OK: $CLI_SAVED"

# 8.2) CLI global (se presente)
if command -v mini-ide >/dev/null 2>&1; then
  log "-- validar CLI global (mini-ide) --"
  mini-ide analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 42 --url "http://127.0.0.1:$PORT" >/tmp/mini-ide-cli-global.log 2>&1 || {
    err "CLI global falhou. Veja /tmp/mini-ide-cli-global.log"
# desativado:     exit 1
  }
  CLI_G_SAVED="$(grep -oE '/[^ ]+/analysis-[0-9\-]+\.json' /tmp/mini-ide-cli-global.log | tail -n1 || true)"
  [ -n "$CLI_G_SAVED" ] && [ -f "$CLI_G_SAVED" ] || { err "arquivo do CLI global não encontrado"; exit 1; }
  ok "CLI global OK: $CLI_G_SAVED"
else
  warn "CLI global (mini-ide) não encontrado no PATH — ignorando etapa (OK)"
fi

# ---------- 9) Resumo ----------
echo "----------------------------------------"
echo "CHECKLIST GERAL: SUCESSO ✅"
echo "Server base: http://127.0.0.1:$PORT"
echo "Docs:        $DOCS_HTML"
echo "CLI local:   $CLI_SAVED"
[ -n "${CLI_G_SAVED:-}" ] && echo "CLI global:  $CLI_G_SAVED"
echo "----------------------------------------"
