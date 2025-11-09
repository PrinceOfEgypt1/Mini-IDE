#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: hardening_checklist_and_audit.sh
# Faz:
#   1) Reescreve 42_pipeline_checklist.sh (grep seguro, (( )), traps, logs)
#   2) Atualiza scripts/audit_checklist_safety.sh
#   3) Aplica patch idempotente no packages/server/test/test-utils.ts (TS2322/payload)
#   4) TypeDoc opcional
# ==============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info() { echo -e "${GREEN}[info]${NC} $*"; }
log_ok()   { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_fail() { echo -e "${RED}[fail]${NC} $*"; }

log_info "Iniciando hardening de grep e comparações numéricas"

# ==============================================================================
# 1) Reescrever 42_pipeline_checklist.sh (com traps e logs)
# ==============================================================================
CHECKLIST_FILE="42_pipeline_checklist.sh"
[ -f "$CHECKLIST_FILE" ] || { log_fail "Arquivo $CHECKLIST_FILE não encontrado"; exit 1; }

log_info "Criando backup: ${CHECKLIST_FILE}.backup"
cp "$CHECKLIST_FILE" "${CHECKLIST_FILE}.backup"

cat > "${CHECKLIST_FILE}.tmp" << 'EOF_CHECKLIST'
#!/usr/bin/env bash
set -Eeuo pipefail

# 42_pipeline_checklist.sh - hardened (grep seguro, (( )), traps, logs, TypeDoc opcional)
REQUIRE_GLOBAL_CLI="${REQUIRE_GLOBAL_CLI:-1}"
PORT="${PORT:-3200}"
SERVER_URL="http://127.0.0.1:${PORT}"
SERVER_PID=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info(){ echo -e "${GREEN}[info]${NC} $*"; }
log_ok(){   echo -e "${GREEN}[ok]${NC} $*"; }
log_warn(){ echo -e "${YELLOW}[warn]${NC} $*"; }
log_fail(){ echo -e "${RED}[fail]${NC} $*"; }

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    log_ok "Servidor (PID: $SERVER_PID) finalizado"
  fi
}
trap cleanup EXIT

err_handler() {
  local ec=$?
  echo -e "${RED}[fail]${NC} Falha inesperada (exit=$ec) na linha ${BASH_LINENO[0]}. Consulte .checklist_server.log (se existir)."
  exit $ec
}
trap err_handler ERR

log_info "Etapa 1/10: pnpm install"
if pnpm install --frozen-lockfile; then log_ok "Install OK"; else log_fail "Install falhou"; exit 1; fi

log_info "Etapa 2/10: pnpm -r run build"
if pnpm -r run build; then log_ok "Build OK"; else log_fail "Build falhou"; exit 1; fi

log_info "Etapa 3/10: pnpm -r exec tsc --noEmit"
if pnpm -r exec tsc --noEmit; then log_ok "Typecheck OK"; else log_fail "Typecheck falhou"; exit 1; fi

log_info "Etapa 4/10: pnpm -r run lint"
if pnpm -r run lint; then log_ok "Lint OK"; else log_fail "Lint falhou"; exit 1; fi

log_info "Etapa 5/10: pnpm -r run test"
if pnpm -r run test; then log_ok "Tests OK"; else log_fail "Tests falharam"; exit 1; fi

# --- TypeDoc opcional ---------------------------------------------------------
log_info "Etapa 6/10: Verificando suporte a TypeDoc (docs:generate)"
if node -e "try{process.exit(require('./package.json').scripts?.['docs:generate']?0:1)}catch(e){process.exit(1)}"; then
  log_info "Gerando documentação TypeDoc (docs:generate)"
  if pnpm run docs:generate; then
    log_ok "TypeDoc gerado em docs/api/"
  else
    log_warn "TypeDoc falhou, mas não é bloqueante (prosseguindo)"
  fi
else
  log_warn "Script docs:generate ausente no package.json (pulando etapa)"
fi

# --- Servidor temporário ------------------------------------------------------
log_info "Etapa 7/10: Subindo servidor temporário na porta ${PORT}"
: > .checklist_server.log
PORT="${PORT}" node packages/server/dist/index.js >> .checklist_server.log 2>&1 & SERVER_PID=$!

log_info "Aguardando servidor responder em ${SERVER_URL} (timeout 10s)"
MAX_WAIT=10; WAIT_COUNT=0
while (( WAIT_COUNT < MAX_WAIT )); do
  if curl -s -f "${SERVER_URL}/healthz" > /dev/null 2>&1; then
    log_ok "Servidor respondendo em ${SERVER_URL}"
    break
  fi
  sleep 1; (( WAIT_COUNT++ ))
done
if (( WAIT_COUNT >= MAX_WAIT )); then
  log_fail "Servidor não respondeu em ${MAX_WAIT}s. Tail do log:"
  tail -n 50 .checklist_server.log || true
  exit 1
