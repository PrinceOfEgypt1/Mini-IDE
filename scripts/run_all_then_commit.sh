# scripts/run_all_then_commit.sh
#!/usr/bin/env bash
set -euo pipefail

# Configs seguras para o pipeline local
export REQUIRE_GLOBAL_CLI="${REQUIRE_GLOBAL_CLI:-0}"   # não exige CLI global
export PORT="${PORT:-3201}"                            # evita conflito
CHECKLIST="./42_pipeline_checklist.sh"

msg_default="chore: pipeline verde (build/typecheck/lint/tests/CLI)"
MSG="${1:-$msg_default}"
DO_PUSH="${DO_PUSH:-0}"  # export DO_PUSH=1 para dar push

echo "[info] Executando checklist completo (PORT=$PORT, REQUIRE_GLOBAL_CLI=$REQUIRE_GLOBAL_CLI)…"
bash "$CHECKLIST"

echo "[ok] Checklist 100% verde"
echo "[info] Preparando commit…"
git add -A

# Se não houver mudanças, não falha
if git diff --cached --quiet; then
  echo "[ok] Nada para commitar (working tree limpo)."
  exit 0
fi

git commit -m "$MSG"
echo "[ok] Commit criado: $(git rev-parse --short HEAD)"

if [ "$DO_PUSH" = "1" ]; then
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  echo "[info] Dando push em '$current_branch'…"
  git push origin "$current_branch"
  echo "[ok] Push concluído."
else
  echo "[info] Push desabilitado (export DO_PUSH=1 para enviar)."
fi
