# 27_fix_lint_and_resmoke.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Corrigir falhas de lint no pacote @mini-ide/cli:
#       * remover variáveis não usadas no parseArgs ([_node, _file] -> [, , ])
#       * tornar `input` imutável em parseAnalyze (let -> const)
#   - Revalidar: build/typecheck/lint/test/docs do monorepo
#   - Subir server temporário (porta 3100) se necessário e exercitar o CLI
# Idempotente: pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
CLI="$ROOT/packages/cli/src/index.ts"
BUND="$ROOT/bundles/v1.0.12"
mkdir -p "$BUND"

echo "== MINI-IDE :: 27_fix_lint_and_resmoke =="

test -f "$CLI" || { echo "erro: arquivo não encontrado: $CLI"; exit 1; }

# 1) Patch 1 — remover variáveis não usadas em parseArgs ([_node, _file] -> [, , ])
#    Substitui exatamente a linha de destructuring.
if grep -qE 'const \[_node,\s*_file,\s*\.\.\.rest] = argv;' "$CLI"; then
  sed -i 's/const \[_node, *_file, *\.\.\.rest] = argv;/const [, , ...rest] = argv;/' "$CLI"
  echo "[ok] parseArgs: removidas variáveis não usadas (_node, _file)."
else
  echo "[info] parseArgs já está sem variáveis não usadas (ok)."
fi

# 2) Patch 2 — tornar `input` imutável em parseAnalyze (let -> const)
#    Troca apenas a primeira atribuição `let input: string = first;`
if grep -qE 'let input: string = first;' "$CLI"; then
  sed -i 's/let input: string = first;/const input: string = first;/' "$CLI"
  echo "[ok] parseAnalyze: alterado let->const em input."
else
  echo "[info] parseAnalyze já usa const em input (ok)."
fi

# 3) Rebuild e lint apenas do CLI para feedback rápido
pnpm -F @mini-ide/cli run build
pnpm -F @mini-ide/cli run lint

# 4) Pipeline completo (build/typecheck/lint/test/docs)
echo "[info] pipeline completo do workspace…"
pnpm -r run build
pnpm -r run typecheck
pnpm -r run lint
pnpm -r run test

echo "[info] gerando TypeDoc…"
pnpm run docs
echo "[ok] docs em: $ROOT/docs/api"

# 5) Subir server temporário (porta 3100) se não houver em 3000/3100
NEED_TEMP_SERVER=0
PORT=3100
if curl -sf http://localhost:3000/healthz >/dev/null 2>&1; then
  echo "[info] server já rodando em :3000 — usarei essa instância."
  PORT=3000
else
  if curl -sf http://localhost:$PORT/healthz >/dev/null 2>&1; then
    echo "[info] server já rodando em :$PORT — usarei essa instância."
  else
    NEED_TEMP_SERVER=1
    echo "[info] subindo server temporário em :$PORT…"
    ( cd "$ROOT/packages/server" && PORT=$PORT pnpm run dev ) >/tmp/mini-ide-server.log 2>&1 &
    SRV_PID=$!

    cleanup() {
      if [ "${NEED_TEMP_SERVER:-0}" -eq 1 ] && ps -p "${SRV_PID:-0}" >/dev/null 2>&1; then
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
      if ! ps -p "$SRV_PID" >/dev/null 2>&1; then
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

# 6) Exercitar CLI contra /analyze
echo "[info] exercitando CLI (mini-ide analyze)…"
mini-ide analyze "  Linha 1   \r\n\r\n   Linha 2\t ok  " --maxLen 80 --url "http://localhost:$PORT" || {
  echo "[erro] CLI falhou. Tente relincar: pnpm link --global @mini-ide/cli"
  exit 1
}

# 7) Mostrar arquivo salvo
LAST=$(ls -1t "$BUND"/analysis-*.json 2>/dev/null | head -n1 || true)
if [ -n "${LAST:-}" ]; then
  echo "[ok] arquivo gerado: $LAST"
  if command -v jq >/dev/null 2>&1; then
    jq '.response | {ok, inputLen, outputLen, result}' "$LAST"
  else
    head -n 30 "$LAST" || true
  fi
else
  echo "[aviso] nenhum analysis-*.json encontrado em $BUND"
fi

echo "== OK :: lint corrigido e smoke completo executado =="
