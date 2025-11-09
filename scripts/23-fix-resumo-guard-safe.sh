#!/usr/bin/env bash
# scripts/23-fix-resumo-guard-safe.sh
# Corrige definitivamente a guarda do bloco "9) Resumo" em 42_pipeline_checklist.sh
# Uso:
#   bash scripts/23-fix-resumo-guard-safe.sh          # dry-run
#   bash scripts/23-fix-resumo-guard-safe.sh --run    # aplica
#   bash scripts/23-fix-resumo-guard-safe.sh --run --commit

set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for a in "${@:-}"; do
  case "$a" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) ;; # ignora
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || { echo "[erro] rode dentro de um repositório git"; exit 1; }
cd "$ROOT"

FILE="42_pipeline_checklist.sh"
[ -f "$FILE" ] || { echo "[erro] não encontrei $FILE na raiz do repo"; exit 1; }

SAFE_LINE='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Arquivo: $ROOT/$FILE"
echo "Ações: remover guarda antiga + fi correspondente; limpar COUNT_RESUMO antigos; injetar guarda segura após header."

# localizar header
HEADER_LINE="$(grep -nF '# ---------- 9) Resumo ----------' "$FILE" | head -1 | cut -d: -f1 || true)"
[ -n "${HEADER_LINE:-}" ] || { echo "[erro] header '# ---------- 9) Resumo ----------' não encontrado"; exit 1; }

# localizar linha exata do IF antigo (busca LITERAL, sem regex)
OLD_IF_PATTERN='if [ "$(grep -c "^# ---------- 9\) Resumo ----------$" "42_pipeline_checklist.sh")" -gt 1 ]; then'
OLD_IF_LINE="$(grep -nF "$OLD_IF_PATTERN" "$FILE" | head -1 | cut -d: -f1 || true)"

# localizar COUNT_RESUMO antigos
COUNT_LINES="$(grep -n '^COUNT_RESUMO=' "$FILE" || true)"

if [ "$DO_RUN" -eq 0 ]; then
  echo
  echo "[dry-run] header em: $HEADER_LINE"
  [ -n "${OLD_IF_LINE:-}" ] && echo "[dry-run] guarda antiga (if...) na linha: $OLD_IF_LINE" || echo "[dry-run] guarda antiga não encontrada (ok)"
  [ -n "${COUNT_LINES:-}" ] && echo "[dry-run] COUNT_RESUMO antigos:"$'\n'"$COUNT_LINES" || echo "[dry-run] nenhum COUNT_RESUMO antigo (ok)"
  exit 0
fi

cp -f "$FILE" "$FILE.bak.23fix"

# 1) Remover COUNT_RESUMO antigos
if [ -n "${COUNT_LINES:-}" ]; then
  # remove todas as linhas que começam com COUNT_RESUMO=
  grep -v '^COUNT_RESUMO=' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
fi

# 2) Se existir o IF antigo, remover bloco do IF até o próximo 'fi' simples
if [ -n "${OLD_IF_LINE:-}" ]; then
  # encontra a primeira linha 'fi' após o IF antigo
  END_FI="$(awk -v start="$OLD_IF_LINE" 'NR>start && $0 ~ /^[[:space:]]*fi[[:space:]]*$/ {print NR; exit}' "$FILE")"
  if [ -z "${END_FI:-}" ]; then
    echo "[aviso] não encontrei 'fi' após a linha $OLD_IF_LINE; vou remover apenas a linha do if para evitar dano maior."
    sed -i "${OLD_IF_LINE}d" "$FILE"
  else
    # deleta do IF ao FI (inclusive)
    sed -i "${OLD_IF_LINE},${END_FI}d" "$FILE"
  fi
fi

# 3) Injetar guarda segura logo após o header, se não existir
if ! grep -q '^COUNT_RESUMO=' "$FILE"; then
  awk -v hline="$HEADER_LINE" -v safe="$SAFE_LINE" 'NR==hline{print; print safe; next} {print}' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
fi

# 4) garantir newline final
tail -c1 "$FILE" | read -r _ || echo >> "$FILE"

# 5) commit opcional
if [ "$DO_COMMIT" -eq 1 ]; then
  git add "$FILE"
  git commit -m "chore(checklist): remove guarda antiga (grep -c regex), injeta guarda segura literal após o header do bloco 9) Resumo"
fi

echo "[ok] patch aplicado."
echo "[info] validando execução do checklist…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true
