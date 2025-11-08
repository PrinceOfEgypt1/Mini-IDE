# fix_eof_tail.sh
set -euo pipefail
FILE="42_pipeline_checklist.sh"
BACKUP="$FILE.bak.$(date +%F-%H%M%S)"

echo "== Backup =="
cp -a "$FILE" "$BACKUP"

echo "== Normalizando EOL =="
sed -i 's/\r$//' "$FILE"

echo "== Localizando início da duplicata (8.2) após a linha 205 =="
START_LINE="$(awk 'NR>205 && $0 ~ /^[[:space:]]*# 8\.2\) CLI global \(se presente\)/{print NR; exit}' "$FILE" || true)"
if [[ -z "${START_LINE:-}" ]]; then
  echo "[warn] Marcador não encontrado após 205; usando linha 209 como padrão"
  START_LINE=209
fi

if ! [[ "$START_LINE" =~ ^[0-9]+$ ]]; then
  echo "[erro] Linha inicial inválida: $START_LINE"; exit 1
fi

echo "== Gerando novo arquivo (cortando do $START_LINE ao EOF) =="
TMP="$(mktemp)"
# mantém o conteúdo original até a linha anterior ao início da duplicata
sed -n "1,$((START_LINE-1))p" "$FILE" > "$TMP"

# anexa um rodapé enxuto e fechado
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

# garante newline final
printf '\n' >> "$TMP"

mv "$TMP" "$FILE"

echo "== Validando sintaxe =="
if bash -n "$FILE"; then
  echo "[ok] Sintaxe válida"
else
  echo "[erro] Ainda há erro de sintaxe. Diff:"
  diff -u "$BACKUP" "$FILE" | sed -n '1,200p'
  exit 1
fi

echo "== Preview (últimas 80 linhas) =="
nl -ba "$FILE" | tail -n 80

echo "== Pronto. Para testar:"
echo "REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh"
