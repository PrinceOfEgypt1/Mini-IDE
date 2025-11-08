# auto_fix_trailing_blocks.sh
set -euo pipefail
FILE="42_pipeline_checklist.sh"
BACKUP="$FILE.bak.$(date +%F-%H%M%S)"

echo "== Backup =="
cp -a "$FILE" "$BACKUP"

echo "== Normalizando EOL =="
sed -i 's/\r$//' "$FILE"

# Detecta saldos
read -r IF_SALDO DO_SALDO CASE_SALDO < <(awk '
  BEGIN{ifc=0; doc=0; cas=0}
  /^[[:space:]]*#/ {next}
  {
    if ($1=="if") ifc++
    if ($1=="fi") ifc--
    if ($1=="case") cas++
    if ($1=="esac") cas--
    for(i=1;i<=NF;i++){
      if($i=="do")   doc++
      if($i=="done") doc--
    }
  }
  END{ printf "%d %d %d", ifc, doc, cas }
' "$FILE")

# Heredocs abertos
mapfile -t OPEN_HD < <(awk '
  match($0, /<<[-]?([\"\047]?)([A-Za-z0-9_]+)\1/, m){print m[2]}
' "$FILE" | sort -u)

# Heredocs fechados
mapfile -t TERM_HD < <(awk '
  { if (match($0, /^[[:space:]]*([A-Za-z0-9_]+)[[:space:]]*$/, x)) print x[1] }
' "$FILE" | sort -u)

# Faltantes
NEED_CLOSE=()
for tag in "${OPEN_HD[@]:-}"; do
  found=0
  for t in "${TERM_HD[@]:-}"; do
    [[ "$t" == "$tag" ]] && { found=1; break; }
  done
  [[ $found -eq 0 ]] && NEED_CLOSE+=("$tag")
done

echo "== Saldos detectados: if=$IF_SALDO do=$DO_SALDO case=$CASE_SALDO =="
echo "== Heredocs a fechar: ${NEED_CLOSE[*]:-nenhum} =="

{
  echo ""
  echo "# ===== AUTO-FIX (anexo) ====="
  if (( ${#NEED_CLOSE[@]} > 0 )); then
    echo "# Fechando heredocs pendentes:"
    for tag in "${NEED_CLOSE[@]}"; do
      echo "$tag"
    done
  fi

  if (( CASE_SALDO > 0 )); then
    echo "# Fechando esac faltantes:"
    for ((i=0;i<CASE_SALDO;i++)); do
      echo "esac  # auto-close"
    done
  fi

  if (( DO_SALDO > 0 )); then
    echo "# Fechando done faltantes:"
    for ((i=0;i<DO_SALDO;i++)); do
      echo "done  # auto-close"
    done
  fi

  if (( IF_SALDO > 0 )); then
    echo "# Fechando fi faltantes:"
    for ((i=0;i<IF_SALDO;i++)); do
      echo "fi    # auto-close"
    done
  fi
  echo "# ===== FIM AUTO-FIX ====="
  echo ""
} >> "$FILE"

# Garante newline final
printf '\n' >> "$FILE"

echo "== Validando sintaxe após auto-fix =="
if bash -n "$FILE"; then
  echo "[ok] Sintaxe válida após auto-fix"
else
  echo "[atenção] Ainda há erro de sintaxe. Veja diferenças com:"
  echo "  diff -u $BACKUP $FILE | sed -n '1,200p'"
  exit 1
fi

echo "== Pronto =="
