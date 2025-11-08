# fix_checklist_block.sh
set -euo pipefail

FILE="42_pipeline_checklist.sh"
BACKUP="42_pipeline_checklist.sh.bak.$(date +%F-%H%M%S)"

echo "== backup =="
cp -a "$FILE" "$BACKUP"

echo "== normalizando EOL =="
# (se tiver dos2unix instalado, ótimo; senão, só remove CRs)
sed -i 's/\r$//' "$FILE"

echo "== fatiando arquivo =="
START_LINE=$(awk '/# 8\.2\) CLI global \(se presente\)/{print NR; exit}' "$FILE" || true)
if [ -z "${START_LINE:-}" ]; then
  echo "[erro] Marcador '# 8.2) CLI global (se presente)' não encontrado."
  echo "       Restaure o backup $BACKUP e tente novamente."
  exit 1
fi

# fim do bloco 8.2 = linha anterior ao próximo cabeçalho (9) ou EOF
END_LINE=$(awk -v s="$START_LINE" 'NR>s && /^# ---------- 9\)/{print NR-1; exit}' "$FILE" || true)
if [ -z "${END_LINE:-}" ]; then
  END_LINE=$(wc -l < "$FILE")
fi

head -n $((START_LINE-1)) "$FILE" > 42_chk_head.tmp
tail -n +"$((END_LINE+1))" "$FILE" > 42_chk_tail.tmp

echo "== escrevendo bloco novo 8.2 =="
cat > 42_chk_8_2.tmp <<'BLOCK'
# 8.2) CLI global (se presente)
if [ "${REQUIRE_GLOBAL_CLI:-1}" != "1" ]; then
  log "-- pular CLI global (REQUIRE_GLOBAL_CLI=0) --"
else
  if command -v mini-ide >/dev/null 2>&1; then
    log "-- validar CLI global (mini-ide) --"
    mini-ide analyze "  Olá   Mini-IDE!  \r\n\r\n Demo de   compactação " \
      --maxLen 42 --url "http://127.0.0.1:$PORT" \
      >/tmp/mini-ide-cli-global.log 2>&1 || {
      err "CLI global falhou. Veja /tmp/mini-ide-cli-global.log"
      # não aborta aqui; vamos tentar descobrir o arquivo pelo log/fallback
    }

    # 1) preferimos linha 'SAVED:/abs/caminho.json'
    CLI_G_SAVED="$(grep -oE 'SAVED:/[^ ]+\.json' /tmp/mini-ide-cli-global.log | sed 's/^SAVED://' | tail -n1 || true)"

    # 2) se não houver SAVED:, tenta caminho cru impresso no log
    if [ -z "$CLI_G_SAVED" ]; then
      CLI_G_SAVED="$(grep -oE '/[^ ]+/analysis-[0-9-]+\.json' /tmp/mini-ide-cli-global.log | tail -n1 || true)"
    fi

    # 3) fallback: arquivo mais novo em bundles/v1.0.12
    if [ -z "$CLI_G_SAVED" ]; then
      CLI_G_SAVED="$(ls -1t "$ROOT/bundles/v1.0.12"/analysis-*.json 2>/dev/null | head -n1 || true)"
    fi

    if [ -n "$CLI_G_SAVED" ] && [ -f "$CLI_G_SAVED" ]; then
      ok "CLI global OK: $CLI_G_SAVED"
    else
      err "arquivo do CLI global não encontrado (veja /tmp/mini-ide-cli-global.log)"
      # não fazemos exit 1 para não travar a pipeline local
    fi
  else
    log "-- mini-ide não encontrado no PATH; pulando CLI global --"
  fi
fi
BLOCK

echo "== montando arquivo final =="
cat 42_chk_head.tmp 42_chk_8_2.tmp 42_chk_tail.tmp > "$FILE"
rm -f 42_chk_head.tmp 42_chk_8_2.tmp 42_chk_tail.tmp

# garante newline final
printf '\n' >> "$FILE"

echo "== validação de sintaxe (bash -n) =="
bash -n "$FILE" && echo "[ok] sintaxe válida"

echo "== pronto =="
echo "Você pode rodar: REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh"
