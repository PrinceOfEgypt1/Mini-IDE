#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F="$ROOT/42_pipeline_checklist.sh"

# Flags configuráveis (sem editar arquivos):
: "${PORT:=3200}"                 # Porta do server temporário
: "${REQUIRE_GLOBAL_CLI:=1}"      # 1 = valida CLI global; 0 = pula
: "${IGNORE_GUARDA_RESUMO:=0}"    # 1 = ignora qualquer guard de "Resumo"
: "${LOG_DIR:=/tmp}"              # pasta de logs

RUN_LOG="$LOG_DIR/mini-ide-run-$(date +%F-%H%M%S).log"

# Limpa restos de execuções anteriores (opcional)
rm -f /tmp/mini-ide-*.log || true

# Sintaxe do checklist antes de rodar
bash -n "$F" || { echo "[erro] Sintaxe inválida em $F" >&2; exit 2; }

# Exporta flags para o checklist
export PORT REQUIRE_GLOBAL_CLI
if [[ "$IGNORE_GUARDA_RESUMO" == "1" ]]; then
  export IGNORE_GUARDA_RESUMO=1
fi

echo "[info] Executando checklist… (log: $RUN_LOG)"
set +e
REQUIRE_GLOBAL_CLI="$REQUIRE_GLOBAL_CLI" PORT="$PORT" bash "$F" | tee "$RUN_LOG"
rc=${PIPESTATUS[1]}
set -e

# Resumo enxuto do que interessa
echo "----------------------------------------"
echo "Resumo rápido"
if grep -Fq "CHECKLIST GERAL: SUCESSO" "$RUN_LOG"; then
  echo "✅ PASSOU"
else
  echo "❌ FALHOU — veja o log: $RUN_LOG"
fi

awk '
  /^Server base:/  {print}
  /^Docs:/         {print}
  /^CLI local:/    {print}
  /^CLI global:/   {print}
  /^-- validar/    {print}
' "$RUN_LOG" || true

echo "----------------------------------------"
echo "[info] Log completo: $RUN_LOG"
exit $rc
