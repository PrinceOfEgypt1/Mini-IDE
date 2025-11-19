#!/usr/bin/env bash
set -euo pipefail

# Descobre diretórios
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"

cd "$ROOT_DIR"

echo "ROOT_DIR = $ROOT_DIR"
echo "SCRIPT_DIR = $SCRIPT_DIR"
echo

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

for script in "${SCRIPTS[@]}"; do
  echo "-----------------------------------------"
  echo "[info] Vou executar: $script"

  if [[ ! -f "$script" ]]; then
    echo "[ERRO] Arquivo não existe: $script"
    exit 1
  fi

  if [[ ! -x "$script" ]]; then
    echo "[info] Ajustando permissão de execução em: $script"
    chmod +x "$script"
  fi

  "$script"
done

echo "-----------------------------------------"
echo "[ok] Todos os scripts do lote 3 foram executados."
