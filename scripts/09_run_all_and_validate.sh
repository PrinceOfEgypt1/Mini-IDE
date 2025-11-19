#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MINI-IDE - LOTE 3 DE HUs DE UI (v1.0.18+)
# Execução e Validação Completa
# =============================================================================

# Descobre a pasta onde o script está (…/Mini-IDE/scripts)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Raiz do projeto = um nível acima (…/Mini-IDE)
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"

cd "$ROOT_DIR"

banner() {
  cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   MINI-IDE - LOTE 3 DE HUs DE UI (v1.0.18+)                  ║
║   Execução e Validação Completa                              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
}

info() {
  printf '[info] %s\n' "$*"
}

ok() {
  printf '[ok] %s\n' "$*"
}

error() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

banner

info "Iniciando execução de todos os scripts..."

info "Validando pré-requisitos..."

if ! command -v pnpm >/dev/null 2>&1; then
  error "pnpm não encontrado no PATH. Instale pnpm antes de continuar."
else
  ok "pnpm encontrado"
fi

if [[ ! -d "$ROOT_DIR/packages/ui" ]]; then
  error "Diretório packages/ui não encontrado. Execute este script a partir da raiz do projeto Mini-IDE."
else
  ok "Estrutura do projeto verificada"
fi

info ""
info "Executando scripts de implementação..."
info ""

# IMPORTANTE:
# Aqui usamos SEMPRE o caminho completo (SCRIPT_DIR/...) para cada script.
SCRIPTS=(
  "$SCRIPT_DIR/01_hu_ui_discovery_notes_002_component.sh"
  "$SCRIPT_DIR/02_hu_ui_discovery_notes_002_test.sh"
  "$SCRIPT_DIR/03_hu_ui_explore_mode_001_component.sh"
  "$SCRIPT_DIR/04_hu_ui_explore_mode_001_test.sh"
  "$SCRIPT_DIR/05_hu_ui_timeline_003_component.sh"
  "$SCRIPT_DIR/06_hu_ui_timeline_003_test.sh"
  "$SCRIPT_DIR/07_integrate_with_workspace_tabs.sh"
  "$SCRIPT_DIR/08_workspace_tabs_integration_test.sh"
)

DESCRICOES=(
  "Implementar Discovery Notes evoluídas com edição e persistência"
  "Criar/atualizar testes de Discovery Notes (HU-UI-Discovery-Notes-002)"
  "Implementar Overview com Modo Explorar (HU-UI-Explore-Mode-001)"
  "Criar/atualizar testes da Overview (HU-UI-Explore-Mode-001)"
  "Criar componente Timeline de Exploração (HU-UI-Timeline-003)"
  "Criar testes para a Timeline de Exploração (HU-UI-Timeline-003)"
  "Integrar componentes com WorkspaceTabs (abas centrais)"
  "Testes de integração do WorkspaceTabs com novos componentes"
)

TOTAL=${#SCRIPTS[@]}

for ((i = 0; i < TOTAL; i++)); do
  script="${SCRIPTS[$i]}"
  descricao="${DESCRICOES[$i]}"

  echo
  echo "========================================="
  info "Executando: $(basename "$script")"
  info "Descrição: $descricao"
  echo "========================================="

  if [[ ! -f "$script" ]]; then
    error "Script não encontrado: $script"
  fi

  if [[ ! -x "$script" ]]; then
    info "Script não é executável, ajustando permissão..."
    chmod +x "$script"
  fi

  "$script"
done

echo
info "Todos os scripts de implementação foram executados com sucesso."
echo

info "Iniciando validação da pipeline local (lint, test, typecheck, build)..."

echo "========================================="
info "Executando: pnpm lint"
echo "========================================="
pnpm lint

echo "========================================="
info "Executando: pnpm test"
echo "========================================="
pnpm test

echo "========================================="
info "Executando: pnpm typecheck"
echo "========================================="
pnpm typecheck

echo "========================================="
info "Executando: pnpm build"
echo "========================================="
pnpm build

echo
ok "Lote 3 de HUs de UI executado e validado com sucesso."
echo
