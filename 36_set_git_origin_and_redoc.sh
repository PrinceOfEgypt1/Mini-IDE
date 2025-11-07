# 36_set_git_origin_and_redoc.sh
# -------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo: configurar git remote "origin" e regerar TypeDoc sem warnings.
# Uso:
#   export GIT_ORIGIN='git@github.com:<user>/Mini-IDE.git'
#   bash 36_set_git_origin_and_redoc.sh
# -------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
cd "$ROOT"

if [ -z "${GIT_ORIGIN:-}" ]; then
  echo "[erro] defina GIT_ORIGIN (ex.: git@github.com:<user>/Mini-IDE.git)"; exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "[ok] origin já configurado: $(git remote get-url origin)"
else
  echo "[info] adicionando origin: $GIT_ORIGIN"
  git remote add origin "$GIT_ORIGIN"
fi

echo "[info] regenerando TypeDoc…"
pnpm run docs
test -f "$ROOT/docs/api/index.html" || { echo "[erro] docs não geradas"; exit 1; }

echo "== OK :: TypeDoc atualizado em $ROOT/docs/api/index.html =="
