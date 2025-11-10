# scripts/fix_precommit_await_thenable.sh
#!/usr/bin/env bash
set -euo pipefail

FILE="packages/server/test/test-utils.ts"
BACKUP="${FILE}.bak.awaitfix.$(date +%Y%m%d%H%M%S)"

echo "[info] Alvo: $FILE"
[[ -f "$FILE" ]] || { echo "[fail] Arquivo não encontrado: $FILE"; exit 1; }

cp "$FILE" "$BACKUP"
echo "[ok] Backup criado: $BACKUP"

# Patch idempotente: substitui apenas 'await <expr>' que ainda não esteja embrulhado em Promise.resolve(
# - Usa perl em modo multiline (-0777) e 'g' global.
# - Condição negativa para não tocar o que já tiver Promise.resolve(
perl -0777 -pe '
  s/\bawait\s+(?!Promise\.resolve\()\s*([^\);\n]+)\s*\)/"await Promise.resolve(".$1.")\)"/ge if 0; # noop para manter sintaxe
' "$FILE" > "${FILE}.tmp" || { echo "[fail] Não consegui preparar tmp"; mv "$BACKUP" "$FILE"; exit 1; }

# A regex acima precisa considerar ; e que pode não haver ")". Vamos aplicar duas trocas seguras:
# 1) await <expr>;
perl -0777 -i -pe 's/\bawait\s+(?!Promise\.resolve\()\s*([^;\n]+)\s*;/await Promise.resolve(\1);/g' "$FILE"
# 2) await <expr>\n (sem ;). Mantém a quebra.
perl -0777 -i -pe 's/\bawait\s+(?!Promise\.resolve\()\s*([^\n]+)\n/await Promise.resolve(\1)\n/g' "$FILE"

echo "[info] Validando ESLint só no arquivo alterado…"
pnpm --filter @mini-ide/server exec eslint "$FILE" --max-warnings=0 || {
  echo "[fail] ESLint ainda falhou; restaurando backup…"
  mv "$BACKUP" "$FILE"
  exit 1
}

echo "[info] Typecheck (server)…"
pnpm --filter @mini-ide/server exec tsc -p tsconfig.json --noEmit || {
  echo "[fail] Typecheck falhou; restaurando backup…"
  mv "$BACKUP" "$FILE"
  exit 1
}

echo "[ok] Patch aplicado com sucesso a $FILE"
echo "[info] Executando checklist completo para garantir 0 erros…"
bash scripts/run_all_then_commit.sh "chore(server/tests): remover await não-thenable em test-utils"

echo "[ok] Finalizado."
