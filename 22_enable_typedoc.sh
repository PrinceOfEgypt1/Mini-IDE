# 22_enable_typedoc.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo: habilitar documentação automática (TypeDoc) para pacotes TS e gerar docs em docs/api/.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
DOCS="$ROOT/docs/api"
mkdir -p "$DOCS"

echo "== MINI-IDE :: 22_enable_typedoc =="

# 1) Instalar typedoc no workspace
pnpm add -D -w typedoc

# 2) Criar um typedoc.json na raiz com configurações padrão sólidas
cat > "$ROOT/typedoc.json" <<'EOF'
{
  "$schema": "https://typedoc.org/schema.json",
  "entryPoints": [
    "packages/shared/src/index.ts",
    "packages/analysis-agent/src/index.ts",
    "packages/server/src/index.ts",
    "packages/cli/src/index.ts",
    "packages/ui/src/index.ts"
  ],
  "out": "docs/api",
  "tsconfig": "tsconfig.base.json",
  "treatWarningsAsErrors": false,
  "cleanOutputDir": true,
  "categorizeByGroup": true,
  "entryPointStrategy": "expand",
  "excludeExternals": false,
  "excludePrivate": false,
  "excludeProtected": false,
  "sort": ["source-order"]
}
EOF

# 3) Adicionar script na raiz para gerar docs
if command -v jq >/dev/null 2>&1; then
  TMP="$(mktemp)"
  jq '.scripts.docs="typedoc"
      | .scripts["docs:serve"]="python3 -m http.server 8080 -d docs/api"
     ' "$ROOT/package.json" > "$TMP"
  mv "$TMP" "$ROOT/package.json"
else
  grep -q '"docs": "typedoc"' "$ROOT/package.json" || \
    sed -i 's#"ci:all": "pnpm build && pnpm typecheck && pnpm lint && pnpm test"#"ci:all": "pnpm build && pnpm typecheck && pnpm lint && pnpm test", "docs": "typedoc", "docs:serve": "python3 -m http.server 8080 -d docs\/api"#' "$ROOT/package.json"
fi

# 4) Gerar documentação
pnpm run docs

echo "== OK :: documentação gerada em docs/api (rode: pnpm run docs:serve) =="
