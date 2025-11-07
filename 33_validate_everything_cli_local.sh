# 33_validate_everything_cli_local.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Repetir validação ponta a ponta sem depender de `mini-ide` global.
#   - Invocar o CLI diretamente via Node (packages/cli/dist/index.js).
#   - Se desejar futuro uso global, ajusta PATH para o bin do pnpm (~/.local/share/pnpm) e tenta link.
# Idempotente e verboso; encerra server temporário com trap.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
BUND="$ROOT/bundles/v1.0.12"
SRV_DIR="$ROOT/packages/server"
CLI_DIR="$ROOT/packages/cli"
CLI_DIST="$CLI_DIR/dist/index.js"
PORT_DEFAULT=3100
PORT="${PORT:-$PORT_DEFAULT}"

echo "== MINI-IDE :: 33_validate_everything_cli_local =="

command -v node >/dev/null || { echo "[erro] Node não encontrado no PATH"; exit 1; }
command -v pnpm >/dev/null || { echo "[erro] pnpm não encontrado no PATH"; exit 1; }
echo "[info] Node: $(node -v) | PNPM: $(pnpm -v)"
mkdir -p "$BUND"

cd "$ROOT"

# 1) Pipeline básica (rápida; se já rodou, tudo cacheado)
echo "-- build/typecheck/lint/test --"
pnpm -r run build
pnpm -r run typecheck
pnpm -r run lint
pnpm -r run test

# 2) Docs (garante artefato para referência)
pnpm run docs
test -f "$ROOT/docs/api/index.html" || { echo "[erro] docs não geradas"; exit 1; }

# 3) Server: usa :3000 se estiver no ar; senão sobe temporário em :$PORT
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

# 4) Validar endpoints
echo "-- validar /healthz --"
curl -sf "$BASE_URL/healthz" | (command -v jq >/dev/null 2>&1 && jq . || cat)
echo "-- validar /analyze --"
curl -sf -X POST "$BASE_URL/analyze" -H 'content-type: application/json' \
  -d '{"input":"  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ","maxLen":60}' \
  | (command -v jq >/dev/null 2>&1 && jq . || cat)

# 5) Invocar CLI sem depender de global:
#    - Garante build do CLI e executa o entrypoint compilado via `node`.
pnpm -F @mini-ide/cli run build
if [ ! -f "$CLI_DIST" ]; then
  echo "[erro] não encontrei $CLI_DIST (build do CLI falhou?)"
  exit 1
fi

echo "-- validar CLI local (node packages/cli/dist/index.js) --"
node "$CLI_DIST" analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 60 --url "$BASE_URL"

LAST="$(ls -1t "$BUND"/analysis-*.json 2>/dev/null | head -n1 || true)"
if [ -z "${LAST:-}" ]; then
  echo "[erro] o CLI não gerou arquivo em $BUND"
  exit 1
fi
echo "[ok] arquivo gerado pelo CLI: $LAST"
(command -v jq >/dev/null 2>&1 && jq '.response | {ok, outputLen, result}' "$LAST") || head -n 40 "$LAST"

# 6) (Opcional) Configurar bin global do pnpm e linkar — não falha a execução se indisponível
if [ -d "$HOME/.local/share/pnpm" ]; then
  case ":$PATH:" in
    *":$HOME/.local/share/pnpm:"*) : ;;
    *) export PATH="$HOME/.local/share/pnpm:$PATH"; echo "[info] PATH atualizado com ~/.local/share/pnpm";;
  esac
  if ! command -v mini-ide >/dev/null 2>&1; then
    echo "[info] tentando link global opcional do CLI…"
    pnpm link --global @mini-ide/cli || true
    command -v mini-ide >/dev/null 2>&1 && echo "[ok] mini-ide disponível globalmente" || echo "[aviso] mini-ide global ainda indisponível (ok)"
  fi
else
  echo "[aviso] ~/.local/share/pnpm não existe nesta sessão; pulei link global (ok)"
fi

echo "----------------------------------------"
echo "VALIDAÇÃO GERAL (CLI LOCAL): SUCESSO ✅"
echo "Server base: $BASE_URL"
echo "Docs:        $ROOT/docs/api/index.html"
echo "CLI output:  $LAST"
echo "----------------------------------------"
