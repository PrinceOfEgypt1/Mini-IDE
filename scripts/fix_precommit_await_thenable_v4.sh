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

# 0) Se o arquivo atual estiver quebrado para TypeScript/ESLint, tenta restaurar do último backup
try_restore_if_broken() {
  local last_bak
  set +e
  (cd "$SERVER_DIR" && pnpm exec eslint "$REL_FILE" >/dev/null 2>&1)
  local eslint_rc=$?
  set -e
  if [[ $eslint_rc -ne 0 ]]; then
    last_bak="$(ls -1t "${ABS_FILE}.bak.awaitfix."* 2>/dev/null | head -n1 || true)"
    if [[ -n "$last_bak" && -f "$last_bak" ]]; then
      echo "[warn] ESLint detectou erro de parsing; restaurando de ${last_bak}"
      cp -f "$last_bak" "$ABS_FILE"
    fi
  fi
}

try_restore_if_broken

# 1) Backup do estado atual
cp "$ABS_FILE" "$BACKUP"
echo "[ok] Backup criado: $BACKUP"

# 2) Remoção cirúrgica de 'await' apenas para helpers síncronos conhecidos
#    Ajuste a lista abaixo se existir outro helper síncrono com await indevido.
perl -0777 -i -pe 's/\bawait\s+(?=(status\s*\())//g' "$ABS_FILE"
perl -0777 -i -pe 's/\bawait\s+(?=(jsonUnknown\s*\())//g' "$ABS_FILE"

# 3) Validação com ESLint (no pacote server)
echo "[info] ESLint (server -> $REL_FILE)…"
(
  cd "$SERVER_DIR"
  pnpm exec eslint "$REL_FILE" --max-warnings=0
) || {
  echo "[fail] ESLint falhou; restaurando backup…"
  mv -f "$BACKUP" "$ABS_FILE"
  exit 1
}

# 4) Typecheck do pacote server
echo "[info] Typecheck (server)…"
(
  cd "$SERVER_DIR"
  pnpm exec tsc -p tsconfig.json --noEmit
) || {
  echo "[fail] Typecheck falhou; restaurando backup…"
  mv -f "$BACKUP" "$ABS_FILE"
  exit 1
}

echo "[ok] Patch aplicado e validado no pacote server 🎯"

# 5) Opcional: pipeline completo + commit
if [[ "${1:-}" == "--run-pipeline" ]]; then
  echo "[info] Executando pipeline completo + commit…"
  bash scripts/run_all_then_commit.sh "chore(server/tests): remover await não-thenable em helpers síncronos"
else
  echo "[tip] Para rodar o pipeline + commit:"
  echo "     bash scripts/run_all_then_commit.sh \"chore(server/tests): remover await não-thenable em helpers síncronos\""
fi
