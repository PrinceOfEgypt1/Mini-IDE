# 35_finalize_cli_global_and_docs.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
#
# Objetivo (fechamento definitivo):
#  1) Corrigir avisos do TypeDoc trocando @description -> @remarks (TSDoc válido).
#  2) (Opcional) Configurar git remote "origin" se variável GIT_ORIGIN estiver definida
#     e nenhum origin existir, evitando warning de source links quebrados no TypeDoc.
#  3) Regerar docs e validar artefato principal.
#  4) Linkar o CLI globalmente da forma correta (a partir do diretório do pacote).
#     - Ajustar PATH do pnpm global (~/.local/share/pnpm) se necessário.
#     - Se ainda não disponível, criar wrapper em ~/.local/bin/mini-ide (fallback).
#  5) Subir (se necessário) o server temporário (:3100), exercitar endpoints e o CLI
#     global, e confirmar o arquivo de saída em bundles/v1.0.12/.
#
# Idempotente e verboso. Pode rodar quantas vezes quiser.
# Requisitos: Node 22+, pnpm; jq opcional.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
CLI="$ROOT/packages/cli"
BUND="$ROOT/bundles/v1.0.12"
DOC_MAIN="$ROOT/docs/api/index.html"
PORT="${PORT:-3100}"
BIN_NAME="mini-ide"
PNPM_GLOBAL="$HOME/.local/share/pnpm"
LOCAL_BIN="$HOME/.local/bin"

echo "== MINI-IDE :: 35_finalize_cli_global_and_docs =="

# 0) sanity
cd "$ROOT" || { echo "[erro] não encontrei $ROOT"; exit 1; }
command -v node >/dev/null || { echo "[erro] Node não encontrado no PATH"; exit 1; }
command -v pnpm >/dev/null || { echo "[erro] pnpm não encontrado no PATH"; exit 1; }
mkdir -p "$BUND"

# 1) Corrigir TSDoc (@description -> @remarks) para evitar warnings do TypeDoc
echo "[info] ajustando TSDoc (@description -> @remarks)…"
FOUND="$(grep -RIl --include='*.ts' '@description' packages || true)"
if [ -n "${FOUND:-}" ]; then
  # shellcheck disable=SC2086
  sed -i 's/@description/@remarks/g' $FOUND
  echo "[ok] tags TSDoc atualizadas:"
  # shellcheck disable=SC2001
  echo "$FOUND" | sed 's/^/  - /'
else
  echo "[info] nenhuma tag @description encontrada (ok)"
fi

# 2) (Opcional) Configurar git remote origin se variável GIT_ORIGIN estiver set e origin ausente
if ! git remote get-url origin >/dev/null 2>&1; then
  if [ "${GIT_ORIGIN:-}" != "" ]; then
    if echo "$GIT_ORIGIN" | grep -Eq '^(git@|https://)'; then
      echo "[info] adicionando git remote origin: $GIT_ORIGIN"
      git remote add origin "$GIT_ORIGIN" || true
    else
      echo "[aviso] GIT_ORIGIN não parece uma URL git válida; ignorei."
    fi
  else
    echo "[aviso] sem git remote origin; se quiser links corretos no TypeDoc, exporte GIT_ORIGIN e rode de novo."
  fi
else
  echo "[ok] git remote origin já configurado: $(git remote get-url origin)"
fi

# 3) Regerar docs
echo "[info] gerando documentação…"
pnpm run docs
test -f "$DOC_MAIN" || { echo "[erro] documentação não gerada em $DOC_MAIN"; exit 1; }
echo "[ok] docs geradas: $DOC_MAIN"

# 4) Link global do CLI da forma correta (a partir do pacote)
echo "[info] build do CLI…"
pnpm -F @mini-ide/cli run build
test -f "$CLI/dist/index.js" || { echo "[erro] não encontrei $CLI/dist/index.js"; exit 1; }

echo "[info] link global do CLI via pnpm (no diretório do pacote)…"
( cd "$CLI" && pnpm link --global ) || true

# Ajuste de PATH para pnpm global
if [ -d "$PNPM_GLOBAL" ]; then
  case ":$PATH:" in
    *":$PNPM_GLOBAL:"*) : ;;
    *) export PATH="$PNPM_GLOBAL:$PATH"; echo "[info] PATH atualizado com $PNPM_GLOBAL";;
  esac
