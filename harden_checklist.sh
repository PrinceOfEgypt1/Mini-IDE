# harden_checklist.sh
set -euo pipefail
F=42_pipeline_checklist.sh
cp -a "$F" "$F.bak.$(date +%F-%H%M%S)"

# garante newline final
sed -i -e '$a\' "$F"

# injeta guarda após a primeira linha 'set -euo pipefail' (se ainda não existir)
grep -q '__GUARDA_RESUMO__' "$F" || awk '
  BEGIN{ins=0}
  {
    print $0
    if (!ins && $0 ~ /^set -euo pipefail/) {
      print "";
      print "# __GUARDA_RESUMO__ (não remover): evita duplicação do bloco 9) Resumo";
      print "if [ \"$(grep -c \"^# ---------- 9\\) Resumo ----------$\" \""F"\")\" -gt 1 ]; then";
      print "  echo \"[erro] Bloco 9) Resumo duplicado em "F"\" >&2; exit 1";
      print "fi";
      print "";
      ins=1
    }
  }
' F="$F" "$F" > "$F.tmp" && mv "$F.tmp" "$F"

bash -n "$F" && echo "[ok] Harden aplicado e sintaxe válida"
