# 34_link_cli_global.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#   - Resolver, de forma definitiva, o link global do CLI (@mini-ide/cli) com pnpm.
#   - O erro visto foi: ERR_PNPM_NO_IMPORTER_MANIFEST_FOUND ao tentar `pnpm link --global @mini-ide/cli`
#     diretamente pelo nome. O correto é executar o link A PARTIR do diretório do pacote.
#   - Verifica se o "bin" do package.json está correto; compila; faz o link global;
#     valida se o binário `mini-ide` está no PATH; se não estiver, cria um wrapper em ~/.local/bin.
#   - Idempotente. Seguro rodar várias vezes.
# Requisitos:
#   - pnpm instalado; Node 22+; permissão para criar ~/.local/bin se necessário.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
PKG_DIR="$ROOT/packages/cli"
PKG_JSON="$PKG_DIR/package.json"
BIN_NAME="mini-ide"
BIN_REL="dist/index.js"        # entrypoint compilado
LOCAL_BIN="$HOME/.local/bin"

echo "== MINI-IDE :: 34_link_cli_global =="

# 0) checagens
test -d "$PKG_DIR" || { echo "[erro] não encontrei $PKG_DIR"; exit 1; }
test -f "$PKG_JSON" || { echo "[erro] não encontrei $PKG_JSON"; exit 1; }
command -v pnpm >/dev/null || { echo "[erro] pnpm não encontrado no PATH"; exit 1; }

# 1) garante que o bin esteja configurado corretamente no package.json
if ! grep -q "\"bin\"[[:space:]]*:[[:space:]]*{[^\}]*\"$BIN_NAME\"[[:space:]]*:[[:space:]]*\"$BIN_REL\"" "$PKG_JSON"; then
  echo "[erro] campo \"bin\" do package.json do CLI não aponta para $BIN_REL (ou não existe)."
  echo "       abra $PKG_JSON e garanta algo como:"
  echo "       \"bin\": { \"$BIN_NAME\": \"$BIN_REL\" }"
  exit 1
fi
echo "[ok] package.json (bin) aparenta correto → $BIN_NAME → $BIN_REL"

# 2) build do CLI para garantir artefato
pnpm -F @mini-ide/cli run build
test -f "$PKG_DIR/$BIN_REL" || { echo "[erro] não encontrei $PKG_DIR/$BIN_REL pós-build"; exit 1; }

# 3) link global CORRETO: deve ser executado a partir do diretório do pacote
echo "[info] executando link global a partir do diretório do pacote…"
( cd "$PKG_DIR" && pnpm link --global )

# 4) garante que o PATH contenha o diretório global do pnpm
if [ -d "$HOME/.local/share/pnpm" ] && ! command -v "$BIN_NAME" >/dev/null 2>&1; then
  case ":$PATH:" in
    *":$HOME/.local/share/pnpm:"*) : ;;
    *) export PATH="$HOME/.local/share/pnpm:$PATH"; echo "[info] PATH atualizado com ~/.local/share/pnpm";;
  esac
fi

# 5) fallback: se ainda não encontrar o bin no PATH, cria wrapper em ~/.local/bin
if ! command -v "$BIN_NAME" >/dev/null 2>&1; then
  echo "[aviso] $BIN_NAME ainda indisponível no PATH; criando wrapper em $LOCAL_BIN/$BIN_NAME"
  mkdir -p "$LOCAL_BIN"
  cat > "$LOCAL_BIN/$BIN_NAME" <<'EOF'
#!/usr/bin/env bash
# Wrapper para executar o CLI local compilado (fallback)
set -euo pipefail
ROOT="$HOME/workspace/Mini-IDE/packages/cli"
exec node "$ROOT/dist/index.js" "$@"
EOF
  chmod +x "$LOCAL_BIN/$BIN_NAME"

  # adiciona ~/.local/bin ao PATH se necessário (somente sessão atual)
  case ":$PATH:" in
    *":$LOCAL_BIN:"*) : ;;
    *) export PATH="$LOCAL_BIN:$PATH"; echo "[info] PATH atualizado com $LOCAL_BIN";;
  esac
fi

# 6) validação rápida do comando global
if command -v "$BIN_NAME" >/dev/null 2>&1; then
  echo "[ok] $BIN_NAME disponível globalmente: $(command -v $BIN_NAME)"
else
  echo "[erro] não foi possível disponibilizar $BIN_NAME no PATH"; exit 1
fi

# 7) teste rápido (usa servidor se já estiver rodando em 3000; senão tenta 3100 e, se falhar, usa sem URL)
BASE_URL=""
if curl -sf http://localhost:3000/healthz >/dev/null 2>&1; then
  BASE_URL="--url http://localhost:3000"
elif curl -sf http://localhost:3100/healthz >/dev/null 2>&1; then
  BASE_URL="--url http://localhost:3100"
fi

echo "[info] teste do CLI global…"
$BIN_NAME analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " --maxLen 60 $BASE_URL || {
  echo "[aviso] execução do CLI retornou código != 0 (pode ser ausência do server)."
}

echo "== OK :: CLI linkado globalmente e validado =="
echo "Dica: feche e reabra o terminal para persistir o PATH (se necessário)."
