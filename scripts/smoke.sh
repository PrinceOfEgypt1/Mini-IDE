#!/usr/bin/env bash
set -euo pipefail
pnpm --filter @mini-ide/server build
PORT=3200 node packages/server/dist/index.js & SPID=$!
sleep 1
curl -fsS http://127.0.0.1:3200/healthz >/dev/null
pnpm --filter @mini-ide/cli build
node packages/cli/dist/index.js analyze "Smoke Mini-IDE" --maxLen 10 --url http://127.0.0.1:3200 >/dev/null
kill $SPID || true
echo "[ok] smoke passou"
