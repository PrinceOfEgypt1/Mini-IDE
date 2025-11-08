# fix_harden_guard.sh
set -euo pipefail
F="42_pipeline_checklist.sh"
BKP="$F.bak.$(date +%F-%H%M%S)"
cp -a "$F" "$BKP"

# Garante newline final
sed -i -e '$a\' "$F"

# Reescreve apenas o bloco do guard entre a marca __GUARDA_RESUMO__ e a próxima linha em branco
awk '
  BEGIN{inblk=0}
  {
    if ($0 ~ /__GUARDA_RESUMO__/) {
      print $0
      # imprime o bloco novo, literal e seguro
      print "RESUMO_COUNT=$(grep -Fxc \"# ---------- 9) Resumo ----------\" \"" F "\" 2>/dev/null || echo 0)"
      print "case \"$RESUMO_COUNT\" in"
      print "  (*[!0-9]*) RESUMO_COUNT=0 ;;"
      print "esac"
      print "if [ \"$RESUMO_COUNT\" -gt 1 ]; then"
      print "  echo \"[erro] Bloco 9) Resumo duplicado em " F "\" >&2; exit 1"
      print "fi"
      inblk=1; next
    }
    if (inblk==1) {
      # pula linhas do bloco antigo até a próxima linha vazia
      if ($0 ~ /^$/) { print \"\"; inblk=0 }
      next
    }
    print $0
  }
' F="$F" "$F" > "$F.tmp" && mv "$F.tmp" "$F"

# Validação
bash -n "$F" && echo "[ok] Sintaxe válida e guard ajustado"
