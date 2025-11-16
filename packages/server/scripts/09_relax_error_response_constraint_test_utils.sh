#!/usr/bin/env bash
set -euo pipefail

echo "== MINI-IDE :: Ajustar constraint genérica em test-utils.ts (ErrorResponse) =="

# Ir para a raiz do repositório (dois níveis acima da pasta scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TARGET_FILE="packages/server/test/test-utils.ts"

if [[ -f "$TARGET_FILE" ]]; then
  echo "[INFO] Arquivo encontrado: $TARGET_FILE"

  # Backup antes de qualquer alteração
  if [[ ! -f "${TARGET_FILE}.bak.before_relax_constraint" ]]; then
    cp "$TARGET_FILE" "${TARGET_FILE}.bak.before_relax_constraint"
    echo "[INFO] Backup criado: ${TARGET_FILE}.bak.before_relax_constraint"
  else
    echo "[WARN] Backup já existe: ${TARGET_FILE}.bak.before_relax_constraint (não será sobrescrito)"
  fi

  # Substituir qualquer 'extends Record<string, unknown>' por 'extends object'
  if grep -q 'extends Record<string, unknown>' "$TARGET_FILE"; then
    sed -i 's/extends Record<string, unknown>/extends object/g' "$TARGET_FILE"
    echo "[OK] Constraint atualizada em: $TARGET_FILE"
  else
    echo "[WARN] Padrão 'extends Record<string, unknown>' não encontrado em: $TARGET_FILE (nada alterado)"
  fi
else
  echo "[ERRO] Arquivo não encontrado: $TARGET_FILE"
  exit 1
fi

echo
echo "== MINI-IDE :: Rodando typecheck após ajuste =="

if command -v pnpm >/dev/null 2>&1; then
  pnpm typecheck
else
  echo "[ERRO] pnpm não encontrado no PATH. Instale ou ajuste o ambiente antes de rodar o typecheck."
  exit 1
fi

echo
echo "== MINI-IDE :: Concluído. Verifique se o typecheck ficou verde. =="
