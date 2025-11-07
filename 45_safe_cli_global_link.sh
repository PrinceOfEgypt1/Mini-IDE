# 45_safe_cli_global_link.sh
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do monorepo)
# Objetivo: verificar e (opcionalmente) publicar o binário global `mini-ide`
# Modo padrão: DRY-RUN (só checa e mostra o que faria). Para aplicar, rode com:  --apply
# Rollback: não altera Git; se --apply for usado, qualquer shell wrapper criado é removível.

set -euo pipefail

ROOT="${ROOT:-$HOME/workspace/Mini-IDE}"
PKG_DIR="$ROOT/packages/cli"
BIN_WRAPPER="$HOME/.local/bin/mini-ide"
APPLY="${1:-}"
PNPM_GLOBAL_ROOT="$(pnpm root -g || true)"
YELLOW='\033[33m'; GREEN='\033[32m'; RED='\033[31m'; NC='\033[0m'

msg() { printf "%b\n" "$*"; }
info(){ msg "${YELLOW}[info]${NC} $*"; }
ok()  { msg "${GREEN}[ok]${NC}   $*"; }
err() { msg "${RED}[erro]${NC} $*"; }

echo "== SAFE LINK :: mini-ide (dry-run por padrão) =="
info "ROOT: $ROOT"
info "CLI : $PKG_DIR"

# 1) Pré-checagens
[[ -d "$PKG_DIR" ]] || { err "Pacote CLI não encontrado em $PKG_DIR"; exit 1; }
command -v pnpm >/dev/null || { err "pnpm não encontrado no PATH"; exit 1; }
command -v node >/dev/null || { err "node não encontrado no PATH"; exit 1; }

# 2) Checa build local do CLI
info "Checando build local do CLI…"
( cd "$PKG_DIR" && pnpm -s build >/dev/null )
ok "Build do CLI OK"

# 3) Detecta bin global atual
GLOBAL_CANDIDATE_JS="$PNPM_GLOBAL_ROOT/@mini-ide/cli/dist/index.js"
if [[ -n "$PNPM_GLOBAL_ROOT" && -f "$GLOBAL_CANDIDATE_JS" ]]; then
  ok "Já existe build global do CLI em: $GLOBAL_CANDIDATE_JS"
else
  info "CLI ainda não linkado globalmente via pnpm"
fi

# 4) Wrapper em ~/.local/bin (idempotente)
NEEDS_WRAPPER=0
if ! command -v mini-ide >/dev/null; then
  info "mini-ide NÃO está no PATH (vamos propor wrapper em ~/.local/bin)"
  NEEDS_WRAPPER=1
else
  ok "mini-ide já está no PATH ($(command -v mini-ide))"
fi

# 5) Plano de execução
echo
echo "—— Plano ——————————————————————————————————————————"
echo "• pnpm link --global em packages/cli"
[[ $NEEDS_WRAPPER -eq 1 ]] && echo "• Criar wrapper: $BIN_WRAPPER -> node \"\$PNPM_GLOBAL_ROOT/@mini-ide/cli/dist/index.js\""
echo "———————————————————————————————————————————————————"
echo

if [[ "$APPLY" != "--apply" ]]; then
  info "DRY-RUN concluído. Para aplicar: bash 45_safe_cli_global_link.sh --apply"
  exit 0
fi

# 6) Aplicação
info "Aplicando (—apply)…"
( cd "$PKG_DIR" && pnpm -s link --global )
ok "pnpm link global do CLI concluído"

# Recalcula PNPM_GLOBAL_ROOT após link
PNPM_GLOBAL_ROOT="$(pnpm root -g)"
GLOBAL_CANDIDATE_JS="$PNPM_GLOBAL_ROOT/@mini-ide/cli/dist/index.js"
[[ -f "$GLOBAL_CANDIDATE_JS" ]] || { err "index.js global não encontrado após link: $GLOBAL_CANDIDATE_JS"; exit 1; }

if [[ $NEEDS_WRAPPER -eq 1 ]]; then
  mkdir -p "$(dirname "$BIN_WRAPPER")"
  cat > "$BIN_WRAPPER" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
PNPM_GLOBAL_ROOT="$(pnpm root -g)"
exec node "$PNPM_GLOBAL_ROOT/@mini-ide/cli/dist/index.js" "$@"
SH
  chmod +x "$BIN_WRAPPER"
  ok "Wrapper criado: $BIN_WRAPPER"
  info "Adicione ao PATH (se preciso): export PATH=\"$HOME/.local/bin:\$PATH\""
fi

# 7) Smoke
info "Testando mini-ide --help…"
mini-ide --help || { err "Falha ao executar mini-ide --help"; exit 1; }
ok "CLI global operacional"

echo
ok "Concluído com sucesso ✅"
