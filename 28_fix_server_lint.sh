# 28_fix_server_lint.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo:
#   - Corrigir lints do @mini-ide/server:
#       1) @typescript-eslint/consistent-type-imports  → usar `import type { FastifyInstance }`
#       2) @typescript-eslint/require-await            → handlers sem await não devem ser async
#   - Preserva TSDoc e o restante do código.
#   - Valida com build + lint + test do pacote e mostra resumo do workspace.
# Idempotente: pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
FILE="$SRV/src/index.ts"

echo "== MINI-IDE :: 28_fix_server_lint =="

test -f "$FILE" || { echo "erro: não encontrei $FILE"; exit 1; }

# 1) Fix: consistent-type-imports → separar import de tipo
#    Caso típico atual: `import Fastify, { FastifyInstance } from 'fastify';`
#    Resultado:         `import Fastify from 'fastify';` + `import type { FastifyInstance } from 'fastify';`
if grep -qE '^import\s+Fastify,\s*{\s*FastifyInstance\s*}\s+from\s+..fastify.;' "$FILE"; then
  # Remove o named import e adiciona import type em seguida, se ainda não existir
  sed -i "s/^import\s\+Fastify,\s*{\s*FastifyInstance\s*}\s\+from\s\+'fastify';/import Fastify from 'fastify';/" "$FILE"
  if ! grep -qE "^import\s+type\s+{[^}]*FastifyInstance[^}]*}\s+from\s+'fastify';" "$FILE"; then
    # adiciona logo após a linha do import Fastify
    awk '{
      print $0
      if ($0 ~ /^import Fastify from .fastify.;/) {
        print "import type { FastifyInstance } from \x27fastify\x27;"
      }
    }' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"
  fi
else
  echo "[info] import de FastifyInstance já está como type ou em formato compatível."
fi

# 2) Fix: require-await → remover async de handlers que não usam await
#    healthz handler
sed -i "s/app\.get(\x27\/healthz\x27,\s*async\s*()\s*=>/app.get(\x27\/healthz\x27, () =>/" "$FILE"
#    analyze handler
sed -i "s/app\.post(\x27\/analyze\x27,\s*async\s*(request)\s*=>/app.post(\x27\/analyze\x27, (request) =>/" "$FILE"

# 3) Build + Lint + Test do pacote server
echo "[info] validando @mini-ide/server…"
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run lint
pnpm -F @mini-ide/server run test

# 4) (Opcional) Mostrar um resumo do workspace para garantir que nada mais quebrou
echo "[info] resumo do workspace (lint apenas):"
pnpm -r --workspace-concurrency=1 run lint || true

echo "== OK :: lints do server corrigidos (consistent-type-imports e require-await) =="
echo "Dica: se quiser rodar tudo amanhã: pnpm -r run build && pnpm -r run typecheck && pnpm -r run lint && pnpm -r run test"
