# 49_fix_beforeall_imports.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Corrige imports dos testes do @mini-ide/server para incluir beforeAll/afterAll
# e valida com build/lint/test do pacote.

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
SRV="$ROOT/packages/server"
TEST="$SRV/test"

echo "== 49 :: FIX beforeAll/afterAll imports (Vitest) =="

[[ -d "$TEST" ]] || { echo "[erro] diretório de testes não encontrado: $TEST"; exit 1; }

fix_file() {
  local f="$1"
  [[ -f "$f" ]] || { echo "[aviso] não encontrado: $f (ok)"; return 0; }

  # Garante LF
  sed -i 's/\r$//' "$f"

  # Se já tem import do vitest, normaliza para incluir beforeAll/afterAll
  if grep -qE "^import\s+\{\s*describe.*from\s+'vitest';\s*$" "$f"; then
    # Substitui linha de import existente (qualquer ordem de itens)
    perl -0777 -pe "
      s/import\s+\{[^}]*\}\s+from\s+'vitest';/import { describe, it, expect, beforeAll, afterAll } from 'vitest';/g
    " -i "$f"
  else
    # Se não tem import do vitest nesse formato, injeta um import padrão no topo
    # (mantém qualquer banner de comentário inicial)
    awk '
      BEGIN{ injected=0 }
      NR==1{
        print "import { describe, it, expect, beforeAll, afterAll } from '\''vitest'\'';";
        injected=1
      }
      { print }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
}

fix_file "$TEST/healthz.spec.ts"
fix_file "$TEST/analyze.spec.ts"

echo "[info] validando @mini-ide/server…"
( cd "$SRV" && pnpm -s build && pnpm -s lint && pnpm -s test )

echo "== 49 :: OK — beforeAll/afterAll importados e testes verdes ✅ =="
