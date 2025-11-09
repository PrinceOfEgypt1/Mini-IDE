#!/usr/bin/env bash
# scripts/25-fix-resumo-dedup-hard.sh
# -----------------------------------------------------------------------------
# Objetivo: Normalizar o bloco "9) Resumo" no 42_pipeline_checklist.sh
# - Remover guard antigo (regex + grep -c) e seu 'fi'
# - Remover quaisquer linhas COUNT_RESUMO= (guards antigos/duplicados)
# - Manter apenas UM cabeçalho "# ---------- 9) Resumo ----------"
# - Injetar UM guard seguro logo após o primeiro cabeçalho
#
# Uso:
#   bash scripts/25-fix-resumo-dedup-hard.sh          # dry-run (mostra plano)
#   bash scripts/25-fix-resumo-dedup-hard.sh --run    # aplica alterações
#   bash scripts/25-fix-resumo-dedup-hard.sh --run --commit  # aplica e commita
#
# Observações:
# - Idempotente: rodar múltiplas vezes não quebra o arquivo.
# - Não depende de GNU awk extensions incomuns.
# -----------------------------------------------------------------------------
set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for a in "${@:-}"; do
  case "$a" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) ;; # ignora argumentos desconhecidos
  esac
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$ROOT" ] || { echo "[erro] rode dentro de um repo git"; exit 1; }
cd "$ROOT"

FILE="42_pipeline_checklist.sh"
[ -f "$FILE" ] || { echo "[erro] não encontrei $FILE na raiz do repo"; exit 1; }

HEADER="# ---------- 9) Resumo ----------"
# Linha EXATA do guard antigo que vimos nos logs:
OLD_IF='if [ "$(grep -c "^# ---------- 9\) Resumo ----------$" "42_pipeline_checklist.sh")" -gt 1 ]; then'
# Guard seguro (literal) que vamos padronizar:
SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Raiz: $ROOT"
echo "Alvo: $FILE"
echo "Ações:"
echo "  • Remover guard antigo (linha com grep -c regex) e seu 'fi'"
echo "  • Remover quaisquer linhas COUNT_RESUMO= (inclui guards antigos/duplicados)"
echo "  • Deduplicar cabeçalho \"$HEADER\" (manter só a 1ª ocorrência)"
echo "  • Injetar UM guard seguro imediatamente após o 1º cabeçalho"

echo
echo "[diag] Cabeçalhos atuais:"
grep -nF "$HEADER" "$FILE" || true
echo
echo "[diag] Guard antigo (if … grep -c …):"
grep -nF "$OLD_IF" "$FILE" || true
echo
echo "[diag] Linhas COUNT_RESUMO=:"
grep -n '^COUNT_RESUMO=' "$FILE" || true

if [ "$DO_RUN" -eq 0 ]; then
  echo
  echo "(dry-run) Nada alterado. Rode com --run para aplicar."
  exit 0
fi

cp -f "$FILE" "$FILE.bak.25fix"

# Transformação única, em memória:
awk -v header="$HEADER" -v oldif="$OLD_IF" -v guard="$SAFE_GUARD" '
BEGIN{
  seen_header=0
  skipping_old_if=0
  injected_guard=0
}
{
  line=$0

  # 1) Se estamos descartando até o próximo fi por causa do guard antigo:
  if (skipping_old_if==1) {
    if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/) {
      skipping_old_if=0
    }
    next
  }

  # 2) Remover guard antigo (linha exata):
  if ($0==oldif) { skipping_old_if=1; next }

  # 3) Remover QUALQUER linha COUNT_RESUMO= (evita duplicatas e versões antigas):
  if ($0 ~ /^COUNT_RESUMO=/) next

  # 4) Não manter guards seguros antigos onde quer que estejam (caso tenham sido espalhados):
  if ($0==guard) next

  # 5) Tratar cabeçalho do bloco 9) Resumo:
  if ($0==header) {
    if (seen_header==0) {
      print $0      # imprime o primeiro cabeçalho
      if (injected_guard==0) {
        print guard # injeta a guarda segura logo abaixo dele
        injected_guard=1
      }
      seen_header=1
    }
    # se já vimos o cabeçalho, não imprime cabeçalhos duplicados
    next
  }

  # 6) Linhas normais:
  print $0
}
END{
  # nada a fazer no END
}
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

# Garante newline ao final
tail -c1 "$FILE" | read -r _ || echo >> "$FILE"

if [ "$DO_COMMIT" -eq 1 ]; then
  git add "$FILE"
  git commit -m "chore(checklist): normaliza bloco 9) Resumo (dedup header, remove guards antigos/duplicados e injeta guard seguro único)"
fi

echo "[ok] Ajuste aplicado."
echo
echo "[pos] Contagem de cabeçalhos pós-fix:"
grep -nF "$HEADER" "$FILE" || true

echo "[pos] Validando guard (deve acusar >1 apenas se ainda houver duplicidade real)…"
COUNT_NOW="$(grep -cF "$HEADER" "$FILE" || echo 0)"
echo "[pos] COUNT_NOW=$COUNT_NOW"
if [ "${COUNT_NOW:-0}" -gt 1 ]; then
  echo "[aviso] Ainda há múltiplos cabeçalhos. Verifique regiões próximas do bloco 9) para conteúdo colado."
fi

echo
echo "[info] Rodando checklist (não falha este script se checklist abortar)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true
