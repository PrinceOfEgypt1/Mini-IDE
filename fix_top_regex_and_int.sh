#!/usr/bin/env bash
set -Eeuo pipefail

FILE="42_pipeline_checklist.sh"
[[ -f "$FILE" ]] || { echo "[erro] não achei $FILE"; exit 1; }

BKP="$FILE.bak.$(date +%F-%H%M%S)"
cp -a "$FILE" "$BKP"

# Normaliza EOL e garante newline final
sed -i -e 's/\r$//' -e '$a\' "$FILE"

awk '
  BEGIN{ maxhdr=60 }  # só cabeçalho
  NR<=maxhdr {
    line=$0

    # 1) grep com parênteses vira fixed-string (-F)
    # casos: grep -E "..." , e grep "..."
    if (line ~ /grep[[:space:]]+(-E[[:space:]]+)?([^|#]*[()\\][^|#]*)/) {
      # troca primeiro "grep -E" por "grep -F"
      gsub(/grep[[:space:]]+-E[[:space:]]+/,"grep -F ", line)
      # se ainda sobrou "grep " sem -E/-F, com parênteses no padrão, põe -F
      if (line ~ /(^|[[:space:]])grep[[:space:]]+\"[^\"]*[()\\][^\"]*\"/) {
        sub(/(^|[[:space:]])grep[[:space:]]+/, "grep -F ", line)
      }
    }

    # 2) comparação numérica segura: "$VAR" -> "${VAR:-0}"
    # pega padrões simples do tipo [ "$X" -gt 1 ] ou [ "$X" -eq 0 ] etc.
    gsub(/\[\s*"\$([A-Za-z_][A-Za-z0-9_]*)"\s*(-gt|-ge|-eq|-ne|-le|-lt)\s*/, "[ \"${\\1:-0}\" \\2 ", line)

    print line
    next
  }
  { print }
' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

bash -n "$FILE" && echo "[ok] Cabeçalho corrigido — sintaxe válida (backup: $BKP)"
