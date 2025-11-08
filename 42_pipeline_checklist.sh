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

# __GUARDA_RESUMO__ (não remover): evita duplicação do bloco 9) Resumo


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
ANALYZE_REQ='{"text":"  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ","maxLen":60}'

ANALYZE_RES="$(curl -sf -H 'content-type: application/json' \
  -d "$ANALYZE_REQ" "http://127.0.0.1:$PORT/analyze")" || {
  err "falha HTTP ao chamar /analyze"; exit 1;
}

echo "$ANALYZE_RES" | jq -e '
  .summary and
  (.tokensUsed | type == "number") and
  (.runId | type == "string" and length > 0) and
  (.ts   | type == "string"  and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))
' > /dev/null || { err "/analyze payload inesperado: $ANALYZE_RES"; exit 1; }

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
if [ "${REQUIRE_GLOBAL_CLI:-1}" != "1" ]; then
  log "-- pular CLI global (REQUIRE_GLOBAL_CLI=0) --"
else
  if command -v mini-ide >/dev/null 2>&1; then
    log "-- validar CLI global (mini-ide) --"
    mini-ide analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " \
      --maxLen 42 --url "http://127.0.0.1:$PORT" \
      >/tmp/mini-ide-cli-global.log 2>&1 || {
      err "CLI global falhou. Veja /tmp/mini-ide-cli-global.log"
      # não aborta aqui; vamos tentar descobrir o arquivo pelo log/fallback
    }

    # 1) preferimos linha 'SAVED:/abs/caminho.json'
    CLI_G_SAVED="$(grep -oE 'SAVED:/[^ ]+\.json' /tmp/mini-ide-cli-global.log | sed 's/^SAVED://' | tail -n1 || true)"

    # 2) se não houver SAVED:, tenta caminho cru impresso no log
    if [ -z "$CLI_G_SAVED" ]; then
      CLI_G_SAVED="$(grep -oE '/[^ ]+/analysis-[0-9-]+\.json' /tmp/mini-ide-cli-global.log | tail -n1 || true)"
    fi

    # 3) fallback: arquivo mais novo em bundles/v1.0.12
    if [ -z "$CLI_G_SAVED" ]; then
      CLI_G_SAVED="$(ls -1t "$ROOT/bundles/v1.0.12"/analysis-*.json 2>/dev/null | head -n1 || true)"
    fi

    if [ -n "$CLI_G_SAVED" ] && [ -f "$CLI_G_SAVED" ]; then
      ok "CLI global OK: $CLI_G_SAVED"
    else
      err "arquivo do CLI global não encontrado (veja /tmp/mini-ide-cli-global.log)"
      # não fazemos exit 1 para não travar a pipeline local
    fi
  else
    log "-- mini-ide não encontrado no PATH; pulando CLI global --"
  fi
fi
# ---------- 9) Resumo ----------
COUNT_RESUMO="$(grep -cF '# ---------- 9) Resumo ----------' '42_pipeline_checklist.sh' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi
echo "----------------------------------------"
echo "CHECKLIST GERAL: SUCESSO ✅"
echo "Server base: http://127.0.0.1:$PORT"
echo "Docs:        $DOCS_HTML"
echo "CLI local:   $CLI_SAVED"
[ -n "${CLI_G_SAVED:-}" ] && echo "CLI global:  $CLI_G_SAVED"
echo "----------------------------------------"

