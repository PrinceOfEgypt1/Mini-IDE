# 24_fix_cli_main_guard.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo: impedir que o CLI execute `main()` durante testes/imports (Vitest),
#           corrigindo o erro "process.exit unexpectedly called".
#           O script reescreve a cauda do arquivo, recompila, roda testes do CLI
#           e regenera a documentação TypeDoc.
# Idempotente: pode rodar várias vezes sem efeitos colaterais.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
CLI="$ROOT/packages/cli"

echo "== MINI-IDE :: 24_fix_cli_main_guard =="

# 1) Garante que o arquivo existe
test -f "$CLI/src/index.ts" || { echo "erro: $CLI/src/index.ts não encontrado"; exit 1; }

# 2) Reescreve SOMENTE o rodapé do arquivo para proteger a execução do main()
#    Critérios:
#      - Só chama main() quando o arquivo é o entrypoint real do processo
#      - NÃO chama main() quando for importado (ex.: Vitest/TypeDoc)
#      - Adiciona também um guard por variável de ambiente VITEST (belt & suspenders)
awk '
  BEGIN { print_state=1 }
  # Remove a cauda anterior a partir de "main().then(" se existir
  /main\(\)\.then\(/ { print_state=0 }
  { if (print_state) print }
' "$CLI/src/index.ts" > "$CLI/src/index.ts.__tmp__"

cat >> "$CLI/src/index.ts.__tmp__" <<'TSTAIL'

// Execução quando chamado como binário (não durante import/test)
if (
  import.meta.url === `file://${process.argv[1]}` && // chamado diretamente via node/bin
  !process.env.VITEST // não em ambiente de testes
) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
TSTAIL

mv "$CLI/src/index.ts.__tmp__" "$CLI/src/index.ts"
echo "[ok] @mini-ide/cli/src/index.ts protegido com guard de execução"

# 3) Rebuild + test apenas do CLI
pnpm -F @mini-ide/cli run build
pnpm -F @mini-ide/cli run test

# 4) Link global do binário (garante mini-ide no PATH)
pnpm link --global @mini-ide/cli >/dev/null
echo "[ok] CLI linkado globalmente (mini-ide)"

# 5) Regenerar documentação TypeDoc (para garantir que o import não executa nada)
pnpm run docs

echo "== OK :: CLI estabilizado (sem process.exit em testes) e docs regeneradas =="
echo "Uso: mini-ide analyze \"<texto>\" [--maxLen N] [--url http://localhost:3000]"
