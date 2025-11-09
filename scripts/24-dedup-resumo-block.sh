#!/usr/bin/env bash
# scripts/24-dedup-resumo-block.sh
# Objetivo: deixar um único bloco "9) Resumo" e um único guard seguro.
# Uso:
#   bash scripts/24-dedup-resumo-block.sh          # dry-run (mostra o plano)
#   bash scripts/24-dedup-resumo-block.sh --run    # aplica alterações
#   bash scripts/24-dedup-resumo-block.sh --run --commit  # aplica e commita

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
[ -n "$ROOT" ] || { echo "[erro] rode dentro de um repo git"; exit 1; }
cd "$ROOT"

FILE="42_pipeline_checklist.sh"
[ -f "$FILE" ] || { echo "[erro] não encontrei $FILE na raiz do repo"; exit 1; }

HEADER="# ---------- 9) Resumo ----------"
OLD_IF='if [ "$(grep -c "^# ---------- 9\) Resumo ----------$" "42_pipeline_checklist.sh")" -gt 1 ]; then'
SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Raiz: $ROOT"
echo "Alvo: $FILE"
echo "Ações:"
echo "  • Remover guard antigo (linha com grep -c regex) e seu 'fi' correspondente"
echo "  • Remover QUALQUER linha iniciando com COUNT_RESUMO="
echo "  • Deduplicar cabeçalho \"$HEADER\" (manter só a 1ª ocorrência)"
echo "  • Injetar UM guard seguro imediatamente após o 1º cabeçalho"

# Coleta de diagnósticos
HITS_HEADER="$(grep -nF "$HEADER" "$FILE" || true)"
HITS_OLD_IF="$(grep -nF "$OLD_IF" "$FILE" || true)"
HITS_COUNT="$(grep -n '^COUNT_RESUMO=' "$FILE" || true)"

echo
echo "[diag] Cabeçalhos encontrados:"
echo "${HITS_HEADER:-<nenhum>}"
echo
echo "[diag] Guarda antigo (if … grep -c …) encontrado:"
echo "${HITS_OLD_IF:-<nenhum>}"
echo
echo "[diag] Linhas COUNT_RESUMO=:"
echo "${HITS_COUNT:-<nenhuma>}"

if [ "$DO_RUN" -eq 0 ]; then
  echo
  echo "(dry-run) Nada alterado. Rode com --run para aplicar."
  exit 0
fi

cp -f "$FILE" "$FILE.bak.24fix"

# Transformação única via awk em memória:
# - remove o IF antigo; marca para descartar o 'fi' seguinte
# - remove linhas COUNT_RESUMO=
# - mantém apenas o primeiro cabeçalho; ignora repetidos
# - após imprimir o primeiro cabeçalho, injeta o SAFE_GUARD (se ainda não presente)
awk -v header="$HEADER" -v oldif="$OLD_IF" -v guard="$SAFE_GUARD" '
BEGIN{
  seen_header=0
  drop_until_fi=0
  injected_guard=0
}
{
  line=$0

  # 1) se estamos removendo até o próximo "fi" simples
  if (drop_until_fi==1) {
    if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/) {
      drop_until_fi=0
    }
    next
  }

  # 2) remove guard antigo e ativa remoção até "fi"
  if ($0==oldif) { drop_until_fi=1; next }

  # 3) remove QUALQUER COUNT_RESUMO
  if ($0 ~ /^COUNT_RESUMO=/) next

  # 4) tratar cabeçalho do bloco
  if ($0==header) {
    if (seen_header==1) {
      # cabeçalho duplicado => descarta
      next
    }
    # primeiro cabeçalho
    print $0
    seen_header=1
    next_line_peek=1
    next
  }

  # 5) após o primeiro cabeçalho, injeta guard seguro na PRÓXIMA linha útil,
  #    desde que ainda não tenha sido injetado e que a linha atual não seja o guard já presente
  if (seen_header==1 && injected_guard==0) {
    if ($0==guard) {
      injected_guard=1
      print $0
      seen_header=2
      next
    } else {
      print guard
      injected_guard=1
      seen_header=2
      # cai para processar a linha atual normalmente
    }
  }

  # 6) imprime linha normal
  print $0
}
END{
  # nada
}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

# Garantir newline no fim do arquivo
tail -c1 "$FILE" | read -r _ || echo >> "$FILE"

# Commit opcional
if [ "$DO_COMMIT" -eq 1 ]; then
  git add "$FILE"
  git commit -m "chore(checklist): dedup do bloco 9) Resumo e guard único; remoção de guard antigo e COUNT_RESUMO residuais"
fi

echo "[ok] Ajuste aplicado."
echo "[info] Rodando checklist para validar…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true
