#!/usr/bin/env bash
# scripts/26-normalize-checklist-and-git.sh
# -----------------------------------------------------------------------------
# Objetivo:
# 1) Garantir bloco único do "9) Resumo" em 42_pipeline_checklist.sh
#    - manter UM cabeçalho "# ---------- 9) Resumo ----------"
#    - remover TODOS os COUNT_RESUMO antigos e reinjetar UM guard seguro logo abaixo do 1º header
# 2) Limpar arquivos de backup temporários gerados pelos scripts anteriores
# 3) Corrigir estado do git:
#    - garantir que bundles/**/*.json NÃO fiquem rastreados
#    - commitar as mudanças úteis (checklist, .gitignore) e remover do índice o que for gerado
#
# Uso:
#   bash scripts/26-normalize-checklist-and-git.sh          # dry-run
#   bash scripts/26-normalize-checklist-and-git.sh --run    # aplica
#   bash scripts/26-normalize-checklist-and-git.sh --run --commit  # aplica e commita
#
# Observação: idempotente; pode rodar várias vezes.
# -----------------------------------------------------------------------------
set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for a in "${@:-}"; do
  case "$a" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) ;;
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || { echo "[erro] rode dentro de um repo git"; exit 1; }
cd "$ROOT"

FILE="42_pipeline_checklist.sh"
[ -f "$FILE" ] || { echo "[erro] não encontrei $FILE na raiz do repo"; exit 1; }

HEADER="# ---------- 9) Resumo ----------"
SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "• Normalizar bloco \"$HEADER\" e reinjetar guard seguro único"
echo "• Limpar backups temporários do checklist"
echo "• Ajustar .gitignore (ignorar backups e temp) e remover bundles do índice"
echo

echo "[diag] Headers atuais:"
grep -nF "$HEADER" "$FILE" || true
echo
echo "[diag] Guards COUNT_RESUMO atuais:"
grep -n '^COUNT_RESUMO=' "$FILE" || true

if [ "$DO_RUN" -eq 0 ]; then
  echo
  echo "(dry-run) Nada alterado. Rode com --run para aplicar."
  exit 0
fi

# 1) Normaliza o arquivo (dedup header + reinjeta guard único logo após 1º header)
cp -f "$FILE" "$FILE.bak.26fix"

awk -v header="$HEADER" -v guard="$SAFE_GUARD" '
BEGIN{
  seen_header=0
  injected_guard=0
}
{
  # Remover QUALQUER linha COUNT_RESUMO (vamos reinserir só uma, no lugar certo)
  if ($0 ~ /^COUNT_RESUMO=/) next

  # Remover possíveis guards já injetados idênticos
  if ($0 == guard) next

  # Tratar cabeçalho do bloco
  if ($0 == header) {
    if (seen_header==0) {
      print $0
      if (injected_guard==0) {
        print guard
        injected_guard=1
      }
      seen_header=1
    }
    # headers extras são descartados
    next
  }

  print $0
}
END{
  # nada a fazer
}
' "$FILE" > "$FILE.tmp.26fix" && mv "$FILE.tmp.26fix" "$FILE"

# Garante newline ao final
tail -c1 "$FILE" | read -r _ || echo >> "$FILE"

# 2) Limpar backups/temporários antigos do checklist
echo "[info] Limpando backups/temporários antigos do checklist…"
rm -f 42_pipeline_checklist.sh.bak.* 2>/dev/null || true
rm -f 42_pipeline_checklist.sh.tmp.* 2>/dev/null || true

# 3) Ajustar .gitignore para também ignorar estes backups futuros
if ! grep -q '^/42_pipeline_checklist\.sh\.bak\.\*$' .gitignore 2>/dev/null; then
  printf '/42_pipeline_checklist.sh.bak.*\n' >> .gitignore
fi
if ! grep -q '^/42_pipeline_checklist\.sh\.tmp\.\*$' .gitignore 2>/dev/null; then
  printf '/42_pipeline_checklist.sh.tmp.*\n' >> .gitignore
fi

# 4) Garantir que bundles/**/*.json não esteja rastreando nada
echo "[info] Removendo bundles do índice (mantém arquivos no disco)…"
git rm -r --cached bundles 2>/dev/null || true

# 5) Commit opcional
if [ "$DO_COMMIT" -eq 1 ]; then
  git add "$FILE" .gitignore
  # Se nada para commitar, não falha
  git commit -m "chore(checklist): normaliza bloco 9) Resumo (guard único), limpa backups e ajusta ignore de bundles" || true
fi

echo
echo "[pos] Contagem de headers pós-fix:"
grep -nF "$HEADER" "$FILE" || true
CNT="$(grep -cF "$HEADER" "$FILE" || echo 0)"
echo "[pos] COUNT_HEADERS=$CNT"

echo
echo "[info] Rodando checklist (não falha este script se checklist abortar)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "[ok] Finalizado."
