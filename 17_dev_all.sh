# 17_dev_all.sh
#!/usr/bin/env bash
set -euo pipefail
ROOT="$HOME/workspace/Mini-IDE"
cd "$ROOT"

# acrescenta scripts convenientes no server e na raiz
if command -v jq >/dev/null 2>&1; then
  # server: script dev já existe; adiciona watch de types
  tmp="$(mktemp)"; jq '.scripts["dev:watch"]="tsx watch src/index.ts"' packages/server/package.json > "$tmp" && mv "$tmp" packages/server/package.json

  # raiz: dev:all (apenas server por enquanto; UI virá depois)
  tmp="$(mktemp)"; jq '.scripts["dev:all"]="pnpm -F @mini-ide/server run dev"' package.json > "$tmp" && mv "$tmp" package.json
else
  # fallbacks simples
  sed -i 's#"dev": "tsx src/index.ts"#"dev": "tsx src/index.ts", "dev:watch": "tsx watch src/index.ts"#' packages/server/package.json
  grep -q '"dev:all"' package.json || sed -i 's#"ci:all": "pnpm build && pnpm typecheck && pnpm lint && pnpm test"#"ci:all": "pnpm build && pnpm typecheck && pnpm lint && pnpm test", "dev:all": "pnpm -F @mini-ide/server run dev"#' package.json
fi

echo '== OK :: adicionado "pnpm dev:all" na raiz e "dev:watch" no server =='
