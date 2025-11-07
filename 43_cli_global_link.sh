# 43_cli_global_link.sh
# Diretório de execução: ~/workspace/Mini-IDE/packages/cli
set -euo pipefail
cd "$HOME/workspace/Mini-IDE/packages/cli"
pnpm build
pnpm link --global || pnpm add -g .
# garante wrapper caso pnpm global não exponha no PATH
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/mini-ide" <<'SH'
#!/usr/bin/env bash
exec node "$(pnpm root -g)/@mini-ide/cli/dist/index.js" "$@"
SH
chmod +x "$HOME/.local/bin/mini-ide"
echo "[ok] mini-ide disponível. Teste com: mini-ide --help"
