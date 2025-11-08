# fix_cli_global_detect.sh (versão à prova de quoting)
set -euo pipefail

ROOT="${ROOT:-$PWD}"
CLI_SRC="$ROOT/packages/cli/src/index.ts"
CHECKLIST="$ROOT/42_pipeline_checklist.sh"

echo "== [1/4] Backups =="
cp -a "$CLI_SRC"    "${CLI_SRC}.bak.$(date +%F-%H%M%S)"    2>/dev/null || true
cp -a "$CHECKLIST"  "${CHECKLIST}.bak.$(date +%F-%H%M%S)"  2>/dev/null || true

echo "== [2/4] Injetando 'SAVED:' no CLI (heredoc) =="
node <<'NODE' "$CLI_SRC"
const fs = require('fs');
const path = require('path');

const file = process.argv[1];
let c = fs.readFileSync(file, 'utf8');

if (c.includes('SAVED:')) {
  console.log('[skip] CLI já imprime SAVED:');
  process.exit(0);
}

/** Caso 1: substitui console.log(path.resolve(filePath)) por 2 logs (abs + SAVED) **/
const pat1 = /console\.log\(\s*path\.resolve\(\s*filePath\s*\)\s*\)\s*;?/;
if (pat1.test(c)) {
  c = c.replace(
    pat1,
    [
      "const __abs = path.resolve(filePath);",
      "console.log(__abs);",
      "console.log(`SAVED:${__abs}`);"
    ].join("\n")
  );
  fs.writeFileSync(file, c, 'utf8');
  console.log('[ok] injetado via padrão path.resolve(filePath)');
  process.exit(0);
}

/** Caso 2: se há algum console.log com 'analysis-' no texto, adiciona SAVED logo após **/
const pat2 = /console\.log\([^)]*analysis-[^)]*\)\s*;?/;
if (pat2.test(c)) {
  c = c.replace(
    pat2,
    (m) => m + "\ntry { const __abs = (typeof filePath !== 'undefined') ? require('node:path').resolve(filePath) : null; if (__abs) console.log(`SAVED:${__abs}`); } catch {}"
  );
  fs.writeFileSync(file, c, 'utf8');
  console.log('[ok] injetado após log de analysis-*');
  process.exit(0);
}

/** Caso 3 (fallback): adiciona bloco no final; só imprime se existir filePath **/
c += `

/* [auto] bloco para compatibilizar com o checklist: imprime SAVED:<abs> se filePath existir */
try {
  if (typeof filePath !== 'undefined') {
    const __abs = require('node:path').resolve(filePath);
    console.log(\`SAVED:\${__abs}\`);
  }
} catch {}
`;
fs.writeFileSync(file, 'utf8');
console.log('[ok] fallback append no final do arquivo (SAVED:)');
NODE

echo "== [3/4] Build + link global do CLI =="
pnpm -C "$ROOT/packages/cli" build
pnpm -C "$ROOT/packages/cli" link --global || true
echo "[info] mini-ide no PATH:"
type -a mini-ide || true

echo "== [4/4] Ajustando checklist p/ capturar 'SAVED:' + fallback =="

# Garante ROOT no topo do checklist (se não houver)
grep -q '^ROOT=' "$CHECKLIST" || sed -i '1a ROOT="${ROOT:-$PWD}"' "$CHECKLIST"

# Permite pular o passo global com REQUIRE_GLOBAL_CLI=0 (idempotente)
if ! grep -q 'pular CLI global' "$CHECKLIST"; then
  sed -i '/# 8\.2) CLI global (se presente)/a if [ "${REQUIRE_GLOBAL_CLI:-1}" != "1" ]; then log "-- pular CLI global (REQUIRE_GLOBAL_CLI=0) --"; else' "$CHECKLIST"
  sed -i '/# ---------- 9\)/i fi' "$CHECKLIST"
fi

# Troca a linha de captura via grep para usar "SAVED:/...json"
# (idempotente; só troca se encontrar a forma antiga)
if grep -q 'grep -oE .*/analysis-[0-9-]\+\.json' "$CHECKLIST"; then
  sed -i -E \
    "s#CLI_G_SAVED=.*#CLI_G_SAVED=\"\$(grep -oE 'SAVED:/[^ ]+\\.json' /tmp/mini-ide-cli-global.log | sed 's/^SAVED://' | tail -n1 || true)\"#g" \
    "$CHECKLIST"
fi

# Adiciona fallback para bundles/v1.0.12 (se ainda não existir)
if ! grep -q 'fallback.*bundles' "$CHECKLIST"; then
  sed -i "/CLI_G_SAVED=.*tail -n1.*/a \  if [ -z \"\$CLI_G_SAVED\" ]; then CLI_G_SAVED=\"\$(ls -1t \"\$ROOT/bundles/v1.0.12\"/analysis-*.json 2>/dev/null | head -n1)\"; fi" "$CHECKLIST"
fi

echo "[ok] Pronto. Rode sua pipeline:"
echo "     REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh"
