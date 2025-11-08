#!/usr/bin/env bash
set -Eeuo pipefail
FILE="42_pipeline_checklist.sh"
[[ -f "$FILE" ]] || { echo "[erro] não achei $FILE"; exit 1; }

BKP="$FILE.bak.$(date +%F-%H%M%S)"
cp -a "$FILE" "$BKP"

# Normaliza EOL e garante newline final
sed -i -e 's/\r$//' -e '$a\' "$FILE"

# Remove qualquer definição antiga imediata de RESUMO_COUNT (linhas que começam com RESUMO_COUNT=)
# e também comparações diretas suspeitas logo abaixo, substituindo por bloco seguro.
awk -v f="$FILE" '
  BEGIN{done=0}
  {
    if (!done && $0 ~ /^RESUMO_COUNT=/) {
      print "RESUMO_COUNT=\"$(grep -Fxc '\''# ---------- 9) Resumo ----------'\'' \"" f "\" 2>/dev/null || echo 0)\""
      print "case \"$RESUMO_COUNT\" in (*[!0-9]*) RESUMO_COUNT=0 ;; esac"
      print "if [ \"${RESUMO_COUNT:-0}\" -gt 1 ]; then"
      print "  echo \"[erro] Bloco 9) Resumo duplicado em " f "\" >&2; exit 1"
      print "fi"
      done=1
      # pula as próximas 3 linhas se forem o padrão antigo (comparação + fi)
      skip=3; next
    }
    if (done && skip>0) { skip--; next }
    print
  }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

bash -n "$FILE" && echo "[ok] Guard reparado com sucesso — sintaxe válida"
