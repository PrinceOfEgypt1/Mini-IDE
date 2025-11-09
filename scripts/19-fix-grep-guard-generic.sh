#!/usr/bin/env bash
# scripts/19-fix-grep-guard-generic.sh
#
# Objetivo:
#   Corrigir/garantir a guarda do bloco "9) Resumo" em 42_pipeline_checklist.sh, evitando
#   o warning "grep: Unmatched ) or \)". O script funciona de QUALQUER diretório do repo.
#
# O que faz:
#   1) Detecta a raiz do repositório via git.
#   2) Primeiro tenta substituir guardas antigas baseadas em `grep -c` (+ regex).
#   3) Se nada for substituído, injeta uma guarda resiliente logo APÓS a linha do cabeçalho:
#        # ---------- 9) Resumo ----------
#      (a guarda só é injetada se não existir COUNT_RESUMO no arquivo)
#   4) (--commit) adiciona e comita a alteração.
#
# Uso:
#   bash scripts/19-fix-grep-guard-generic.sh           # dry-run (mostra plano)
#   bash scripts/19-fix-grep-guard-generic.sh --run     # aplica alterações
#   bash scripts/19-fix-grep-guard-generic.sh --run --commit  # aplica e comita
#
# Onde executar:
#   De QUALQUER pasta dentro do repo.
#
# Requisitos: bash, git, awk, sed, grep
# Efeitos colaterais: edita 42_pipeline_checklist.sh; com --commit, cria um commit.

set -euo pipefail

DO_RUN=0
DO_COMMIT=0
for arg in "$@"; do
  case "$arg" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) echo "[info] ignorando argumento desconhecido: $arg" ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "[erro] Não estou dentro de um repositório git." >&2
  exit 1
fi
cd "${REPO_ROOT}"

TARGET="42_pipeline_checklist.sh"
if [[ ! -f "${TARGET}" ]]; then
  echo "[erro] Arquivo não encontrado na raiz: ${TARGET}" >&2
  exit 1
fi

SAFE_GUARD='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then'

echo "== Plano =="
echo "Raiz: ${REPO_ROOT}"
echo "Arquivo: ${TARGET}"
echo "Ação: substituir guardas antigas (grep -c com regex) por guarda resiliente; se não houver, injetar após o cabeçalho do bloco."
echo

if [[ "${DO_RUN}" -eq 0 ]]; then
  echo "[dry-run] Mostrando trechos relevantes:"
  echo "---- cabeçalho do bloco 9) ----"
  grep -n '^# ---------- 9) Resumo ----------$' "${TARGET}" || echo "(cabeçalho não encontrado)"
  echo "---- linhas com 'grep -c' ----"
  grep -n 'grep -c' "${TARGET}" || echo "(nenhuma grep -c encontrada)"
  exit 0
fi

# 1) Se já houver COUNT_RESUMO, não faça nada (idempotente)
if grep -q 'COUNT_RESUMO=' "${TARGET}"; then
  echo "[ok] Guarda já presente (COUNT_RESUMO=). Nada a fazer."
  if [[ "${DO_COMMIT}" -eq 1 ]]; then
    git add "${TARGET}" || true
    git commit -m "chore(checklist): mantém guarda resiliente do bloco 9) Resumo" || true
    echo "[ok] Commit criado (mantendo idempotência)."
  fi
  exit 0
fi

# 2) Tenta substituir alguma guarda antiga que use grep -c + referência a "9) Resumo" + arquivo
TMP="${TARGET}.tmp.$$"
awk -v repl="$SAFE_GUARD" '
  {
    # condição ampla: linhas que contenham "grep -c", "9) Resumo" e "42_pipeline_checklist.sh"
    if ($0 ~ /grep -c/ && $0 ~ /9\) Resumo/ && $0 ~ /42_pipeline_checklist\.sh/) {
      print repl
    } else {
      print
    }
  }
' "${TARGET}" > "${TMP}"

if ! cmp -s "${TARGET}" "${TMP}"; then
  mv "${TMP}" "${TARGET}"
  echo "[ok] Substituição aplicada em guarda antiga."
else
  rm -f "${TMP}"
  echo "[info] Nenhuma guarda antiga detectada para substituição."
  echo "[info] Tentando INJETAR guarda segura logo após o cabeçalho do bloco 9) Resumo…"

  # 3) Injetar a guarda após o cabeçalho do bloco 9) Resumo
  if ! grep -qx '^# ---------- 9) Resumo ----------$' "${TARGET}"; then
    echo "[erro] Cabeçalho do bloco 9) Resumo não encontrado. Abortando para evitar inserção incorreta." >&2
    exit 1
  fi

  awk -v header='^# ---------- 9) Resumo ----------$' -v insertLine="$SAFE_GUARD" '
    BEGIN { injected=0 }
    {
      print
      if ($0 ~ header && injected==0) {
        print insertLine
        injected=1
      }
    }
    END {
      if (injected==0) {
        exit 2
      }
    }
  ' "${TARGET}" > "${TARGET}.tmp2" || {
    echo "[erro] Falha ao injetar guarda após cabeçalho." >&2
    rm -f "${TARGET}.tmp2"
    exit 1
  }

  mv "${TARGET}.tmp2" "${TARGET}"
  echo "[ok] Guarda injetada após o cabeçalho do bloco 9) Resumo."
fi

# 4) Commit opcional
if [[ "${DO_COMMIT}" -eq 1 ]]; then
  git add "${TARGET}"
  git commit -m "chore(checklist): guarda resiliente do bloco 9) Resumo (grep -cF + fallback; substituição/injeção automática)"
  echo "[ok] Commit criado."
fi

# 5) Validação opcional
echo "[info] Validando presença da guarda…"
grep -n 'COUNT_RESUMO=' "${TARGET}" || { echo "[erro] Guarda não encontrada após operação." >&2; exit 1; }

echo "[info] Rodando checklist rapidamente (não falha o script se der erro no checklist)…"
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true

echo "[ok] Finalizado."
