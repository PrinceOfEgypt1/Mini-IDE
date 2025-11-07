# 29_strict_fix_server_imports.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Remover o warning "@typescript-eslint/consistent-type-imports" no server
#   - Garante que FastifyInstance seja importado via `import type { FastifyInstance }`
#   - Rebuild + lint + test do pacote @mini-ide/server
# Idempotente: pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
FILE="$SRV/src/index.ts"

echo "== MINI-IDE :: 29_strict_fix_server_imports =="

test -f "$FILE" || { echo "erro: não encontrei $FILE"; exit 1; }

# 1) Normaliza o import principal de fastify para NÃO incluir FastifyInstance
#    - Transforma:  import Fastify, { FastifyInstance, X, Y } from 'fastify'
#    - Em:          import Fastify, { X, Y } from 'fastify'
#    - Ou, se só havia FastifyInstance, vira: import Fastify from 'fastify'
awk '
  BEGIN { OFS=FS }
  {
    if ($0 ~ /^import[[:space:]]+Fastify[[:space:]]*,[[:space:]]*{[^}]*}.*from[[:space:]]+.\x27fastify\x27;/) {
      line=$0
      # remove FastifyInstance de dentro das chaves
      gsub(/FastifyInstance[[:space:]]*,?[[:space:]]*/,"",line)
      gsub(/[[:space:]]*,?[[:space:]]*FastifyInstance/,"",line)
      # se chaves ficarem vazias, remove a parte ", { }"
      gsub(/,[[:space:]]*{[[:space:]]*}/,"",line)
      print line
      next
    }
    if ($0 ~ /^import[[:space:]]+{[[:space:]]*FastifyInstance[[:space:]]*}.*from[[:space:]]+.\x27fastify\x27;/) {
      # esse import de valor será substituído por import type mais abaixo; então descartamos
      next
    }
    print
  }
' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"

# 2) Garante a presença de "import type { FastifyInstance } from 'fastify';" após o import Fastify
if ! grep -qE "^import[[:space:]]+type[[:space:]]+{[^}]*FastifyInstance[^}]*}[[:space:]]+from[[:space:]]+'\x?fastify\x?';" "$FILE"; then
  awk '
    {
      print $0
      if ($0 ~ /^import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+.\x27fastify\x27;/) {
        print "import type { FastifyInstance } from \x27fastify\x27;"
      }
    }
  ' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"
fi

# 3) Build + Lint + Test do pacote server
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run lint
pnpm -F @mini-ide/server run test

echo "== OK :: warning de consistent-type-imports sanado no server =="
