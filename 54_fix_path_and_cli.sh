#!/usr/bin/env bash
# 54_fix_path_and_cli.sh
# Diretório de execução: ~/workspace/Mini-IDE
# Objetivo: garantir que o binário "mini-ide" fique disponível no PATH
# - Cria/atualiza wrapper em ~/.local/bin/mini-ide apontando para o dist global do pnpm
# - Garante ~/.local/bin no PATH (sessão atual + ~/.bashrc)
# - Valida com `mini-ide --help`

set -euo pipefail

ROOT="$(pwd)"
CLI_DIR="$ROOT/packages/cli"
WRAPPER_DIR="$HOME/.local/bin"
WRAPPER_BIN="$WRAPPER_DIR/mini-ide"

echo "== 54 :: FIX PATH & CLI =="
echo "[ctx] ROOT=$ROOT"
echo "[ctx] CLI_DIR=$CLI_DIR"

# 1) Descobrir diretório global do pnpm (onde está @mini-ide/cli linkado)
PNPM_GLOBAL_ROOT="$(pnpm root -g 2>/dev/null || true)"
if [[ -z "${PNPM_GLOBAL_ROOT}" || ! -d "${PNPM_GLOBAL_ROOT}" ]]; then
  echo "[erro] Não consegui obter pnpm root -g. Verifique instalação do pnpm." >&2
  exit 1
fi

CLI_DIST="$PNPM_GLOBAL_ROOT/@mini-ide/cli/dist/index.js"
if [[ ! -f "$CLI_DIST" ]]; then
  echo "[info] Build global não encontrado em: $CLI_DIST"
  echo "[info] Tentando (re)linkar globalmente o CLI…"
  (cd "$CLI_DIR" && pnpm link --global)
  if [[ ! -f "$CLI_DIST" ]]; then
    echo "[erro] Ainda não encontrei $CLI_DIST após link global. Abortando." >&2
    exit 1
  fi
fi

# 2) Criar wrapper em ~/.local/bin/mini-ide
mkdir -p "$WRAPPER_DIR"
cat > "$WRAPPER_BIN" <<EOF
#!/usr/bin/env bash
# Wrapper para @mini-ide/cli (pnpm global)
exec node "$(pnpm root -g)/@mini-ide/cli/dist/index.js" "\$@"
EOF
chmod +x "$WRAPPER_BIN"
echo "[ok] Wrapper criado/atualizado: $WRAPPER_BIN"

# 3) Garantir ~/.local/bin no PATH (sessão atual + persistente)
case ":$PATH:" in
  *":$HOME/.local/bin:"*) echo "[ok] ~/.local/bin já está no PATH da sessão";;
  *)
    export PATH="$HOME/.local/bin:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "[ok] ~/.local/bin adicionado ao PATH (sessão e ~/.bashrc)"
    ;;
esac

# 4) Testar mini-ide --help
echo "[info] Testando mini-ide --help…"
if ! command -v mini-ide >/dev/null 2>&1; then
  echo "[erro] mini-ide ainda não está disponível no PATH. Abra um novo terminal OU rode: source ~/.bashrc" >&2
  exit 1
fi

mini-ide --help || { echo "[erro] Falha ao executar mini-ide --help"; exit 1; }

echo "== 54 :: OK — mini-ide disponível no PATH ✅ =="
