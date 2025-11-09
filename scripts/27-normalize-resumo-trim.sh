#!/usr/bin/env bash
# scripts/27-normalize-resumo-trim.sh
# Normaliza o bloco "9) Resumo" em 42_pipeline_checklist.sh de forma tolerante a espaços:
# - Remove guardas antigas (grep -c com regex) e o 'fi' correspondente
# - Remove quaisquer linhas COUNT_RESUMO= fora do lugar
# - Deduplica o header "# ---------- 9) Resumo ----------" ignorando espaços (mantém 1º, normalizado)
# - Injeta UMA guarda segura logo após o 1º header
# - Valida: 1 header, 1 guarda
#
# Uso (na RAIZ do repo):
#   chmod +x scripts/27-normalize-resumo-trim.sh
#   bash scripts/27-normalize-resumo-trim.sh --run          # aplica
#   bash scripts/27-normalize-resumo-trim.sh --run --commit # aplica e comita
#
# Saídas: sem .bak permanente; usa tmp e substitui atomicamente.

set -euo pipefail

ROOT_DIR="$(pwd)"
TARGET="42_pipeline_checklist.sh"
HEADER_CANON="# ---------- 9) Resumo ----------"
SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

RUN=0
DO_COMMIT=0
for arg in "$@"; do
  case "$arg" in
    --run) RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) ;;
  esac
done

if [ ! -f "$TARGET" ]; then
  echo "[erro] Arquivo não encontrado: $TARGET (rode na raiz do repo)" >&2
  exit 1
fi

echo "== Plano =="
echo "Raiz: $ROOT_DIR"
echo "Alvo: $TARGET"
echo "Ações:"
echo "  • Remover guarda antiga e seu 'fi'"
echo "  • Remover linhas COUNT_RESUMO= fora do lugar"
echo "  • Deduplicar header (tolerante a espaços) e normalizar"
echo "  • Injetar UMA guarda segura após o 1º header"
echo

echo "[diag] Cabeçalhos (qualquer indentação):"
nl -ba "$TARGET" | awk '{line=$0} /9\) Resumo/ {print line}' || true
echo
echo "[diag] Guard antigo (if … grep -c …):"
grep -n -F 'grep -c "^# ---------- 9\) Resumo ----------$"' "$TARGET" || true
echo
echo "[diag] Linhas COUNT_RESUMO=:"
grep -n -F 'COUNT_RESUMO=' "$TARGET" || true
echo

if [ "$RUN" -ne 1 ]; then
  echo "(dry-run) Nada alterado. Rode com --run para aplicar."
  exit 0
fi

TMP="$(mktemp "${TARGET}.tmp.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

# Regrava o arquivo com máquina de estados:
# - trim de espaços para comparar header
# - dedup de header tolerante a espaços
# - injeta guarda única logo após header
awk -v HEADER_CANON="$HEADER_CANON" -v SAFE_GUARD="$SAFE_GUARD" '
function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s){ return rtrim(ltrim(s)) }

BEGIN{
  skip_until_fi=0
  seen_header=0
  injected_guard=0
}
{
  raw=$0
  t=trim(raw)

  # 1) Se estamos descartando até encontrar um fi (veio de guarda antiga)
  if (skip_until_fi==1) {
    tmp=trim(raw)
    if (tmp=="fi") { skip_until_fi=0 }
    next
  }

  # 2) Detecta guarda antiga (linha com grep -c regex) -> ativa pulo até fi
  if (index(raw, "grep -c \"^# ---------- 9\\) Resumo ----------$\"")>0) {
    skip_until_fi=1
    next
  }

  # 3) Remove qualquer COUNT_RESUMO= fora do lugar
  if (index(raw, "COUNT_RESUMO=")>0) {
    # Não imprimimos, pois vamos injetar a guarda correta no lugar certo
    next
  }

  # 4) Dedup header (tolerante a espaços): se a linha, ao trimar, for exatamente o header canônico
  if (t==HEADER_CANON) {
    if (seen_header==0) {
      print HEADER_CANON
      if (injected_guard==0) {
        print SAFE_GUARD
        injected_guard=1
      }
      seen_header=1
    }
    # ignora headers subsequentes (duplicados, com/sem indentação)
    next
  }

  # 5) Caso comum
  print raw
}
END{
  # Se não encontramos header algum, não inventamos um — deixamos o arquivo como está.
}
' "$TARGET" > "$TMP"

mv "$TMP" "$TARGET"
trap - EXIT

# Validação final
HEADERS_COUNT="$(grep -cF "$HEADER_CANON" "$TARGET" || echo 0)"
GUARD_COUNT="$(grep -cF "$SAFE_GUARD" "$TARGET" || echo 0)"
echo
echo "[validação] headers=\"$HEADERS_COUNT\" guardas=\"$GUARD_COUNT\" (esperado: 1 / 1)"
if [ "${HEADERS_COUNT:-0}" -ne 1 ] || [ "${GUARD_COUNT:-0}" -ne 1 ]; then
  echo "[erro] Normalização não atingiu o estado esperado (1 header / 1 guarda)."
  exit 1
fi
echo "[ok] Normalização aplicada com sucesso."

# Execução rápida do checklist (somente para feedback)
echo
echo "[info] Rodando checklist (quick)…"
set +e
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
  echo "[warn] Checklist retornou código $RC — verifique o output acima."
else
  echo "[ok] Checklist finalizou com sucesso."
fi

# Commit opcional
if [ "$DO_COMMIT" -eq 1 ]; then
  echo
  echo "[git] Comitando alteração…"
  git add "$TARGET"
  git commit -m "chore(checklist): normaliza bloco 9) Resumo (dedup tolerante a espaços + guarda única segura)"
fi

echo
echo "[fim] Concluído."
