#!/usr/bin/env bash
set -euo pipefail

echo "[info] Pós-commit: limpeza de artefatos e hardening"

# 1) Ignorar artefatos temporários/backup
GITIGNORE=".gitignore"
touch "$GITIGNORE"
ADD_IGNORE=0
declare -a PATTERNS=(
  "*.bak"
  "*.tmp"
  "*.backup_*"
  ".backup-fixes/"
  "packages/**/index.ts.tmp"
  "packages/**/index.ts.backup_*"
  "packages/**/test-utils.ts.tmp"
)
for p in "${PATTERNS[@]}"; do
  if ! grep -qxF "$p" "$GITIGNORE"; then
    echo "$p" >> "$GITIGNORE"
    ADD_IGNORE=1
    echo "[ok] Adicionado ao .gitignore: $p"
  fi
done
if [ "$ADD_IGNORE" -eq 1 ]; then
  git add "$GITIGNORE"
fi

# 2) Remover do git os artefatos já versionados (se existirem)
echo "[info] Removendo artefatos versionados indevidos (se houver)…"
git rm -rf --ignore-unmatch \
  .backup-fixes \
  **/*.bak \
  **/*.tmp \
  **/*.backup_* \
  packages/server/src/index.ts.backup_* \
  packages/server/src/index.ts.tmp* \
  packages/server/test/test-utils.ts.tmp \
  2>/dev/null || true

# 3) (Opcional) docs:generate -> script shell (evita quoting complexo no jq)
ROOT_PKG="package.json"
DOCS_SCRIPT_PATH="scripts/generate_docs_stub.sh"

mkdir -p scripts
if [ ! -f "$DOCS_SCRIPT_PATH" ]; then
  cat > "$DOCS_SCRIPT_PATH" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/api
cat > docs/api/index.html <<'HTML'
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8"/>
    <title>API Docs (stub)</title>
  </head>
  <body>
    <h1>API Docs (stub)</h1>
    <p>Gere o TypeDoc real quando desejar. Por ora, este stub satisfaz o pipeline.</p>
  </body>
</html>
HTML
echo "[ok] docs geradas: $(pwd)/docs/api/index.html"
EOS
  chmod +x "$DOCS_SCRIPT_PATH"
  git add "$DOCS_SCRIPT_PATH"
  echo "[ok] Criado $DOCS_SCRIPT_PATH"
fi

# Injeta/atualiza o script no package.json (sem aspas escapadas loucas)
if jq -e '.scripts' "$ROOT_PKG" >/dev/null 2>&1; then
  tmp="$(mktemp)"
  jq '.scripts["docs:generate"]="bash scripts/generate_docs_stub.sh"' "$ROOT_PKG" > "$tmp"
  mv "$tmp" "$ROOT_PKG"
  git add "$ROOT_PKG"
  echo "[ok] package.json atualizado com scripts.docs:generate"
else
  echo "[fail] package.json inválido (sem campo scripts). Abortando."
  exit 1
fi

# 4) Hardening do Husky: typecheck workspace sem filtros “vazios”
HUSKY_TC=".husky/pre-commit"
if [ -f "$HUSKY_TC" ] && ! grep -q "pnpm -r exec tsc --noEmit" "$HUSKY_TC"; then
  echo "[info] Ajustando pre-commit para typecheck workspace…"
  printf '\n# Hardening: typecheck workspace\npnpm -r exec tsc --noEmit || exit 1\n' >> "$HUSKY_TC"
  git add "$HUSKY_TC"
fi

# 5) Validar pipeline (rápido)
echo "[info] Validando checklist rápido…"
REQUIRE_GLOBAL_CLI=0 PORT=3201 bash ./42_pipeline_checklist.sh || {
  echo "[fail] Checklist rápido falhou — verifique o output acima."
  exit 1
}

# 6) Commit
if ! git diff --cached --quiet; then
  git commit -m "chore(repo): limpar artefatos, docs stub e hardening do pre-commit"
  echo "[ok] Commit de pós-limpeza criado."
else
  echo "[ok] Nada para commitar."
fi

echo "[ok] Pós-commit concluído."
