# fix_dedup_summary.sh
set -euo pipefail
FILE="42_pipeline_checklist.sh"
BACKUP="$FILE.bak.$(date +%F-%H%M%S)"

echo "== Backup =="
cp -a "$FILE" "$BACKUP"

echo "== Normalizando EOL =="
sed -i 's/\r$//' "$FILE"

echo "== Localizando 1º cabeçalho do Resumo (apos linha 180) =="
START_LINE="$(awk 'NR>180 && $0 ~ /^[[:space:]]*# ---------- 9\) Resumo ----------$/{print NR; exit}' "$FILE")"

if [[ -z "${START_LINE:-}" ]]; then
  echo "[erro] Cabeçalho '# ---------- 9) Resumo ----------' não encontrado."; exit 1
fi
echo "[info] Resumo inicia na linha: $START_LINE"

TMP="$(mktemp)"
# mantém tudo até a linha anterior ao cabeçalho
sed -n "1,$((START_LINE-1))p" "$FILE" > "$TMP"

# injeta um único bloco de resumo
cat >> "$TMP" <<'EOF'
# ---------- 9) Resumo ----------
echo "----------------------------------------"
echo "CHECKLIST GERAL: SUCESSO ✅"
echo "Server base: http://127.0.0.1:$PORT"
echo "Docs:        $DOCS_HTML"
echo "CLI local:   $CLI_SAVED"
[ -n "${CLI_G_SAVED:-}" ] && echo "CLI global:  $CLI_G_SAVED"
echo "----------------------------------------"
EOF
printf '\n' >> "$TMP"

mv "$TMP" "$FILE"

echo "== Validando sintaxe =="
bash -n "$FILE" && echo "[ok] Sintaxe válida"

echo "== Preview (últimas 60 linhas) =="
nl -ba "$FILE" | tail -n 60

echo "== Como testar =="
echo "REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh"
