# scripts/finalize_precommit_typecheck.sh
#!/usr/bin/env bash
set -euo pipefail
HOOK=".husky/pre-commit"
[ -f "$HOOK" ] || { echo "[fail] Hook não encontrado: $HOOK"; exit 1; }

backup="${HOOK}.bak.$(date +%Y%m%d%H%M%S)"
cp "$HOOK" "$backup"

tmp="$(mktemp)"
awk '
  BEGIN { skip=0 }
  {
    # Remove qualquer bloco antigo de "Hardening: typecheck workspace"
    if ($0 ~ /^# Hardening: typecheck workspace/) { skip=1; next }
    if (skip==1) {
      if ($0 ~ /tsc --noEmit/) next;
      else { skip=0 }
    }
    print $0
  }
' "$HOOK" > "$tmp"

mv "$tmp" "$HOOK"

# Garante bloco canônico (após o cabeçalho do hook)
if ! grep -q "Typecheck com filtro" "$HOOK"; then
  cat <<'EOF' >> "$HOOK"

echo "== HUSKY :: typecheck workspace =="
# Typecheck com filtro quando houver paths; fallback para workspace inteiro
PKG_FILT="$(git diff --cached --name-only | awk -F/ '$1=="packages" && NF>=2 {print $1"/"$2}' | sort -u | paste -sd, -)"
if [ -n "$PKG_FILT" ]; then
  echo "[pre-commit] Typecheck filtrado (workspaces): $PKG_FILT"
  pnpm -r --filter "$PKG_FILT" exec tsc --noEmit || exit 1
else
  echo "[pre-commit] Typecheck workspace inteiro (fallback)"
  pnpm -r exec tsc --noEmit || exit 1
fi
EOF
fi

chmod +x "$HOOK"
git add "$HOOK"
echo "[ok] pre-commit consolidado. Backup em: $backup"
