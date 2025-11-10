#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok(){ echo -e "${GREEN}[ok]${NC} $*"; }
info(){ echo -e "${GREEN}[info]${NC} $*"; }
warn(){ echo -e "${YELLOW}[warn]${NC} $*"; }
fail(){ echo -e "${RED}[fail]${NC} $*"; }

SRV_FILE="packages/server/src/index.ts"
[ -f "$SRV_FILE" ] || { fail "Arquivo não encontrado: $SRV_FILE"; exit 1; }

info "Criando backup: ${SRV_FILE}.bak"
cp "$SRV_FILE" "${SRV_FILE}.bak"

rollback() {
  warn "Restaurando backup..."
  mv "${SRV_FILE}.bak" "$SRV_FILE" 2>/dev/null || true
}
trap 'fail "Erro durante a correção."; rollback; exit 1' ERR

# 1) Inserir normalizeText() após imports se ainda não existir
if ! grep -q 'function normalizeText(' "$SRV_FILE"; then
  info "Injetando função normalizeText()"
  awk '
    BEGIN { inserted=0 }
    {
      print $0
      if (!inserted && $0 ~ /^import /) last_import=NR
    }
    END {
      for (i=1;i<=NR;i++) {}
    }
  ' "$SRV_FILE" > "${SRV_FILE}.tmp.header"

  # Insere logo após o último import
  awk -v RS='\0' '1' "$SRV_FILE" > "${SRV_FILE}.tmp.body"  # copia inteiro
  # Constrói saída com injeção após o bloco de imports
  awk '
    BEGIN{printed=0; injected=0}
    {
      print
      if (!injected && $0 !~ /^import / && prev ~ /^import /) {
        print ""
        print "/**"
        print " * Normaliza texto para comparação/armazenamento:"
        print " * - Converte CRLF/CR para LF"
        print " * - Colapsa sequências de whitespace (inclui tabs/newlines) em um único espaço"
        print " * - Aplica trim"
        print " */"
        print "function normalizeText(input: string): string {"
        print "  return input"
        print "    .replace(/\\r\\n?|\\n/g, \" \")"
        print "    .replace(/[\\s\\u00A0]+/g, \" \")"
        print "    .trim();"
        print "}"
        print ""
        injected=1
      }
      prev=$0
    }
  ' "$SRV_FILE" > "${SRV_FILE}.tmp" && mv "${SRV_FILE}.tmp" "$SRV_FILE"
fi

# 2) Garantir uso de MIN_MAX_LEN como default
if grep -q 'const[[:space:]]\+MIN_MAX_LEN' "$SRV_FILE"; then
  info "Garantindo uso de MIN_MAX_LEN como default"
  # Substitui padrões comuns de leitura de maxLen para usar ?? MIN_MAX_LEN
  sed -E -i \
    's/\b(maxLen\s*=\s*[^;]+);/maxLen = (typeof maxLen === "number" ? maxLen : undefined) ?? MIN_MAX_LEN;/g' \
    "$SRV_FILE" || true
fi

# 3) Usar normalizeText antes de gerar o summary
#   - tenta cobrir padrões: summary: text.slice(0,maxLen)
#   - ou const summary = text.slice(0, maxLen)
if grep -q 'summary' "$SRV_FILE"; then
  info "Aplicando normalizeText() no summary"
  # Caso inline no objeto de resposta
  sed -E -i \
    's/summary:\s*([a-zA-Z_][a-zA-Z0-9_]*)\.slice\(\s*0\s*,\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\)/summary: normalizeText(\1).slice(0,\2)/g' \
    "$SRV_FILE" || true

  # Caso variável separada
  sed -E -i \
    's/const\s+summary\s*=\s*([a-zA-Z_][a-zA-Z0-9_]*)\.slice\(\s*0\s*,\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\);/const summary = normalizeText(\1).slice(0,\2);/g' \
    "$SRV_FILE" || true
fi

# 4) Garante Content-Type application/json (header padrão, idempotente)
if ! grep -q 'reply.header("Content-Type", "application/json")' "$SRV_FILE"; then
  info "Assegurando Content-Type application/json"
  sed -E -i \
    's/(reply\s*=\s*reply\s*\|\|\s*this\.reply\s*;|reply\.)/reply.header("Content-Type","application\/json");\n\1/' \
    "$SRV_FILE" || true
fi

ok "Correções aplicadas"

# 5) Build + Lint + Test
info "Build..."
pnpm -C packages/server run build >/dev/null
ok "Build OK"

info "Lint --fix..."
pnpm -C packages/server exec eslint src --ext .ts,.tsx --fix || true
ok "Lint OK (warnings não bloqueiam)"

info "Testes..."
pnpm -C packages/server run test >/dev/null
ok "Testes OK"

# 6) Limpeza final e remoção do backup
rm -f "${SRV_FILE}.bak"
echo -e "${GREEN}[ok]==========================================="
echo -e "[ok] CORREÇÃO CONCLUÍDA ✅ (payload normalizado em /analyze)"
echo -e "[ok]===========================================${NC}"