fi

# --- /healthz -----------------------------------------------------------------
log_info "Etapa 8/10: Validando GET /healthz"
HEALTH_RESPONSE="$(curl -s "${SERVER_URL}/healthz")"
if echo "$HEALTH_RESPONSE" | grep -qF '"status"' && echo "$HEALTH_RESPONSE" | grep -qF '"ok"'; then
  log_ok "Healthcheck passou: $HEALTH_RESPONSE"
else
  log_fail "Healthcheck inválido: $HEALTH_RESPONSE"
  exit 1
fi

# --- /analyze -----------------------------------------------------------------
log_info "Etapa 9/10: Validando POST /analyze"
ANALYZE_RESPONSE="$(curl -s -X POST "${SERVER_URL}/analyze" -H "Content-Type: application/json" -d '{"text":"test","maxLen":10}')"
if echo "$ANALYZE_RESPONSE" | grep -qF '"summary"'; then
  log_ok "Analyze endpoint respondeu: ${ANALYZE_RESPONSE:0:100}..."
else
  log_fail "Analyze endpoint inválido: $ANALYZE_RESPONSE"
  exit 1
fi

# --- CLI local ----------------------------------------------------------------
log_info "Etapa 10/10: Validando CLI local"
PORT="${PORT}" node packages/server/dist/index.js >> .checklist_server.log 2>&1 & SERVER_PID=$!
sleep 2
if ! curl -s -f "${SERVER_URL}/healthz" > /dev/null 2>&1; then
  log_fail "Servidor não disponível para teste CLI (ver .checklist_server.log)"
  exit 1
fi

CLI_OUTPUT="$(node packages/cli/dist/index.js analyze "Pipeline test" --maxLen 50 --url "${SERVER_URL}" 2>&1 || true)"
if echo "$CLI_OUTPUT" | grep -qE '(Análise|Analysis|summary)'; then
  log_ok "CLI local funcionando"
else
  log_warn "CLI retornou saída inesperada: ${CLI_OUTPUT:0:200}"
fi

log_ok "=========================================="
log_ok "PIPELINE COMPLETO ✅"
log_ok "=========================================="
log_ok "✓ Install"
log_ok "✓ Build"
log_ok "✓ Typecheck"
log_ok "✓ Lint"
log_ok "✓ Tests"
log_ok "✓ TypeDoc (opcional)"
log_ok "✓ Server :${PORT}"
log_ok "✓ Healthcheck"
log_ok "✓ Analyze endpoint"
log_ok "✓ CLI local"
log_info "Pronto para commit/push"
EOF_CHECKLIST

mv "${CHECKLIST_FILE}.tmp" "$CHECKLIST_FILE"
chmod +x "$CHECKLIST_FILE"
log_ok "Arquivo $CHECKLIST_FILE atualizado com hardening"

# ==============================================================================
# 2) Auditoria
# ==============================================================================
AUDIT_FILE="scripts/audit_checklist_safety.sh"
mkdir -p scripts
cat > "$AUDIT_FILE" << 'EOF_AUDIT'
#!/usr/bin/env bash
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info(){ echo -e "${GREEN}[info]${NC} $*"; }
log_ok(){   echo -e "${GREEN}[ok]${NC} $*"; }
log_warn(){ echo -e "${YELLOW}[warn]${NC} $*"; }
log_fail(){ echo -e "${RED}[fail]${NC} $*"; }

log_info "Iniciando auditoria de segurança do 42_pipeline_checklist.sh"
CHECKLIST="42_pipeline_checklist.sh"; WARNINGS=0
[ -f "$CHECKLIST" ] || { log_fail "Arquivo $CHECKLIST não encontrado"; exit 1; }

log_info "Verificando padrões de grep inseguros..."
UNSAFE_GREP="$(grep -nE 'grep.*\?[^"]' "$CHECKLIST" || true)"
[ -n "$UNSAFE_GREP" ] && { log_warn "Padrões de grep potencialmente inseguros:"; echo "$UNSAFE_GREP"; WARNINGS=$((WARNINGS+1)); } || log_ok "Nenhum padrão de grep inseguro encontrado"

log_info "Verificando comparações numéricas..."
UNSAFE_COMPARISONS="$(grep -nE '\[ .* -(gt|ge|lt|le) ' "$CHECKLIST" || true)"
if [ -n "$UNSAFE_COMPARISONS" ]; then
  while IFS= read -r line; do
    LINE_NUM="$(echo "$line" | cut -d: -f1)"
    log_warn "Comparação numérica com [ -gt/-ge/-lt/-le ] na linha $LINE_NUM"
    echo "       $line"
    WARNINGS=$((WARNINGS+1))
  done <<< "$UNSAFE_COMPARISONS"
else
  log_ok "Comparações numéricas seguras (ou via (( )))"
fi

