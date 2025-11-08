# diag_checklist_eof.sh
set -euo pipefail

FILE="42_pipeline_checklist.sh"
echo "== Arquivo: $FILE =="

# 1) Normaliza EOL para evitar falso-positivo
sed -i 's/\r$//' "$FILE"

# 2) Validação de sintaxe
echo "== bash -n =="
if bash -n "$FILE" 2>diag.err; then
  echo "[ok] Sem erro de parsing"
else
  cat diag.err
fi

# 3) Mostra a região final (últimas 120 linhas)
echo "== Últimas 120 linhas (numeradas) =="
nl -ba "$FILE" | tail -n 120

# 4) Saldos de blocos (heurístico simples, ignora linhas comentadas)
echo "== Saldos de blocos (aprox.) =="
awk '
  BEGIN{ifc=0; doc=0; cas=0}
  /^[[:space:]]*#/ {next}
  {
    # tokens simples; pode haver falsos positivos, mas ajuda
    if ($1=="if") ifc++
    if ($1=="fi") ifc--
    if ($1=="case") cas++
    if ($1=="esac") cas--
    # do/done: soma aparições literais
    for(i=1;i<=NF;i++){
      if($i=="do")   doc++
      if($i=="done") doc--
    }
  }
  END{
    print "saldo_if=",ifc
    print "saldo_do=",doc
    print "saldo_case=",cas
  }
' "$FILE"

# 5) Heredocs abertos e não fechados
echo "== Heredocs (abertos x fechados) =="
awk '
  match($0, /<<[-]?([\"\047]?)([A-Za-z0-9_]+)\1/, m){open[m[2]]++}
  { if (match($0, /^[[:space:]]*([A-Za-z0-9_]+)[[:space:]]*$/, x)) {term[x[1]]++} }
  END{
    for (k in open){
      if (!(k in term)) print "HEREDOC SEM FECHO:", k
    }
  }
' "$FILE" || true

echo "== Fim diagnóstico =="
