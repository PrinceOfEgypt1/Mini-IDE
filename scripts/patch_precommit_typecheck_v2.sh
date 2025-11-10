# scripts/patch_precommit_typecheck_v2.sh
#!/usr/bin/env bash
set -euo pipefail

HOOK=".husky/pre-commit"
[ -f "$HOOK" ] || { echo "[fail] Hook não encontrado: $HOOK"; exit 1; }

backup="${HOOK}.bak.$(date +%Y%m%d%H%M%S)"
cp "$HOOK" "$backup"

tmp="$(mktemp)"
awk '
  BEGIN { injected=0 }
  {
    print $0
    if ($0 ~ /# Typecheck com filtro quando houver paths; fallback para workspace inteiro/ && injected==0) {
      print "PKG_FILT=\"$(git diff --cached --name-only | awk -F/ '\''$1==\"packages\" && NF>=2 {print $1\"/\"$2}'\'' | sort -u | paste -sd, -)\""
      print "if [ -n \"$PKG_FILT\" ]; then"
      print "  echo \"[pre-commit] Typecheck filtrado (workspaces): $PKG_FILT\""
      print "  pnpm -r --filter \"$PKG_FILT\" exec tsc --noEmit || exit 1"
      print "else"
      print "  echo \"[pre-commit] Typecheck workspace inteiro (fallback)\""
      print "  pnpm -r exec tsc --noEmit || exit 1"
      print "fi"
      injected=1
      next
    }
  }
' "$HOOK" > "$tmp"

mv "$tmp" "$HOOK"
chmod +x "$HOOK"
git add "$HOOK"
echo "[ok] pre-commit refinado. Backup em: $backup"
