#!/usr/bin/env bash
# scripts/20-fix-grep-guard-final.sh
#
# Objetivo:
#   Corrigir definitivamente a guarda do bloco "9) Resumo" em 42_pipeline_checklist.sh,
#   eliminando o aviso do grep e o erro "unexpected end of file".
#
# O que faz:
#   1) Detecta a raiz do repo (pode rodar de qualquer pasta).
#   2) Constrói uma guarda segura, em linha única:
#        COUNT_RESUMO="$(grep -cF '# ---------- 9) Resumo ----------' '42_pipeline_checklist.sh' || echo 0)"; \
#        if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "..."; exit 1; fi
#   3) Substitui:
#       - a guarda antiga (linha com grep -c + regex)
#       - qualquer linha parcial "COUNT_RESUMO=..." que tenha ficado sem `fi`
#   4) Faz commit opcional com --commit.
#
# Uso:
#   bash scripts/20-fix-grep-guard-final.sh           # dry-run (mostra o plano)
#   bash scripts/20-fix-grep-guard-final.sh --run     # aplica
#   bash scripts/20-fix-grep-guard-final.sh --run --commit
#
# Requisitos: bash, grep, sed, git
set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for arg in "$@"; do
  case "$arg" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) echo "[info] argumento ignorado: $arg" ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "[erro] não estou em um repositório git." >&2
  exit 1
fi
cd "$REPO_ROOT"

TARGET="42_pipeline_checklist.sh"
if [[ ! -f "$TARGET" ]]; then
  echo "[erro] arquivo não encontrado na raiz: $TARGET" >&2
  exit 1
fi

SAFE="COUNT_RESUMO=\"\$(grep -cF '# ---------- 9) Resumo ----------' '42_pipeline_checklist.sh' || echo 0)\"; if [ \"\${COUNT_RESUMO:-0}\" -gt 1 ]; then echo \"[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh\" >&2; exit 1; fi"

echo "== Plano =="
echo "Raiz: $REPO_ROOT"
echo "Arquivo: $TARGET"
echo "Ação: substituir guarda antiga e qualquer linha parcial por guarda segura em 1 linha."
echo

if [[ "$DO_RUN" -eq 0 ]]; then
  echo "[dry-run] Linhas relevantes:"
  nl -ba "$TARGET" | sed -n '1,40p' | grep -n "grep -c" || true
  grep -n "COUNT_RESUMO=" "$TARGET" || echo "(sem COUNT_RESUMO por enquanto)"
  exit 0
fi

# 1) Substitui a guarda antiga (aquela com grep -c + regex na MESMA linha do if)
#    Padrão aproximado para atingir a linha problemática em qualquer variação razoável:
sed -i \
  -e "s|^if \[ \"\$(grep -c \"\^# ---------- 9\\) Resumo ----------\$\" \"42_pipeline_checklist\.sh\")\" -gt 1 \]; then\$|$SAFE|g" \
  "$TARGET"

# 2) Substitui qualquer linha parcial já injetada que comece com COUNT_RESUMO= por uma linha segura completa
sed -i \
  -e "s|^COUNT_RESUMO=.*|$SAFE|g" \
  "$TARGET"

# 3) Verificação rápida: a guarda precisa existir exatamente uma vez
COUNT_LINES="$(grep -c '^COUNT_RESUMO=' "$TARGET" || echo 0)"
if [[ "${COUNT_LINES:-0}" -eq 0 ]]; then
  # Tenta inserir logo após o cabeçalho do bloco 9)
  if grep -qx '^# ---------- 9) Resumo ----------$' "$TARGET"; then
    awk -v header='^# ---------- 9) Resumo ----------$' -v guard="$SAFE" '
      BEGIN { injected=0 }
      {
        print
        if ($0 ~ header && injected==0) {
          print guard
          injected=1
        }
      }
      END { if (injected==0) exit 2 }
    ' "$TARGET" > "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET" || {
      echo "[erro] falha ao injetar guarda após o cabeçalho." >&2
      exit 1
    }
  else
    echo "[erro] cabeçalho do bloco 9) não encontrado; abortando para evitar inserção incorreta." >&2
    exit 1
  fi
elif [[ "${COUNT_LINES:-0}" -gt 1 ]]; then
  echo "[warn] múltiplas guardas detectadas (${COUNT_LINES}). Mantendo a primeira e removendo as demais…"
  # Mantém a primeira ocorrência e remove as seguintes
  awk '
    BEGIN { seen=0 }
    {
      if ($0 ~ /^COUNT_RESUMO=/) {
        seen++
        if (seen==1) print
      } else {
        print
      }
    }
  ' "$TARGET" > "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET"
fi

# 4) Commit opcional
if [[ "$DO_COMMIT" -eq 1 ]]; then
  git add "$TARGET"
  git commit -m "chore(checklist): normaliza guarda do bloco 9) Resumo (uma linha segura, grep -cF + echo/exit/fi)"
  echo "[ok] commit criado."
fi

echo "[info] validação rápida:"
grep -n '^COUNT_RESUMO=' "$TARGET" || { echo "[erro] guarda não encontrada após operação." >&2; exit 1; }

echo "[info] rodada de checklist (não falha este script se checklist errar)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "[ok] finalizado."
