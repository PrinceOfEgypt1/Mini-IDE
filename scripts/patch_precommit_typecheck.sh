#!/usr/bin/env bash
set -euo pipefail
HOOK=".husky/pre-commit"
[ -f "$HOOK" ] || { echo "[fail] Hook não encontrado: $HOOK"; exit 1; }
BLOCK="$(mktemp)"
cat > "$BLOCK" <<'EOF'
# Typecheck com filtro quando houver paths; fallback para workspace inteiro
FILT="$(git diff --cached --name-only | xargs -r -n1 dirname | sort -u | paste -sd, -)"
if [ -n "$FILT" ]; then
  echo "[pre-commit] Typecheck filtrado: $FILT"
  pnpm -r --filter "$FILT" exec tsc --noEmit || exit 1
else
  echo "[pre-commit] Typecheck workspace inteiro (fallback)"
  pnpm -r exec tsc --noEmit || exit 1
fi
EOF
backup="${HOOK}.bak.$(date +%Y%m%d%H%M%S)"
cp "$HOOK" "$backup"
if grep -qE 'pnpm .*--filter' "$HOOK"; then
  sed -i "/pnpm .*--filter/{
r $BLOCK
d
}" "$HOOK"
  echo "[ok] Linha com --filter substituída por bloco com fallback"
else
  if ! grep -q 'pnpm -r exec tsc --noEmit' "$HOOK"; then
    printf '\n# Typecheck workspace\npnpm -r exec tsc --noEmit || exit 1\n' >> "$HOOK"
    echo "[ok] Acrescentado typecheck do workspace"
  else
    echo "[ok] Hook já possuía typecheck adequado"
  fi
fi
chmod +x "$HOOK"
git add "$HOOK"
echo "[ok] pre-commit ajustado. Backup em: $backup"
