# 31_purge_fastify_imports.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Remover importações duplicadas de Fastify no @mini-ide/server/src/index.ts
#   - Garantir o padrão:
#         import Fastify from 'fastify';
#         import type { FastifyInstance } from 'fastify';
#   - Evitar qualquer outro import envolvendo FastifyInstance como valor
#   - Validar com build + lint (sem warnings) + test do pacote server
# Idempotente: seguro para rodar quantas vezes precisar.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
FILE="$SRV/src/index.ts"

echo "== MINI-IDE :: 31_purge_fastify_imports =="

test -f "$FILE" || { echo "erro: não encontrei $FILE"; exit 1; }

# 1) Remover QUALQUER linha que importe Fastify com FastifyInstance junto (valor)
#    Ex.: "import Fastify, { FastifyInstance } from 'fastify';"
#    Também remove "import { FastifyInstance } from 'fastify';" (valor)
awk '
  # Regra 1: remover linhas com "import Fastify, { ...FastifyInstance... } from '\''fastify'\'';"
  /^(import[[:space:]]+Fastify[[:space:]]*,[[:space:]]*{[^}]*FastifyInstance[^}]*}[[:space:]]*from[[:space:]]+['\''"]fastify['\''"]\s*;?\s*)$/ { next }
  # Regra 2: remover linhas só com "import { FastifyInstance } from '\''fastify'\'';"
  /^(import[[:space:]]+{[[:space:]]*FastifyInstance[[:space:]]*}[[:space:]]*from[[:space:]]+['\''"]fastify['\''"]\s*;?\s*)$/ { next }
  { print }
' "$FILE" > "$FILE.__step1__"

# 2) Garantir UMA única linha "import Fastify from 'fastify';"
#    - Se não existir, inserir antes do primeiro import
#    - Se existir mais de uma, manter a primeira e descartar as demais
if grep -qE "^[[:space:]]*import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+['\"]fastify['\"];[[:space:]]*$" "$FILE.__step1__"; then
  # Deduplicar mantendo a primeira ocorrência
  awk '
    BEGIN { seen=0 }
    {
      if ($0 ~ /^[[:space:]]*import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+['"'"'"]fastify['"'"'"];[[:space:]]*$/) {
        if (seen==1) next;
        seen=1;
      }
      print
    }
  ' "$FILE.__step1__" > "$FILE.__step2__"
else
  # Inserir imediatamente antes do primeiro import qualquer; se não houver import, no topo
  if grep -qE "^[[:space:]]*import[[:space:]]" "$FILE.__step1__"; then
    awk '
      BEGIN { inserted=0 }
      {
        if (inserted==0 && $0 ~ /^[[:space:]]*import[[:space:]]/) {
          print "import Fastify from '\''fastify'\'';"
          inserted=1
        }
        print
      }
      END {
        if (inserted==0) print "import Fastify from '\''fastify'\'';"
      }
    ' "$FILE.__step1__" > "$FILE.__step2__"
  else
    printf "import Fastify from '\''fastify'\'';\n" > "$FILE.__step2__"
    cat "$FILE.__step1__" >> "$FILE.__step2__"
  fi
fi

# 3) Garantir "import type { FastifyInstance } from 'fastify';" APÓS o import Fastify
if grep -qE "^[[:space:]]*import[[:space:]]+type[[:space:]]+{[[:space:]]*FastifyInstance[[:space:]]*}[[:space:]]+from[[:space:]]+['\"]fastify['\"];[[:space:]]*$" "$FILE.__step2__"; then
  cp "$FILE.__step2__" "$FILE.__step3__"
else
  awk '
    BEGIN { injected=0 }
    {
      print
      if (injected==0 && $0 ~ /^[[:space:]]*import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+['"'"'"]fastify['"'"'"];[[:space:]]*$/) {
        print "import type { FastifyInstance } from '\''fastify'\'';"
        injected=1
      }
    }
  ' "$FILE.__step2__" > "$FILE.__step3__"
fi

# 4) Substituir o arquivo final
mv "$FILE.__step3__" "$FILE"
rm -f "$FILE.__step1__" "$FILE.__step2__" || true

# 5) Pré-visualização dos imports resultantes
echo "[preview] imports finais em src/index.ts:"
nl -ba "$FILE" | sed -n '1,40p' | grep -nE "import .*from '\''fastify'\'';|import type .*from '\''fastify'\'';" || true

# 6) Validar pacote server: build + lint (sem warnings) + test
pnpm -F @mini-ide/server run build

# Lint estrito: sem warnings
npx --yes eslint "$SRV/src" --ext .ts,.tsx --max-warnings=0

pnpm -F @mini-ide/server run test

echo "== OK :: imports de fastify normalizados e lint zerado no server =="
