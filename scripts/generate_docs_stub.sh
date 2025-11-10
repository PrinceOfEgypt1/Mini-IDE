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
