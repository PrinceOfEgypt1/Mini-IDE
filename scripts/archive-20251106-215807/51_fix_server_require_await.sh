# 51_fix_server_require_await.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Objetivo:
# - Tornar handlers das rotas síncronos (remover 'async' onde não há await)
# - Remover comentários eslint-disable no-console não utilizados
# - Validar build/lint/test do pacote @mini-ide/server

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
SRV="$ROOT/packages/server"
SRC="$SRV/src"
IDX="$SRC/index.ts"

echo "== 51 :: FIX server require-await & cleanup no-console =="

[[ -f "$IDX" ]] || { echo "[erro] não encontrei $IDX"; exit 1; }

# Backup
cp -f "$IDX" "$IDX.bak_$(date +%Y%m%d-%H%M%S)"

# 1) Rotas: remover 'async' dos handlers que não usam await
#    - GET /healthz:  app.get('/healthz', async () => { ... })
#    - POST /analyze: app.post('/analyze', async (request) => { ... })
#    Mantemos a assinatura e só removemos 'async ' (com espaço) após a vírgula.
sed -i \
  -e "s|\(app\.get('/healthz', \)async |\1|g" \
  -e "s|\(app\.post('/analyze', \)async |\1|g" \
  "$IDX"

# 2) Remover comentários eslint-disable no-console (não usados)
sed -i "/eslint-disable-next-line no-console/d" "$IDX"

# Normalizar finais de linha
sed -i 's/\r$//' "$IDX"

echo "[info] validando @mini-ide/server…"
( cd "$SRV" && pnpm -s build && pnpm -s lint && pnpm -s test )

echo "== 51 :: OK — lint verde no server ✅ =="
