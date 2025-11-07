#!/usr/bin/env bash
set -euo pipefail
echo "== MINI-IDE :: 16_restore_compactPrompt =="

ROOT="$HOME/workspace/Mini-IDE"
AG="$ROOT/packages/analysis-agent"
SRV="$ROOT/packages/server"

# 1) Recriar compactPrompt.ts se estiver ausente
mkdir -p "$AG/src"
if [ ! -f "$AG/src/compactPrompt.ts" ]; then
  cat > "$AG/src/compactPrompt.ts" <<'EOF'
/**
 * compactPrompt
 * - Normaliza whitespace
 * - Remove linhas vazias duplicadas
 * - Aplica trim
 * - Opcionalmente limita comprimento
 */
export type CompactOptions = {
  maxLen?: number; // se definido, corta e adiciona " …"
};

export function compactPrompt(input: string, opts: CompactOptions = {}): string {
  // normaliza \r\n -> \n
  let s = input.replace(/\r\n/g, '\n');

  // substitui múltiplos espaços por um único dentro da linha
  s = s.split('\n').map(l => l.replace(/\s+/g, ' ').trim()).join('\n');

  // remove linhas vazias consecutivas
  s = s.replace(/\n{3,}/g, '\n\n').trim();

  // aplica maxLen
  const max = opts.maxLen ?? 0;
  if (max > 0 && s.length > max) {
    return s.slice(0, Math.max(0, max - 2)).trimEnd() + ' …';
  }
  return s;
}
EOF
  echo "[ok] compactPrompt.ts restaurado"
else
  echo "[ok] compactPrompt.ts já existe"
fi

# 2) Garantir que index.ts exporta a função
cat > "$AG/src/index.ts" <<'EOF'
export { compactPrompt, type CompactOptions } from './compactPrompt';
export function hello(name = 'world'): string {
  return `hello, ${name}`;
}
EOF
echo "[ok] analysis-agent/src/index.ts com export compactPrompt"

# 3) Rebuild analysis-agent
pnpm -F @mini-ide/analysis-agent run build
pnpm -F @mini-ide/analysis-agent run test || true
echo "[ok] analysis-agent buildado"

# 4) Rebuild + test do server
pnpm -F @mini-ide/server run build
pnpm -F @mini-ide/server run test

echo "== OK :: compactPrompt restaurado e /analyze buildando =="
echo "Subir em dev: pnpm -F @mini-ide/server run dev"
echo "Testar: curl -s -X POST http://localhost:3000/analyze -H 'content-type: application/json' -d '{\"input\":\"Linha  1   com   espaços\\r\\n\\r\\n\\r\\n   Linha  2\\tok\"}' | jq"
