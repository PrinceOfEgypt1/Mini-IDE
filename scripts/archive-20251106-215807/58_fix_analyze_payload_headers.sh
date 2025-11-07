#!/usr/bin/env bash
set -euo pipefail

SRV="packages/server"
T="$SRV/test"

echo "== 58 :: FIX /analyze payload & headers =="

# Reescreve somente os trechos necessários do analyze.spec.ts
# - Usa 'input' em vez de 'text'
# - Adiciona 'headers: { content-type: application/json }' no app.inject

perl -0777 -pe '
  # 1) Troca { text: ... } por { input: ... }
  s/\{[ \t]*text:/\{ input:/g;

  # 2) Garante headers JSON em cada app.inject(...)
  s/app\.inject\(\{\s*method:\s*'\''POST'\'',\s*url:\s*'\''\/analyze'\'',\s*payload:\s*([^\}]+)\}\)/
    "app.inject({ method: '\''POST'\'', url: '\''\/analyze'\'', headers: { '\''content-type'\'': '\''application\/json'\'' }, payload: $1 })"/gex;
' -i "$T/analyze.spec.ts"

echo "[info] Lint/Typecheck/Test @mini-ide/server"
pnpm --filter @mini-ide/server lint
pnpm --filter @mini-ide/server typecheck
pnpm --filter @mini-ide/server test
echo "== 58 :: OK =="