fi

# Fallback: criar wrapper caso o bin global não esteja disponível
if ! command -v "$BIN_NAME" >/dev/null 2>&1; then
  echo "[aviso] $BIN_NAME não encontrado no PATH; criando wrapper em $LOCAL_BIN/$BIN_NAME"
  mkdir -p "$LOCAL_BIN"
  cat > "$LOCAL_BIN/$BIN_NAME" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec node "$HOME/workspace/Mini-IDE/packages/cli/dist/index.js" "$@"
EOF
  chmod +x "$LOCAL_BIN/$BIN_NAME"
  case ":$PATH:" in
    *":$LOCAL_BIN:"*) : ;;
    *) export PATH="$LOCAL_BIN:$PATH"; echo "[info] PATH atualizado com $LOCAL_BIN";;
  esac
fi

command -v "$BIN_NAME" >/dev/null 2>&1 && echo "[ok] $BIN_NAME disponível em: $(command -v $BIN_NAME)" || {
  echo "[erro] não consegui disponibilizar $BIN_NAME no PATH"; exit 1;
}

# 5) Subir server temporário (se necessário) e validar endpoints + CLI global
USE_PORT=""
if curl -sf "http://localhost:3000/healthz" >/dev/null 2>&1; then
  USE_PORT=3000
  echo "[info] usando server existente em :3000"
else
  if curl -sf "http://localhost:$PORT/healthz" >/dev/null 2>&1; then
    USE_PORT=$PORT
    echo "[info] usando server existente em :$PORT"
  else
    echo "[info] subindo server temporário em :$PORT…"
    ( cd "$SRV" && PORT="$PORT" pnpm run dev ) >/tmp/mini-ide-server.log 2>&1 &
    SRV_PID=$!
    cleanup() {
      if ps -p "${SRV_PID:-0}" >/dev/null 2>&1; then
        echo "[info] encerrando server temporário (pid=$SRV_PID)…"
        kill "$SRV_PID" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup EXIT
    # aguarda pronto
    for i in $(seq 1 40); do
      if curl -sf "http://localhost:$PORT/healthz" >/dev/null 2>&1; then
        USE_PORT=$PORT
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

echo "-- validar /healthz --"
curl -sf "$BASE_URL/healthz" | (command -v jq >/dev/null 2>&1 && jq . || cat) >/dev/null
echo "[ok] /healthz ok"

echo "-- validar /analyze --"
AN="$(curl -sf -X POST "$BASE_URL/analyze" -H 'content-type: application/json' \
  -d '{"input":"  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação ","maxLen":60}')" || true
test -n "$AN" || { echo "[erro] /analyze não respondeu"; exit 1; }
echo "$AN" | (command -v jq >/dev/null 2>&1 && jq . || cat)
echo "$AN" | grep -q '"ok":true' || { echo "[erro] /analyze não retornou ok=true"; exit 1; }
echo "[ok] /analyze ok"

echo "-- validar CLI global ($BIN_NAME) --"
"$BIN_NAME" analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 60 --url "$BASE_URL" || {
  echo "[erro] execução do CLI global falhou"; exit 1;
}

LAST="$(ls -1t "$BUND"/analysis-*.json 2>/dev/null | head -n1 || true)"
test -n "${LAST:-}" || { echo "[erro] arquivo do CLI não foi gerado em $BUND"; exit 1; }
echo "[ok] arquivo gerado pelo CLI: $LAST"
(command -v jq >/dev/null 2>&1 && jq '.response | {ok, outputLen, result}' "$LAST") || head -n 40 "$LAST"

echo "----------------------------------------"
echo "FINALIZAÇÃO: SUCESSO ✅"
echo "Server base: $BASE_URL"
echo "Docs:        $DOC_MAIN"
echo "CLI output:  $LAST"
echo "----------------------------------------"
echo "Dica: para corrigir links de origem no TypeDoc, rode com:"
echo "      GIT_ORIGIN='git@github.com:<user>/Mini-IDE.git' bash 35_finalize_cli_global_and_docs.sh"
