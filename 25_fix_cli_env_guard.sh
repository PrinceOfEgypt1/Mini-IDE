# 25_fix_cli_env_guard.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo:
#   - Corrigir o acesso à env no guard do CLI (TS4111) usando process.env['VITEST']
#   - Tornar o guard robusto: não executar main() em testes (Vitest) nem em imports
#   - Recompilar, testar o pacote CLI e regenerar docs
# Idempotente: pode rodar várias vezes sem efeitos colaterais.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
CLI="$ROOT/packages/cli"

echo "== MINI-IDE :: 25_fix_cli_env_guard =="

test -f "$CLI/src/index.ts" || { echo "erro: $CLI/src/index.ts não encontrado"; exit 1; }

# Reescreve apenas a cauda do arquivo, removendo blocos antigos de execução automática.
# Corta a partir do marcador do bloco anterior, se existir; senão, corta a partir de main().then(
awk '
  BEGIN { keep=1 }
  /\/\/ Execução quando chamado como binário/ { keep=0 }
  /main\(\)\.then\(/ { keep=0 }
  { if (keep) print }
' "$CLI/src/index.ts" > "$CLI/src/index.ts.__tmp__"

cat >> "$CLI/src/index.ts.__tmp__" <<'EOF'

// Execução quando chamado como binário (não durante import/test)
const __isDirectRun = (import.meta.url === `file://${process.argv[1]}`);
const __isVitest = (process.env['VITEST'] ?? '') !== '' && (process.env['VITEST'] ?? '') !== '0' && (process.env['VITEST'] ?? '') !== 'false';

if (__isDirectRun && !__isVitest) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
EOF

mv "$CLI/src/index.ts.__tmp__" "$CLI/src/index.ts"
echo "[ok] tail do CLI atualizado com guard usando process.env['VITEST']"

# Build + Test do pacote CLI
pnpm -F @mini-ide/cli run build
pnpm -F @mini-ide/cli run test

# Link global do binário (garante que `mini-ide` esteja no PATH)
pnpm link --global @mini-ide/cli >/dev/null
echo "[ok] CLI linkado globalmente"

# Regenerar documentação (TypeDoc) para validar imports sem execução
pnpm run docs

echo "== OK :: CLI estabilizado (guard TS4111 corrigido) e docs regeneradas =="
echo "Exemplo de uso:"
echo '  mini-ide analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 60 --url http://localhost:3000'
