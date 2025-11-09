#!/usr/bin/env bash
# scripts/18-fix-grep-guard.sh
#
# Objetivo: corrigir o aviso do grep ("Unmatched ) or \)") na guarda do bloco
#           "9) Resumo" em 42_pipeline_checklist.sh, tornando a busca literal e resiliente.
#
# O que faz:
#   - Detecta a raiz do repositório via `git rev-parse`.
#   - Aplica patch cirúrgico, trocando a linha de guarda problemática por:
#       COUNT_RESUMO="$(grep -cF '# ---------- 9) Resumo ----------' '42_pipeline_checklist.sh' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then
#   - Opcionalmente, cria commit automático.
#
# Uso:
#   bash scripts/18-fix-grep-guard.sh           # dry-run (mostra plano, não altera)
#   bash scripts/18-fix-grep-guard.sh --run     # aplica o patch
#   bash scripts/18-fix-grep-guard.sh --run --commit   # aplica e comita
#
# Onde executar: de QUALQUER diretório dentro do repo (auto-detecta a raiz).
#
# Pré-requisitos: bash, git, awk, grep, sed
# Efeitos colaterais: altera 42_pipeline_checklist.sh; com --commit, cria um commit.

set -euo pipefail

# Flags
DO_RUN=0
DO_COMMIT=0
for arg in "$@"; do
  case "$arg" in
    --run) DO_RUN=1 ;;
    --commit) DO_COMMIT=1 ;;
    *) echo "[info] ignorando argumento desconhecido: $arg" ;;
  esac
done

# Descobrir raiz do repo
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "[erro] Não estou dentro de um repositório git." >&2
  exit 1
fi
cd "${REPO_ROOT}"

TARGET="42_pipeline_checklist.sh"
if [[ ! -f "${TARGET}" ]]; then
  echo "[erro] Arquivo não encontrado: ${TARGET} (rode em um clone com esse arquivo na raiz)" >&2
  exit 1
fi

# Verificar se já está corrigido
if grep -q 'COUNT_RESUMO=' "${TARGET}"; then
  echo "[ok] Já está corrigido (COUNT_RESUMO encontrado em ${TARGET})."
  if [[ "${DO_RUN}" -eq 1 && "${DO_COMMIT}" -eq 1 ]]; then
    git add "${TARGET}" || true
    git commit -m "chore(checklist): guarda resiliente do bloco 9) Resumo (grep -cF + fallback)" || true
    echo "[ok] Commit criado."
  fi
  exit 0
fi

# Plano
echo "== Plano =="
echo "Arquivo: ${REPO_ROOT}/${TARGET}"
echo "Ação: substituir linha da guarda que usa 'grep -c' com regex por versão literal e resiliente"
echo

if [[ "${DO_RUN}" -eq 0 ]]; then
  echo "[dry-run] Nada foi alterado. Execute com --run para aplicar."
  exit 0
fi

# Substituição robusta: identifica a linha com 'grep -c' + '9) Resumo' + referência ao arquivo e troca por linha segura.
replacement='COUNT_RESUMO="$(grep -cF '\''# ---------- 9) Resumo ----------'\'' '\''42_pipeline_checklist.sh'\'' || echo 0)"; if [ "${COUNT_RESUMO:-0}" -gt 1 ]; then'
awk -v repl="$replacement" '
  {
    if ($0 ~ /grep -c/ && $0 ~ /9\) Resumo/ && $0 ~ /42_pipeline_checklist\.sh/) {
      print repl
    } else {
      print
    }
  }
' "${TARGET}" > "${TARGET}.tmp"

# Conferir se houve mudança
if cmp -s "${TARGET}" "${TARGET}.tmp"; then
  rm -f "${TARGET}.tmp"
  echo "[info] Nenhuma linha correspondente encontrada para patch. Talvez já esteja corrigido ou o padrão é diferente."
  exit 0
fi

mv "${TARGET}.tmp" "${TARGET}"
echo "[ok] Patch aplicado em ${TARGET}."

# Commit opcional
if [[ "${DO_COMMIT}" -eq 1 ]]; then
  git add "${TARGET}"
  git commit -m "chore(checklist): corrige guarda do bloco 9) Resumo usando grep -cF e fallback resiliente"
  echo "[ok] Commit criado."
fi

# Smoke opcional: rodar checklist rapidamente (sem falhar o script se der problema)
if command -v bash >/dev/null 2>&1; then
  echo "[info] Rodando checklist para validação rápida…"
  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh || true
fi

echo "[ok] Finalizado."