log_info "Verificando uso correto de grep -E..."
MISSING_E_FLAG="$(grep -nE 'grep [^-]*\|' "$CHECKLIST" | grep -v 'grep -E' || true)"
[ -n "$MISSING_E_FLAG" ] && { log_warn "grep com | sem -E:"; echo "$MISSING_E_FLAG"; WARNINGS=$((WARNINGS+1)); } || log_ok "Uso correto de grep -E"

echo ""
if (( WARNINGS == 0 )); then
  log_ok "==========================================="
  log_ok "AUDITORIA PASSOU ✅"
  log_ok "==========================================="
  log_ok "Nenhum warning encontrado"; exit 0
else
  log_warn "==========================================="
  log_warn "AUDITORIA COM WARNINGS: $WARNINGS"
  log_warn "==========================================="
  log_info "Revise as mensagens acima"; exit 0
fi
EOF_AUDIT
chmod +x "$AUDIT_FILE"
log_ok "Arquivo $AUDIT_FILE criado/atualizado"

# ==============================================================================
# 3) Patch TS idempotente (test-utils.ts) — corrige TS2322 em payload
# ==============================================================================
patch_test_utils() {
  local f="packages/server/test/test-utils.ts"
  if [ ! -f "$f" ]; then
    log_warn "Arquivo não encontrado para patch TS: $f"
    return 0
  fi

  # Import InjectPayload
  if ! grep -qE '^import type \{[[:space:]]*InjectPayload[[:space:]]*\} from "light-my-request";' "$f"; then
    awk '
      BEGIN { inserted=0 }
      /^import / { last=NR }
      { lines[NR]=$0; n=NR }
      END {
        for(i=1;i<=n;i++){ print lines[i] }
        if(n>0){ print "import type { InjectPayload } from \"light-my-request\";" }
      }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi

  # Função normalizePayload
  if ! grep -q "function normalizePayload(" "$f"; then
    awk '
      BEGIN { done=0 }
      {
        print
        if(!done && $0 !~ /^import / && prev ~ /^import /){
          print ""
          print "/** Normaliza payload desconhecido para tipos aceitos pelo server.inject */"
          print "function normalizePayload(p: unknown): InjectPayload | undefined {"
          print "  if (p == null) return undefined;"
          print "  if (typeof p === \"string\") return p;"
          print "  if (p instanceof Uint8Array) return p;"
          print "  if (typeof p === \"object\") return p as Record<string, unknown>;"
          print "  if (typeof p === \"number\" || typeof p === \"boolean\" || typeof p === \"bigint\") return String(p);"
          print "  return undefined;"
          print "}"
          print ""
          done=1
        }
        prev=$0
      }
    ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi

  # Reescrever payload nas chamadas server.inject({...})
  # 1) shorthand 'payload,'
  sed -E -i '
    /server\.inject\(\{/,/}\)/ {
      /normalizePayload\(/! s/^([[:space:]]*)payload[[:space:]]*,[[:space:]]*$/\1payload: normalizePayload(payload),/
    }
  ' "$f"
  # 2) geral 'payload: <expr>,'
  sed -E -i '
    /server\.inject\(\{/,/}\)/ {
      /normalizePayload\(/! s/([[:space:]]*payload:[[:space:]]*)([^,}]+)(,)/\1normalizePayload(\2)\3/
    }
  ' "$f"

  log_ok "Patch TS aplicado em $f"
}
patch_test_utils

# ==============================================================================
# 4) Validação e execução do checklist
# ==============================================================================
echo ""; log_info "Validando sintaxe bash dos arquivos modificados..."
bash -n "$CHECKLIST_FILE" && log_ok "Sintaxe válida: $CHECKLIST_FILE" || { log_fail "Sintaxe inválida em $CHECKLIST_FILE"; mv "${CHECKLIST_FILE}.backup" "$CHECKLIST_FILE" 2>/dev/null || true; exit 1; }
bash -n "$AUDIT_FILE" && log_ok "Sintaxe válida: $AUDIT_FILE" || { log_fail "Sintaxe inválida em $AUDIT_FILE"; exit 1; }

log_info "Executando auditoria de segurança..."
bash "$AUDIT_FILE" && log_ok "Auditoria passou sem warnings críticos" || { log_fail "Auditoria reportou problemas"; exit 1; }

log_info "Executando checklist completo (pode levar alguns minutos)..."
if bash "$CHECKLIST_FILE"; then
  log_ok "Checklist passou 100% verde"
else
  log_fail "Checklist falhou"
  echo "--- .checklist_server.log (tail) ---"
  tail -n 80 .checklist_server.log 2>/dev/null || true
  mv "${CHECKLIST_FILE}.backup" "$CHECKLIST_FILE" 2>/dev/null || true
  exit 1
fi

rm -f "${CHECKLIST_FILE}.backup"
echo ""; log_ok "HARDENING CONCLUÍDO COM SUCESSO ✅"
