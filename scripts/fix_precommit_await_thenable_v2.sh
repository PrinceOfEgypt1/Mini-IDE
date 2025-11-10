#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
SERVER_DIR="$ROOT_DIR/packages/server"
ABS_FILE="$SERVER_DIR/test/test-utils.ts"
REL_FILE="test/test-utils.ts" # relativo ao pacote server
BACKUP="${ABS_FILE}.bak.awaitfix.$(date +%Y%m%d%H%M%S)"

echo "[info] Alvo: $ABS_FILE"
[[ -f "$ABS_FILE" ]] || { echo "[fail] Arquivo não encontrado: $ABS_FILE"; exit 1; }

cp "$ABS_FILE" "$BACKUP"
echo "[ok] Backup criado: $BACKUP"

# -------- PATCH: await de valor síncrono -> await Promise.resolve(valor) --------
# 1) Padrão com ; ao final
perl -0777 -i -pe 's/\bawait\s+(?!Promise\.resolve\()\s*([^;\n]+)\s*;/await Promise.resolve(\1);/g' "$ABS_FILE"
# 2) Padrão sem ; (quebra de linha)
perl -0777 -i -pe 's/\bawait\s+(?!Promise\.resolve\()\s*([^\n]+)\n/await Promise.resolve(\1)\n/g' "$ABS_FILE"

# Opcional: limpa espaços duplicados triviais que possam surgir do patch
perl -0777 -i -pe 's/[ \t]+$/\n/g' "$ABS_FILE" 2>/dev/null || true

# -------- LINT: usar caminho relativo dentro do pacote --------
echo "[info] ESLint (server -> $REL_FILE, caminho relativo correto)…"
(
  cd "$SERVER_DIR"
  pnpm exec eslint "$REL_FILE" --max-warnings=0
) || {
  echo "[fail] ESLint falhou no arquivo $REL_FILE; restaurando backup…"
  mv "$BACKUP" "$ABS_FILE"
  exit 1
}

# -------- TYPECHECK: apenas o pacote server --------
echo "[info] Typecheck (server)…"
(
  cd "$SERVER_DIR"
  pnpm exec tsc -p tsconfig.json --noEmit
) || {
  echo "[fail] Typecheck falhou; restaurando backup…"
  mv "$BACKUP" "$ABS_FILE"
  exit 1
}

echo "[ok] Patch aplicado e validado no pacote server 🎯"

if [[ "${1:-}" == "--run-pipeline" ]]; then
  echo "[info] Executando pipeline completo + tentativa de commit…"
  bash scripts/run_all_then_commit.sh "chore(server/tests): corrigir await não-thenable em test-utils"
else
  echo ""
  echo "[tip] Para rodar tudo e commitar depois da correção:"
  echo "      bash scripts/run_all_then_commit.sh \"chore(server/tests): corrigir await não-thenable em test-utils\""
fi
