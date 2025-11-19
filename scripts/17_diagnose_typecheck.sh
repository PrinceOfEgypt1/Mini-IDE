#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 17_diagnose_typecheck.sh
# Objetivo: Diagnosticar por que typecheck fecha o terminal
# 
# Estratégia:
#   1. Capturar stderr/stdout em arquivo
#   2. Executar typecheck com timeout
#   3. Verificar pacote por pacote
#
# Modo de uso:
#   1. chmod +x scripts/17_diagnose_typecheck.sh
#   2. ./scripts/17_diagnose_typecheck.sh
#   3. Ler typecheck_debug.log
################################################################################

echo "[info] Diagnosticando problema do typecheck..."

LOG_FILE="typecheck_debug.log"
rm -f "$LOG_FILE"

echo "[info] Executando typecheck com captura de log..."

# Executar com timeout e capturar tudo
timeout 30s pnpm typecheck > "$LOG_FILE" 2>&1 || {
  EXIT_CODE=$?
  echo "[warn] Typecheck falhou com código: $EXIT_CODE"
  echo "Exit code: $EXIT_CODE" >> "$LOG_FILE"
}

echo ""
echo "[ok] Log capturado em: $LOG_FILE"
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CONTEÚDO DO LOG:"
echo "═══════════════════════════════════════════════════════"
cat "$LOG_FILE"
echo "═══════════════════════════════════════════════════════"
echo ""

# Tentar typecheck pacote por pacote
echo "[info] Testando typecheck pacote por pacote..."
echo ""

for pkg in shared ui analysis-agent cli server; do
  echo -n "[check] @mini-ide/$pkg: "
  if timeout 10s pnpm --filter "@mini-ide/$pkg" typecheck > /dev/null 2>&1; then
    echo "✅ OK"
  else
    echo "❌ FALHOU"
    echo ""
    echo "Detalhes do erro em @mini-ide/$pkg:"
    pnpm --filter "@mini-ide/$pkg" typecheck 2>&1 | head -50
    echo ""
  fi
done

echo ""
echo "[info] Diagnóstico concluído! Verifique o log acima."
