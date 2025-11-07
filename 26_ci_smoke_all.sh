# 26_ci_smoke_all.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Rodar um smoke completo do monorepo (build/typecheck/lint/test/docs)
#   - Subir o server TEMPORARIAMENTE em porta 3100 (se não estiver rodando)
#   - Exercitar o CLI `mini-ide analyze` contra o server e salvar JSON em bundles/v1.0.12/
#   - Encerrar o server temporário com limpeza garantida (trap)
# Idempotente: pode ser executado quantas vezes quiser.
# Requisitos: Node 22+, pnpm, jq (opcional), mini-ide (CLI) já linkado globalmente.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
BUND="$ROOT/bundles/v1.0.12"
mkdir -p "$BUND"

echo "== MINI-IDE :: 26_ci_smoke_all =="

# 0) Ambiente
echo "[info] Node: $(node -v) | PNPM: $(pnpm -v)"

# 1) Instalar dependências (rápido, lockfile já presente)
pnpm install --frozen-lockfile

# 2) Build/Typecheck/Lint/Test (todos os pacotes)
echo "[info] build/typecheck/lint/test de todo o workspace…"
pnpm -r run build
pnpm -r run typecheck
pnpm -r run lint
pnpm -r run test

# 3) Docs (TypeDoc)
echo "[info] gerando documentação TypeDoc…"
pnpm run docs
echo "[ok] docs geradas em: $ROOT/docs/api"

# 4) Server temporário (porta 3100) — apenas se não houver já um server em 3000/3100
NEED_TEMP_SERVER=0
PORT=3100
if curl -sf http://localhost:3000/healthz >/dev/null 2>&1; then
  echo "[info] server já está rodando em :3000 — usarei essa instância."
  PORT=3000
else
  if curl -sf http://localhost:$PORT/healthz >/dev/null 2>&1; then
    echo "[info] server já está rodando em :$PORT — usarei essa instância."
  else
    NEED_TEMP_SERVER=1
    echo "[info] subindo server temporário em :$PORT…"
    # sobe em background com PORT=3100; trap garante kill
    ( cd "$ROOT/packages/server" && PORT=$PORT pnpm run dev ) >/tmp/mini-ide-server.log 2>&1 &
    SRV_PID=$!

    cleanup() {
      if ps -p "${SRV_PID:-0}" >/dev/null 2>&1; then
        echo "[info] encerrando server temporário (pid=$SRV_PID)…"
        kill "$SRV_PID" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup EXIT

    # aguardar até ficar pronto (timeout 20s)
    for i in $(seq 1 40); do
      if curl -sf "http://localhost:$PORT/healthz" >/dev/null 2>&1; then
        echo "[ok] server temporário pronto em :$PORT"
        break
      fi
      sleep 0.5
      if ! ps -p "$SRV_PID" >/dev/null 2>&1; then
        echo "[erro] processo do server saiu prematuramente. Veja /tmp/mini-ide-server.log"
        exit 1
      fi
      if [ "$i" -eq 40 ]; then
        echo "[erro] timeout ao subir server temporário. Veja /tmp/mini-ide-server.log"
        exit 1
      fi
    done
  fi
fi

# 5) Exercitar CLI (mini-ide analyze) e salvar JSON em bundles/
echo "[info] exercitando CLI contra http://localhost:$PORT/analyze…"
mini-ide analyze "  Linha 1   \r\n\r\n   Linha 2\t ok  " --maxLen 80 --url "http://localhost:$PORT" || {
  echo "[erro] CLI falhou. Verifique se o binário global está linkado: pnpm link --global @mini-ide/cli"
  exit 1
}

# 6) Mostrar último arquivo gerado
LAST=$(ls -1t "$BUND"/analysis-*.json 2>/dev/null | head -n1 || true)
if [ -n "${LAST:-}" ]; then
  echo "[ok] arquivo gerado: $LAST"
  if command -v jq >/dev/null 2>&1; then
    echo "[preview]"
    jq '.response | {ok, inputLen, outputLen, result}' "$LAST"
  else
    head -n 30 "$LAST" || true
  fi
else
  echo "[aviso] nenhum arquivo analysis-*.json encontrado em $BUND"
fi

echo "== OK :: smoke completo (build/typecheck/lint/test/docs/CLI) concluído =="
echo "Dicas:"
echo " - Server local: curl -s http://localhost:$PORT/healthz | jq"
echo " - Docs:        (já geradas em docs/api)  ->  pnpm run docs:serve"
