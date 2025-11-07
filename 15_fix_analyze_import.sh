#!/usr/bin/env bash
set -euo pipefail
echo "== MINI-IDE :: 15_fix_analyze_import =="

ROOT="$HOME/workspace/Mini-IDE"
cd "$ROOT"

# 1) Garanta que o analysis-agent exporta compactPrompt (idempotente)
AGIDX="packages/analysis-agent/src/index.ts"
if ! grep -q "export { compactPrompt" "$AGIDX"; then
  cat > "$AGIDX" <<'EOF'
export { compactPrompt, type CompactOptions } from './compactPrompt';
export function hello(name = 'world'): string {
  return `hello, ${name}`;
}
EOF
  echo "[ok] @mini-ide/analysis-agent/src/index.ts atualizado com export compactPrompt"
fi

# 2) Rebuild do analysis-agent (gera dist/index.d.ts com compactPrompt)
pnpm -F @mini-ide/analysis-agent run build
echo "[ok] analysis-agent rebuilt"

# 3) (Opcional, melhora DX) adicionar path para o pacote sem '/*' -> src/index.ts
#    Isso evita falhas de tipagem em builds parciais e melhora o autocompletion.
TSBASE="tsconfig.base.json"
if command -v jq >/dev/null 2>&1; then
  TMP="$(mktemp)"
  jq '.compilerOptions.paths["@mini-ide/analysis-agent"] = ["packages/analysis-agent/src/index.ts"]
      | .compilerOptions.paths["@mini-ide/shared"] = ["packages/shared/src/index.ts"]' \
      "$TSBASE" > "$TMP"
  mv "$TMP" "$TSBASE"
else
  # Fallback sed: insere entradas se não existirem
  grep -q '"@mini-ide/analysis-agent"' "$TSBASE" || \
    sed -i 's#"@mini-ide/analysis-agent/\*": \["packages\/analysis-agent\/src\/\*"\]#, "@mini-ide/analysis-agent": ["packages\/analysis-agent\/src\/index.ts"]#' "$TSBASE"
  grep -q '"@mini-ide/shared"]' "$TSBASE" || \
    sed -i 's#"@mini-ide/shared/\*": \["packages\/shared\/src\/\*"\]#, "@mini-ide/shared": ["packages\/shared\/src\/index.ts"]#' "$TSBASE"
fi
echo "[ok] tsconfig.base.json atualizado com paths diretos para src/index.ts"

# 4) Agora sim, build do server + testes
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: import de compactPrompt resolvido e /analyze buildando com sucesso =="
echo "Subir em dev: pnpm -F @mini-ide/server run dev  (POST /analyze operacional)"
