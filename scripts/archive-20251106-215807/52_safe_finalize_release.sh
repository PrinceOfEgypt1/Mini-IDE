# 52_safe_finalize_release.sh
# Diretório de execução: ~/workspace/Mini-IDE (raiz)
# Faz:
# - Verifica CLI global; se ausente, chama 45_safe_cli_global_link.sh
# - Garante pipeline ok (build/typecheck/lint/test) antes de tag
# - Sugere próximo tag (patch) se o desejado já existir
# - Chama 46_safe_tag_and_push.sh com o tag escolhido

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
cd "$ROOT"

echo "== 52 :: SAFE FINALIZE RELEASE =="

# 1) CLI global
if ! command -v mini-ide >/dev/null 2>&1; then
  echo "[info] CLI global ausente -> executando 45_safe_cli_global_link.sh…"
  bash 45_safe_cli_global_link.sh
else
  echo "[ok] CLI global já disponível: $(command -v mini-ide)"
fi

# 2) Pipeline rápida (mesma linha da 42_pipeline_checklist, mas light)
echo "[info] validando build/typecheck/lint/test (workspace)…"
pnpm -r run build
pnpm -r run typecheck
pnpm -r run lint
pnpm -r run test

# 3) Git sanity
ORIGIN_URL="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "${ORIGIN_URL}" ]]; then
  echo "[erro] remote 'origin' não configurado. Rode 36b_set_origin_and_redoc.sh."
  exit 1
fi
echo "[ok] origin: $ORIGIN_URL"

# 4) Escolher tag
DESIRED_TAG="${1:-v1.0.13}"  # mude aqui se quiser
git fetch --tags --quiet
if git rev-parse -q --verify "refs/tags/${DESIRED_TAG}" >/dev/null; then
  echo "[aviso] tag ${DESIRED_TAG} já existe. Calculando próximo patch…"
  LAST="$(git tag --list 'v*' | sort -V | tail -n1)"
  if [[ -z "$LAST" ]]; then
    NEXT="v1.0.0"
  else
    MAJ="${LAST#v}"; IFS='.' read -r A B C <<<"$MAJ"
    NEXT="v${A}.$B.$((C+1))"
  fi
  echo "[sugestão] usando ${NEXT}"
  DESIRED_TAG="$NEXT"
fi

# 5) Tag & push (usa seu script seguro)
echo "[info] executando 46_safe_tag_and_push.sh ${DESIRED_TAG}…"
bash 46_safe_tag_and_push.sh "${DESIRED_TAG}"

echo "----------------------------------------"
echo "FINALIZAÇÃO: SUCESSO ✅"
echo "Tag:   ${DESIRED_TAG}"
echo "Docs:  $ROOT/docs/api/index.html"
echo "CLI:   $(command -v mini-ide || echo 'não-global')"
echo "----------------------------------------"
