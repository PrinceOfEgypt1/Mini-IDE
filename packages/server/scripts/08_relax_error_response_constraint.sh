#!/usr/bin/env bash
set -euo pipefail

echo "== MINI-IDE :: Ajustar constraint genérica em testes de erro do server =="

# Vai para a raiz do repo (dois níveis acima de packages/server/scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TARGET_FILES=(
  "packages/server/test/analyze-400.spec.ts"
  "packages/server/test/analyze-500.spec.ts"
)

for file in "${TARGET_FILES[@]}"; do
  if [[ -f "$file" ]]; then
    echo "[INFO] Atualizando constraint genérica em: $file"

    # Backup antes de mexer
    if [[ ! -f "${file}.bak.before_relax_constraint" ]]; then
      cp "$file" "${file}.bak.before_relax_constraint"
      echo "[INFO] Backup criado: ${file}.bak.before_relax_constraint"
    else
      echo "[WARN] Backup já existe: ${file}.bak.before_relax_constraint (não será sobrescrito)"
    fi

    # Substitui T extends Record<string, unknown> por T extends object
    # (apenas se o padrão existir)
    if grep -q 'T extends Record<string, unknown>' "$file"; then
      sed -i 's/T extends Record<string, unknown>/T extends object/g' "$file"
      echo "[OK] Constraint atualizada em: $file"
    else
      echo "[WARN] Padrão 'T extends Record<string, unknown>' não encontrado em: $file (nada alterado)"
    fi
  else
    echo "[WARN] Arquivo não encontrado: $file (ignorando)"
  fi
done

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
