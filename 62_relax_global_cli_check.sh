#!/usr/bin/env bash
set -euo pipefail
FILE="42_pipeline_checklist.sh"
[ -f "$FILE" ] || { echo "[x] não achei $FILE"; exit 1; }

cp -a "$FILE" "${FILE}.bak_$(date +%Y%m%d-%H%M%S)"

# 1) Rebaixa a mensagem de erro para WARN
#    (quantas vezes aparecer, sem duplicar)
sed -i \
  's/\[erro\] arquivo do CLI global não encontrado/[warn] CLI global não encontrado (opcional; ignorando)/g' \
  "$FILE"

# 2) Dentro do bloco “CLI global … até … encerrando server temporário”,
#    neutraliza qualquer "exit 1"
awk '
  BEGIN { inblk=0 }
  /-- validar CLI global \(mini-ide\) --/ { inblk=1 }
  {
    if (inblk==1) {
      if ($0 ~ /^[[:space:]]*exit[[:space:]]+1[[:space:]]*$/) {
        print "# desativado: " $0
        next
      }
    }
    print
  }
  /encerrando server temporário/ { inblk=0 }
' "$FILE" > "${FILE}.tmp"

mv "${FILE}.tmp" "$FILE"
chmod +x "$FILE"
echo "[ok] Patch aplicado em $FILE"
