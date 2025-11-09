#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "[purge] Raiz: $ROOT"

# Não varrer estas pastas
PRUNE_DIRS="\( -path './.git' -o -path './node_modules' -o -path './dist' -o -path './build' -o -path './coverage' -o -path './.husky' -o -path './logs' \) -prune"

# Critérios de backup: *.bak, *.bak.*, *_bak*, *.pre*.bak
mapfile -d '' CANDIDATES < <(
  eval "find . -type d $PRUNE_DIRS -o -type f \( -name '*.bak' -o -name '*.bak.*' -o -name '*_bak*' -o -regex '.*\.pre[^/]*\.bak$' \) -print0"
)

if (( ${#CANDIDATES[@]} == 0 )); then
  echo "[purge] Nenhum arquivo de backup encontrado."
else
  echo "[purge] Encontrados ${#CANDIDATES[@]} arquivo(s) de backup:"
  for f in "${CANDIDATES[@]}"; do
    printf '  - %s\n' "$f"
  done
  echo

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[purge] DRY_RUN=1 — nenhuma remoção realizada."
    exit 0
  fi

  # Remove arquivos
  for f in "${CANDIDATES[@]}"; do rm -f -- "$f"; done

  # Remove diretórios vazios sob packages-bak (se houver)
  find packages-bak -type d -empty -delete 2>/dev/null || true

  # Stage das deleções
  git add -A
  echo "[purge] Backups removidos e alterações staged."
fi

# Garante .gitignore com padrões de backup
GITIGNORE=".gitignore"
declare -a LINES=(
  "# Backups locais — manter fora do Git"
  "*.bak"
  "*.bak.*"
  "*_bak*"
  "packages-bak/"
  "**/*.pre*.bak"
)

touch "$GITIGNORE"
NEED_COMMIT=0
for ln in "${LINES[@]}"; do
  if ! grep -qxF "$ln" "$GITIGNORE"; then
    echo "$ln" >> "$GITIGNORE"
    NEED_COMMIT=1
  fi
done

if (( NEED_COMMIT )); then
  git add "$GITIGNORE"
  echo "[purge] .gitignore atualizado."
fi

echo "[purge] OK."
