#!/usr/bin/env bash
# scripts/01-diagnose-backup.sh
#
# Descrição: Diagnostica problema e faz backup dos arquivos atuais
# Uso: bash scripts/01-diagnose-backup.sh
# Pré-requisitos: bash
# Efeitos colaterais: Cria backups em .bak

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "=== DIAGNÓSTICO - HU-Server-Analyze-200 ==="
echo ""
echo "[info] Project root: ${PROJECT_ROOT}"

# 1. Verificar arquivos críticos
echo ""
echo "[1] Verificando arquivos críticos..."

FILES=(
  "packages/server/src/index.ts"
  "packages/server/test/healthz.spec.ts"
  "packages/server/test/analyze.spec.ts"
)

for file in "${FILES[@]}"; do
  if [[ -f "${file}" ]]; then
    echo "  ✓ ${file} existe"
    SIZE=$(wc -l < "${file}")
    echo "    Linhas: ${SIZE}"
  else
    echo "  ✗ ${file} NÃO existe"
  fi
done

# 2. Fazer backups
echo ""
echo "[2] Criando backups..."

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

for file in "${FILES[@]}"; do
  if [[ -f "${file}" ]]; then
    BACKUP_PATH="${BACKUP_DIR}/${file}"
    mkdir -p "$(dirname "${BACKUP_PATH}")"
    cp "${file}" "${BACKUP_PATH}"
    echo "  ✓ Backup: ${BACKUP_PATH}"
  fi
done

echo ""
echo "[ok] Diagnóstico completo. Backups em: ${BACKUP_DIR}"
echo ""
echo "Próximo passo: bash scripts/02-fix-index-ts.sh"
