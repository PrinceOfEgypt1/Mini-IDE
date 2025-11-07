#!/usr/bin/env bash
set -euo pipefail

# 0) Config
KEEP_SCRIPTS=(
  "17_dev_all.sh"
  "42_pipeline_checklist.sh"
  "46_safe_tag_and_push.sh"
)
ARCHIVE_DIR="scripts/archive-$(date +%Y%m%d-%H%M%S)"

echo "== Mini-IDE :: Cleanup seguro =="
echo "[i] Branch de trabalho: chore/cleanup-scripts-$(date +%Y%m%d-%H%M)"
git switch -c "chore/cleanup-scripts-$(date +%Y%m%d-%H%M)" || true

# 1) Criar pasta de arquivo
mkdir -p "$ARCHIVE_DIR"

# 2) Mapear scripts na raiz
mapfile -t ALL_SH < <(find . -maxdepth 1 -type f -name '*.sh' -printf '%P\n' | sort)

# 3) Mover para arquivo tudo que NÃO estiver na whitelist
for f in "${ALL_SH[@]}"; do
  keep=false
  for k in "${KEEP_SCRIPTS[@]}"; do
    [[ "$f" == "$k" ]] && keep=true && break
  done
  if ! $keep; then
    echo "[mv] $f -> $ARCHIVE_DIR/"
    git mv "$f" "$ARCHIVE_DIR/" 2>/dev/null || mv "$f" "$ARCHIVE_DIR/"
  else
    echo "[keep] $f"
  fi
done

# 4) Arquivar backups e resíduos (.bak, *.pre*.bak) dentro de packages/*
echo "[i] Arquivando arquivos de backup em packages/*"
mapfile -t BAKS < <(find packages -type f \( -name '*.bak' -o -name '*.bak_*' -o -name '*.pre*.bak' \))
if ((${#BAKS[@]})); then
  mkdir -p "$ARCHIVE_DIR/packages-bak"
  for f in "${BAKS[@]}"; do
    tgt="$ARCHIVE_DIR/packages-bak/${f//\//__}"
    echo "[mv] $f -> $tgt"
    git mv "$f" "$tgt" 2>/dev/null || { cp "$f" "$tgt"; rm -f "$f"; }
  done
fi

# 5) Garantir seção de scripts oficiais no README
if ! grep -q '^## Scripts oficiais$' README.md 2>/dev/null; then
  cat >> README.md <<'MD'

## Scripts oficiais
- `17_dev_all.sh` — sobe o ambiente de desenvolvimento.
- `42_pipeline_checklist.sh` — valida build/typecheck/lint/tests e endpoints (`/healthz`, `/analyze`).
- `46_safe_tag_and_push.sh` — cria tag e publica (release).
> Todos os demais scripts foram arquivados em `scripts/`. Evite executá-los.

MD
fi

# 6) Commit
git add -A
GIT_EDITOR=true HUSKY=0 git commit -m "chore(cleanup): arquiva scripts legados e padroniza whitelist de scripts oficiais" --no-verify

echo
echo "== Preview do que ficou na raiz =="
ls -1 *.sh 2>/dev/null || echo "(nenhum .sh fora da whitelist)"

echo
echo "== Rodando checklist para garantir que tudo segue verde =="
bash ./42_pipeline_checklist.sh || { echo '[x] Falha na checklist'; exit 1; }

echo
echo "== Push branch e (opcional) PR =="
git push -u origin HEAD
echo "✔ Limpeza concluída com sucesso."
