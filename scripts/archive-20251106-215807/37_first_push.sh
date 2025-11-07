# 37_first_push.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Garantir branch main, commit inicial (se necessário), push para origin configurado,
#   - Regerar TypeDoc e exibir artefatos finais.
# Requisitos: git, pnpm
# Uso:
#   bash 37_first_push.sh
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
cd "$ROOT" || { echo "[erro] não encontrei $ROOT"; exit 1; }

command -v git >/dev/null || { echo "[erro] git não encontrado"; exit 1; }
command -v pnpm >/dev/null || { echo "[erro] pnpm não encontrado"; exit 1; }

# 1) Verificar origin
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[erro] origin não configurado. Use antes:"
  echo "       bash 36b_set_origin_and_redoc.sh git@github.com:PrinceOfEgypt1/Mini-IDE.git"
  exit 1
fi
echo "[ok] origin: $(git remote get-url origin)"

# 2) Garantir branch main
git symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || true
git branch -M main >/dev/null 2>&1 || true

# 3) Commit inicial (se for repositório zerado)
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A
  git commit -m "chore: bootstrap Mini-IDE (monorepo + tooling + docs)"
else
  # Se já há commits, apenas add/commit se existir algo pendente
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add -A
    git commit -m "chore: sync before first push (docs/ & configs)"
  fi
fi

# 4) Push inicial
git push -u origin main

# 5) Redoc
pnpm run docs
DOC_MAIN="$ROOT/docs/api/index.html"
test -f "$DOC_MAIN" || { echo "[erro] docs não geradas"; exit 1; }

# 6) Resumo
echo "----------------------------------------"
echo "OK: push realizado para $(git remote get-url origin) (branch: main)"
echo "Docs: $DOC_MAIN"
echo "----------------------------------------"
