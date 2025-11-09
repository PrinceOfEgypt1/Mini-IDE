#!/usr/bin/env bash
# scripts/26-normalize-resumo-block.sh
# Normaliza o bloco "9) Resumo" em 42_pipeline_checklist.sh:
# - Remove guardas antigas (grep -c com regex) e o 'fi' correspondente
# - Remove quaisquer linhas COUNT_RESUMO= fora do lugar
# - Deduplica o header "# ---------- 9) Resumo ----------" (mantém a 1ª)
# - Injeta UMA guarda segura logo após o primeiro header
# - Valida resultado no final
#
# Execução: a partir da RAIZ do repo (ex.: ~/workspace/Mini-IDE)
#   chmod +x scripts/26-normalize-resumo-block.sh
#   bash scripts/26-normalize-resumo-block.sh --run   # aplica
#   bash scripts/26-normalize-resumo-block.sh         # apenas dry-run
#
# Saída: não deixa .bak permanente; usa tmp e substitui atomicamente.

set -euo pipefail

ROOT_DIR="$(pwd)"
TARGET="42_pipeline_checklist.sh"

if [ ! -f "$TARGET" ]; then
  echo "[erro] Arquivo não encontrado: $TARGET (rode na raiz do repo)" >&2
  exit 1
fi

RUN=0
if [ "${1:-}" = "--run" ]; then
  RUN=1
fi

HEADER_LINE="# ---------- 9) Resumo ----------"
# Linha exata da guarda segura que queremos manter (literal, sem regex):
SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Raiz: $ROOT_DIR"
echo "Alvo: $TARGET"
echo "Ações:"
echo "  • Remover guarda antiga (linha com grep -c regex) e seu 'fi'"
echo "  • Remover quaisquer linhas COUNT_RESUMO= fora do lugar"
echo "  • Deduplicar cabeçalho \"$HEADER_LINE\" (manter só a 1ª ocorrência)"
echo "  • Injetar UMA guarda segura imediatamente após o 1º cabeçalho"
echo

# 1) Ver diagnóstico atual
echo "[diag] Cabeçalhos atuais:"
nl -ba "$TARGET" | grep -n -F "$HEADER_LINE" || true
echo
echo "[diag] Guard antigo (if … grep -c …):"
# Procuramos literalmente o padrão problemático do passado
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

# 2) Reescrever o arquivo linha a linha com uma pequena máquina de estados
# Regras:
# - skip_until_fi: ao encontrar a guarda antiga (linha que contém o grep -c regex),
#   ignoramos todas as linhas até encontrar um 'fi' (que também será descartado)
# - seen_header: já vimos a 1ª ocorrência do header
# - injected_guard: já injetamos a guarda segura após o 1º header
# - descartamos qualquer linha que contenha "COUNT_RESUMO=" (guardas antigas/espalhadas)
#
# Observação: usamos só match literal (index() no awk) para evitar problemas de regex.

awk -v HEADER="$HEADER_LINE" -v SAFE="$SAFE_GUARD" '
BEGIN {
  skip_until_fi=0
  seen_header=0
  injected_guard=0
}
{
  line=$0

  # Se estamos pulando até fi (vimos uma guarda antiga if ...)
  if (skip_until_fi==1) {
    # descartamos linhas até achar um "fi" isolado (permitindo espaços)
    trimmed=line
    gsub(/^[ \t]+|[ \t]+$/, "", trimmed)
    if (trimmed=="fi") {
      skip_until_fi=0
    }
    next
  }

  # 2.1) Detecta a linha exata da guarda antiga (com regex no source)
  if (index(line, "grep -c \"^# ---------- 9\\) Resumo ----------$\"")>0) {
    # Ignora esta linha e ativa pular até fi
    skip_until_fi=1
    next
  }

  # 2.2) Remove qualquer linha que contenha COUNT_RESUMO=
  if (index(line, "COUNT_RESUMO=")>0) {
    next
  }

  # 2.3) Controla deduplicação do header
  if (line==HEADER) {
    if (seen_header==0) {
      print line
      seen_header=1
      # Injeta guarda segura como próxima linha
      print SAFE
      injected_guard=1
    }
    # Se já vimos header antes, ignoramos headers duplicados
    next
  }

  # Linha comum -> preserva
  print line
}
END {
  # Nada extra a fazer aqui
}
' "$TARGET" > "$TMP"

# Substitui o arquivo original de forma atômica
mv "$TMP" "$TARGET"
trap - EXIT

# 3) Validações simples (pré-checklist)
HEADERS_COUNT="$(grep -cF "$HEADER_LINE" "$TARGET" || echo 0)"
GUARD_COUNT="$(grep -cF "$SAFE_GUARD" "$TARGET" || echo 0)"

echo
echo "[validação] headers=\"$HEADERS_COUNT\" guardas=\"$GUARD_COUNT\" (esperado: 1 header, 1 guarda)"
if [ "${HEADERS_COUNT:-0}" -ne 1 ] || [ "${GUARD_COUNT:-0}" -ne 1 ]; then
  echo "[erro] Normalização não atingiu o estado esperado (1 header / 1 guarda). Verifique manualmente."
  exit 1
fi

echo "[ok] Normalização aplicada com sucesso."

# 4) Executa checklist rapidamente (não falha o script se o checklist falhar — apenas reporta)
echo
echo "[info] Rodando checklist (quick) para verificação…"
set +e
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
CHECK_RC=$?
set -e
if [ "$CHECK_RC" -ne 0 ]; then
  echo "[warn] Checklist retornou código $CHECK_RC. Verifique o output acima."
else
  echo "[ok] Checklist finalizou com sucesso."
fi

echo
echo "[fim] Concluído."
