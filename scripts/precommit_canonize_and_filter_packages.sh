# scripts/precommit_canonize_and_filter_packages.sh
#!/usr/bin/env bash
set -euo pipefail

HOOK=".husky/pre-commit"
[ -f "$HOOK" ] || { echo "[fail] Hook não encontrado: $HOOK"; exit 1; }
backup="${HOOK}.bak.$(date +%Y%m%d%H%M%S)"
cp "$HOOK" "$backup"

tmp="$(mktemp)"

# 1) Remove bloco antigo de "Hardening: typecheck workspace" e quaisquer outros typechecks duplicados.
awk '
  BEGIN{skip=0}
  # Remove bloco iniciado por este comentário até a próxima linha em branco OU fim do arquivo
  /^# Hardening: typecheck workspace/ { skip=1; next }
  # Remove também ecos antigos/duplicados do cabeçalho typecheck
  /^echo "== HUSKY :: typecheck workspace ==/ && hdr++ >= 1 { next }

  # Enquanto em skip, pulamos linhas que contenham tsc --noEmit ou linhas em branco consecutivas
  skip==1 {
    if ($0 ~ /tsc --noEmit/) next
    if ($0 ~ /^[[:space:]]*$/) { skip=0; next }
    next
  }

  { print $0 }
' "$HOOK" > "$tmp"

mv "$tmp" "$HOOK"

# 2) Garante bloco canônico (apenas 1) com filtro restrito a packages/*
if ! grep -q 'Typecheck com filtro quando houver paths' "$HOOK"; then
cat >> "$HOOK" <<'EOF'

echo "== HUSKY :: typecheck workspace =="
# Typecheck com filtro quando houver paths; fallback para workspace inteiro
# Coleta apenas caminhos dentro de packages/<pkg> (1º e 2º segmentos)
PKG_FILT="$(git diff --cached --name-only \
  | awk -F/ '$1=="packages" && NF>=2 {print $1"/"$2}' \
  | sort -u | paste -sd, -)"

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
echo "[ok] pre-commit canonizado e filtrando só packages/* — backup: $backup"
