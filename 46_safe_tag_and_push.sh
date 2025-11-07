# 46_safe_tag_and_push.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Objetivo: criar commit/tag e fazer push com segurança.
# Padrão: DRY-RUN (só mostra o que faria). Use  --apply  para executar.
# Proteções: aborta se houver testes/lint quebrados; confirma remote e branch.

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
TAG="${TAG:-v1.0.12}"
BRANCH="${BRANCH:-main}"
APPLY="${1:-}"
YELLOW='\033[33m'; GREEN='\033[32m'; RED='\033[31m'; NC='\033[0m'
msg() { printf "%b\n" "$*"; }
info(){ msg "${YELLOW}[info]${NC} $*"; }
ok()  { msg "${GREEN}[ok]${NC}   $*"; }
err() { msg "${RED}[erro]${NC} $*"; }

echo "== SAFE TAG & PUSH (dry-run por padrão) =="
cd "$ROOT"

# 1) Git checks
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { err "Não é um repositório Git: $ROOT"; exit 1; }
ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
[[ -n "$ORIGIN_URL" ]] || { err "Remote 'origin' ausente. Configure com: git remote add origin <URL>"; exit 1; }
ok "origin: $ORIGIN_URL"

CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$CUR_BRANCH" == "$BRANCH" ]] || info "Branch atual é '$CUR_BRANCH' (alvo: '$BRANCH')"

# 2) Pipeline local (tudo verde?)
info "Rodando pipeline rápida (build/typecheck/lint/test)…"
pnpm -s -r run build >/dev/null
pnpm -s -r run typecheck >/dev/null
pnpm -s -r run lint >/dev/null
pnpm -s -r run test >/dev/null
ok "Pipeline local OK"

# 3) Plano
echo
echo "—— Plano ——————————————————————————————————————————"
echo "• git add -A && git commit -m \"chore: pipeline green\""
echo "• git tag -a $TAG -m \"Mini-IDE $TAG\""
echo "• git push -u origin ${BRANCH}"
echo "• git push origin ${TAG}"
echo "———————————————————————————————————————————————————"
echo

if [[ "$APPLY" != "--apply" ]]; then
  info "DRY-RUN concluído. Para aplicar: TAG=v1.0.12 BRANCH=main bash 46_safe_tag_and_push.sh --apply"
  exit 0
fi

# 4) Aplicação
git add -A
git commit -m "chore: pipeline green (build/typecheck/lint/test/docs)" || info "Nada para commitar (OK)"
git tag -a "$TAG" -m "Mini-IDE $TAG" || info "Tag já existia? (OK se desejado)"
git push -u origin "$BRANCH"
git push origin "$TAG"
ok "Push e tag publicados ✅"
