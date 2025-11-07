#!/usr/bin/env bash
# 52_force_push_over_remote_readme.sh
# -----------------------------------------------------------------------------
# RECOMENDADO quando o remoto tem apenas o commit inicial de README.
# Ação: substitui o histórico remoto pelo local usando --force-with-lease.
# Diretório de execução: ~/workspace/Mini-IDE
# -----------------------------------------------------------------------------
set -euo pipefail

REMOTE="${1:-origin}"
BRANCH="${2:-main}"

echo "== 52 :: FORCE-PUSH (com --force-with-lease) =="
echo "[info] Remote: $REMOTE | Branch: $BRANCH"

# Garantir remote configurado
git remote get-url "$REMOTE" >/dev/null 2>&1 || { echo "[erro] remote '$REMOTE' não existe."; exit 1; }

echo "[info] Fetch do remoto…"
git fetch "$REMOTE" "$BRANCH" --prune

echo "[info] Status resumido:"
git status -sb || true
echo

# Dica rápida de segurança
echo "[info] Usando --force-with-lease (protege contra sobrescrever algo que você não baixou)"
git push --force-with-lease "$REMOTE" "$BRANCH"

echo "----------------------------------------"
echo "OK: histórico remoto agora espelha o local ✅"
echo "Remote: $(git remote get-url "$REMOTE")"
echo "Branch: $BRANCH"
echo "----------------------------------------"
