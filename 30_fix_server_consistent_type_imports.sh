# 30_fix_server_consistent_type_imports.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo (definitivo):
#   - Forçar importação SOMENTE-TIPO para FastifyInstance no @mini-ide/server/src/index.ts,
#     eliminando o warning "@typescript-eslint/consistent-type-imports".
#   - Normaliza os imports de 'fastify':
#       import Fastify from 'fastify';
#       import type { FastifyInstance } from 'fastify';
#   - Remove qualquer outra forma de import de FastifyInstance.
#   - Valida com build + lint (falha se houver warnings) + test do pacote server.
# Idempotente: pode rodar quantas vezes quiser.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
SRV="$ROOT/packages/server"
FILE="$SRV/src/index.ts"

echo "== MINI-IDE :: 30_fix_server_consistent_type_imports =="

test -f "$FILE" || { echo "erro: não encontrei $FILE"; exit 1; }

# 1) Remove QUALQUER import prévio de FastifyInstance (valor), preservando Fastify default e outros named
#    - Converte "import Fastify, { FastifyInstance, X } from 'fastify'" -> "import Fastify, { X } from 'fastify'"
#    - Converte "import { FastifyInstance } from 'fastify'" -> (remove linha)
awk '
  BEGIN { OFS=FS }
  {
    line=$0
    # Caso 1: import Fastify, { ... } from "fastify"
    if (line ~ /^import[[:space:]]+Fastify[[:space:]]*,[[:space:]]*{[^}]*}[[:space:]]*from[[:space:]]+.\x27fastify\x27;/) {
      # remove FastifyInstance dentro das chaves (com ou sem vírgula adjacente)
      gsub(/FastifyInstance[[:space:]]*,[[:space:]]*/,"",line)
      gsub(/[[:space:]]*,[[:space:]]*FastifyInstance/,"",line)
      gsub(/FastifyInstance/,"",line)
      # limpa chaves vazias: ", { }"
      gsub(/,[[:space:]]*{[[:space:]]*}/,"",line)
      # se sobrou ", {}" (com espaço variado), remove
      gsub(/,[[:space:]]*\{\s*\}/,"",line)
      print line
      next
    }
    # Caso 2: import { FastifyInstance } from "fastify"  -> remover completamente
    if (line ~ /^import[[:space:]]+\{[[:space:]]*FastifyInstance[[:space:]]*\}[[:space:]]*from[[:space:]]+.\x27fastify\x27;/) {
      next
    }
    print $0
  }
' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"

# 2) Garante "import Fastify from 'fastify';" (se inexistente, insere no topo)
if ! grep -qE "^import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+'\x?fastify\x?';" "$FILE"; then
  # insere antes da primeira linha de import existente; se não houver, no topo
  if grep -qE "^import " "$FILE"; then
    awk '
      BEGIN { inserted=0 }
      {
        if (!inserted && $0 ~ /^import /) {
          print "import Fastify from \x27fastify\x27;"
          inserted=1
        }
        print
      }
      END {
        if (!inserted) print "import Fastify from \x27fastify\x27;"
      }
    ' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"
  else
    sed -i "1i import Fastify from 'fastify';" "$FILE"
  fi
fi

# 3) Garante "import type { FastifyInstance } from 'fastify';" após o import Fastify
if ! grep -qE "^import[[:space:]]+type[[:space:]]+\{[[:space:]]*FastifyInstance[[:space:]]*\}[[:space:]]+from[[:space:]]+'\x?fastify\x?';" "$FILE"; then
  awk '
    {
      print $0
      if ($0 ~ /^import[[:space:]]+Fastify[[:space:]]+from[[:space:]]+.\x27fastify\x27;/) {
        print "import type { FastifyInstance } from \x27fastify\x27;"
      }
    }
  ' "$FILE" > "$FILE.__tmp__" && mv "$FILE.__tmp__" "$FILE"
fi

# 4) Mostra trecho final dos imports para auditoria rápida
echo "[preview] imports em src/index.ts:"
grep -nE "^[[:space:]]*import .*from 'fastify';" -n "$FILE" || true
grep -nE "^[[:space:]]*import type .*FastifyInstance.*from 'fastify';" -n "$FILE" || true

# 5) Build + Lint com falha em warnings (para garantir 0 warnings) + Test
pnpm -F @mini-ide/server run build

# roda eslint direto com --max-warnings=0 para garantir que não sobra NENHUM aviso
npx --yes eslint "$SRV/src" --ext .ts,.tsx --max-warnings=0

pnpm -F @mini-ide/server run test

echo "== OK :: imports normalizados (type-only) e lint zerado no server =="
