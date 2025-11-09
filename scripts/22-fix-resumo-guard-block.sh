#!/usr/bin/env bash
# scripts/22-fix-resumo-guard-block.sh
#
# Correção definitiva da guarda do bloco "9) Resumo" em 42_pipeline_checklist.sh.
# - Remove o bloco antigo completo: if [ "$(grep -c "^# ---------- 9\) Resumo ----------$" ... )" -gt 1 ]; then ... fi
# - Remove qualquer COUNT_RESUMO antigo
# - Injeta uma guarda segura em 1 linha logo após o cabeçalho do bloco 9) Resumo
#
# Uso:
#   bash scripts/22-fix-resumo-guard-block.sh           # dry-run (não altera arquivo)
#   bash scripts/22-fix-resumo-guard-block.sh --run     # aplica correção
#   bash scripts/22-fix-resumo-guard-block.sh --run --commit
#
# Pré-requisitos: bash, git, awk, sed, grep

set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for a in "${@:-}"; do
  case "$a" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) echo "[info] argumento ignorado: $a" ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "${REPO_ROOT:-}" ]; then
  echo "[erro] não estou dentro de um repositório git." >&2
  exit 1
fi
cd "$REPO_ROOT"

TARGET="42_pipeline_checklist.sh"
if [ ! -f "$TARGET" ]; then
  echo "[erro] arquivo não encontrado na raiz: $TARGET" >&2
  exit 1
fi

HEADER_RX='^# ---------- 9\) Resumo ----------$'
OLD_IF_RX='^\s*if \[ "\$\(grep -c "\^# ---------- 9\\\) Resumo ----------\$" "42_pipeline_checklist\.sh"\)" -gt 1 \]; then\s*$'
SAFE_LINE='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then echo "[erro] Bloco 9) Resumo duplicado em 42_pipeline_checklist.sh" >&2; exit 1; fi'

echo "== Plano =="
echo "Raiz: $REPO_ROOT"
echo "Alvo: $TARGET"
echo "Ação: remover bloco antigo if..fi e COUNT_RESUMO antigos; injetar guarda segura em 1 linha após o cabeçalho."
echo

if [ "$DO_RUN" -eq 0 ]; then
  echo "[dry-run] Linhas relevantes:"
  grep -nE "$HEADER_RX" "$TARGET" || true
  grep -nE "$OLD_IF_RX" "$TARGET" || true
  grep -n '^COUNT_RESUMO=' "$TARGET" || true
  exit 0
fi

TMP="$TARGET.tmp.$$"

# 1) Remover bloco antigo if..fi e qualquer COUNT_RESUMO antigo
awk -v old_if_rx="$OLD_IF_RX" '
  function starts_old_if(line) {
    return (line ~ old_if_rx)
  }
  BEGIN { in_old=0 }
  {
    if (in_old==1) {
      # Consumir até encontrar um "fi" sozinho na linha (típico do bloco simples)
      if ($0 ~ /^[[:space:]]*fi[[:space:]]*$/) {
        in_old=0
      }
      next
    }
    if (starts_old_if($0)) {
      in_old=1
      next
    }
    # Drop de qualquer COUNT_RESUMO antigo
    if ($0 ~ /^COUNT_RESUMO=/) next

    print
  }
' "$TARGET" > "$TMP"

mv "$TMP" "$TARGET"

# 2) Injetar a guarda segura em 1 linha logo após o cabeçalho, se ainda não existir
if ! grep -q '^COUNT_RESUMO=' "$TARGET"; then
  if grep -qxE "$HEADER_RX" "$TARGET"; then
    awk -v header_rx="$HEADER_RX" -v safe_line="$SAFE_LINE" '
      BEGIN { injected=0 }
      {
        print
        if ($0 ~ header_rx && injected==0) {
          print safe_line
          injected=1
        }
      }
      END {
        if (injected==0) {
          # não injeta se não encontrou o header
          # (não acontece pq já checamos acima, mas fica por segurança)
          exit 2
        }
      }
    ' "$TARGET" > "$TMP" && mv "$TMP" "$TARGET"
    echo "[ok] guarda segura injetada."
  else
    echo "[erro] cabeçalho do bloco 9) Resumo não encontrado. Abortando para evitar inserção errada." >&2
    exit 1
  fi
else
  echo "[info] guarda já presente (COUNT_RESUMO=)."
fi

# 3) Sanitizar: garantir newline final
tail -c1 "$TARGET" | read -r _ || echo >> "$TARGET"

# 4) Commit opcional
if [ "$DO_COMMIT" -eq 1 ]; then
  git add "$TARGET"
  git commit -m "chore(checklist): substitui bloco antigo da guarda 9) Resumo por versão segura (grep -cF) e injeta em 1 linha"
  echo "[ok] commit criado."
fi

echo "[info] validação rápida:"
grep -nE "$HEADER_RX" "$TARGET" || true
grep -n '^COUNT_RESUMO=' "$TARGET" || { echo "[erro] guarda não encontrada após header." >&2; exit 1; }

echo "[info] executando checklist (não falha este script se o checklist falhar)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "[ok] finalizado."
