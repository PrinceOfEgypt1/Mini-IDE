#!/usr/bin/env bash
# scripts/21-fix-grep-guard-final2.sh
#
# Corrige definitivamente a guarda do bloco "9) Resumo" em 42_pipeline_checklist.sh,
# evitando o aviso do grep e o erro "syntax error: unexpected end of file".
#
# Uso:
#   bash scripts/21-fix-grep-guard-final2.sh           # dry-run (mostra plano)
#   bash scripts/21-fix-grep-guard-final2.sh --run     # aplica
#   bash scripts/21-fix-grep-guard-final2.sh --run --commit
#
# Requisitos: bash, awk, git

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
if [[ -z "$REPO_ROOT" ]]; then
  echo "[erro] não estou em um repositório git." >&2
  exit 1
fi
cd "$REPO_ROOT"

TARGET="42_pipeline_checklist.sh"
if [[ ! -f "$TARGET" ]]; then
  echo "[erro] arquivo não encontrado na raiz: $TARGET" >&2
  exit 1
fi

SAFE='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Raiz: $REPO_ROOT"
echo "Arquivo: $TARGET"
echo "Ação: substituir guarda antiga/linhas parciais por guarda segura em 1 linha; injetar se faltar."
echo

if [[ $DO_RUN -eq 0 ]]; then
  echo "[dry-run] Linhas relevantes:"
  # linha antiga com grep -c + regex (procura por '9\) Resumo')
  nl -ba "$TARGET" | awk '/grep -c "\^# ---------- 9\\) Resumo ----------\$"/ {print}'
  # linhas com COUNT_RESUMO
  grep -n '^COUNT_RESUMO=' "$TARGET" || echo "(sem COUNT_RESUMO)"
  # cabeçalho do bloco
  grep -n '^# ---------- 9) Resumo ----------$' "$TARGET" || echo "(sem cabeçalho do bloco 9))"
  exit 0
fi

TMP="${TARGET}.tmp.$$"

# 1) Primeira passagem: substitui
#    - a linha antiga que contém grep -c "^# ---------- 9\) Resumo ----------$"
#    - qualquer linha começando por COUNT_RESUMO=
awk -v safe="$SAFE" '
  BEGIN { replaced_old=0; replaced_count=0 }
  {
    if ($0 ~ /grep -c "\^# ---------- 9\\) Resumo ----------\$"/) {
      print safe
      replaced_old++
    } else if ($0 ~ /^COUNT_RESUMO=/) {
      print safe
      replaced_count++
    } else {
      print
    }
  }
  END {
    # report via stderr so não polui arquivo final
    if (replaced_old>0) fprintf(stderr, "[info] substituídas %d linha(s) de guarda antiga.\n", replaced_old)
    if (replaced_count>0) fprintf(stderr, "[info] normalizadas %d linha(s) COUNT_RESUMO.\n", replaced_count)
  }
' "$TARGET" > "$TMP"

mv "$TMP" "$TARGET"

# 2) Verifica se ficou ao menos uma guarda
COUNT_GUARDAS="$(grep -c '^COUNT_RESUMO=' "$TARGET" || echo 0)"
if [[ "${COUNT_GUARDAS:-0}" -eq 0 ]]; then
  # Injeta após o cabeçalho do bloco 9)
  if grep -qx '^# ---------- 9) Resumo ----------$' "$TARGET"; then
    awk -v header='^# ---------- 9) Resumo ----------$' -v safe="$SAFE" '
      BEGIN { injected=0 }
      {
        print
        if ($0 ~ header && injected==0) {
          print safe
          injected=1
        }
      }
      END { if (injected==0) exit 2 }
    ' "$TARGET" > "$TMP" && mv "$TMP" "$TARGET" || {
      echo "[erro] falha ao injetar guarda após o cabeçalho do bloco 9)." >&2
      exit 1
    }
    echo "[info] guarda injetada após o cabeçalho do bloco 9)."
  else
    echo "[erro] cabeçalho do bloco 9) não encontrado; abortando para evitar inserção errada." >&2
    exit 1
  fi
elif [[ "${COUNT_GUARDAS:-0}" -gt 1 ]]; then
  echo "[warn] múltiplas guardas detectadas (${COUNT_GUARDAS}). Mantendo a primeira e removendo as demais…"
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
  ' "$TARGET" > "$TMP" && mv "$TMP" "$TARGET"
fi

# 3) Commit opcional
if [[ $DO_COMMIT -eq 1 ]]; then
  git add "$TARGET"
  git commit -m "chore(checklist): guarda do bloco 9) Resumo normalizada (grep -cF, echo/exit, fi) via awk"
  echo "[ok] commit criado."
fi

echo "[info] validação:"
grep -n '^COUNT_RESUMO=' "$TARGET" || { echo "[erro] guarda não encontrada." >&2; exit 1; }

echo "[info] rodando checklist (não falha este script se o checklist falhar)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "[ok] finalizado."
