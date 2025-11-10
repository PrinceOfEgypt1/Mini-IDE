#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
SERVER_DIR="$ROOT_DIR/packages/server"
ABS_FILE="$SERVER_DIR/test/test-utils.ts"
REL_FILE="test/test-utils.ts"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
BACKUP="${ABS_FILE}.bak.awaitfix.${TIMESTAMP}"

echo "[info] Alvo: $ABS_FILE"
[[ -f "$ABS_FILE" ]] || { echo "[fail] Arquivo não encontrado: $ABS_FILE"; exit 1; }

# 0) Se a sintaxe estiver quebrada (como no log), tenta restaurar do último backup conhecido.
if ! bash -n "$ABS_FILE" 2>/dev/null; then
  LAST_BAK="$(ls -1t "${ABS_FILE}.bak.awaitfix."* 2>/dev/null | head -n1 || true)"
  if [[ -n "${LAST_BAK}" && -f "${LAST_BAK}" ]]; then
    echo "[warn] Sintaxe inválida detectada; restaurando de ${LAST_BAK}"
    cp -f "${LAST_BAK}" "$ABS_FILE"
  fi
fi

# 1) Backup sempre
cp "$ABS_FILE" "$BACKUP"
echo "[ok] Backup criado: $BACKUP"

# 2) Remoção cirúrgica de 'await' apenas em helpers síncronos conhecidos
#    - Mantém qualquer espaço já existente após 'await '
#    - Só atinge quando há 'await status(' ou 'await jsonUnknown('
perl -0777 -i -pe 's/\bawait\s+(?=(status\s*\())//g' "$ABS_FILE"
perl -0777 -i -pe 's/\bawait\s+(?=(jsonUnknown\s*\())//g' "$ABS_FILE"

# 3) Verifica sintaxe bash do arquivo-alvo (por segurança)
bash -n "$ABS_FILE" || {
  echo "[fail] Sintaxe inválida após patch; restaurando backup…"
  mv "$BACKUP" "$ABS_FILE"
  exit 1
}

# 4) ESLint e Typecheck no pacote server usando caminho relativo
echo "[info] ESLint (server -> $REL_FILE)…"
(
  cd "$SERVER_DIR"
  pnpm exec eslint "$REL_FILE" --max-warnings=0
) || {
  echo "[fail] ESLint falhou; restaurando backup…"
  mv "$BACKUP" "$ABS_FILE"
  exit 1
}

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

# 5) Opcional: roda o pipeline completo + commit
if [[ "${1:-}" == "--run-pipeline" ]]; then
  echo "[info] Executando pipeline completo + commit…"
  bash scripts/run_all_then_commit.sh "chore(server/tests): remover await não-thenable em helpers síncronos"
else
  echo "[tip] Para rodar o pipeline + commit:"
  echo "     bash scripts/run_all_then_commit.sh \"chore(server/tests): remover await não-thenable em helpers síncronos\""
fi
