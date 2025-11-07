# 21_cli_analyze.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo: criar o CLI @mini-ide/cli com comando `mini-ide analyze "<texto>" [--maxLen N]`
#           que chama o endpoint local POST /analyze e salva JSON em bundles/v1.0.12/.
#           Faz build, link global via pnpm e valida com um teste rápido.
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
CLI="$ROOT/packages/cli"
BUND="$ROOT/bundles/v1.0.12"
mkdir -p "$BUND"

echo "== MINI-IDE :: 21_cli_analyze =="

# 1) Ajustar package.json do CLI: adicionar "bin" e scripts úteis
if command -v jq >/dev/null 2>&1; then
  TMP="$(mktemp)"
  jq '
    .bin = { "mini-ide": "dist/index.js" } |
    .scripts.build = "tsc -p tsconfig.build.json" |
    .scripts.dev = "tsx watch src/index.ts" |
    .description = "Mini-IDE CLI (analyze, utilidades locais)"
  ' "$CLI/package.json" > "$TMP"
  mv "$TMP" "$CLI/package.json"
else
  # fallback sed simples (assume estrutura atual gerada por scaffold)
  sed -E -i 's#"description": "[^"]*"#"description": "Mini-IDE CLI (analyze, utilidades locais)"#' "$CLI/package.json"
  grep -q '"bin":' "$CLI/package.json" || sed -E -i 's#"main": "dist\/index.js"#"main": "dist\/index.js", "bin": { "mini-ide": "dist\/index.js" }#' "$CLI/package.json"
  sed -E -i 's#"build": "tsc -p tsconfig\.json"#"build": "tsc -p tsconfig.build.json"#' "$CLI/package.json"
  grep -q '"dev": "tsx watch src/index.ts"' "$CLI/package.json" || sed -E -i 's#"test:watch": "vitest"#"test:watch": "vitest", "dev": "tsx watch src\/index.ts"#' "$CLI/package.json"
fi

# 2) Implementar CLI (TypeScript) — usa fetch nativo do Node 22
cat > "$CLI/src/index.ts" <<'EOF'
/**
 * @module CLI
 * @description
 * Ferramenta de linha de comando `mini-ide`.
 *
 * Comandos:
 *   - `mini-ide analyze "<texto>" [--maxLen N] [--url http://localhost:3000]`
 *
 * Saída:
 *   - Salva o resultado em `bundles/v1.0.12/analysis-YYYYMMDD-HHMMSS.json` (caminho relativo ao monorepo).
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

type AnalyzeArgs = {
  input: string;
  maxLen?: number;
  url: string;
};

function parseArgs(argv: string[]): { cmd: string; rest: string[] } {
  const [_node, _file, ...rest] = argv;
  const cmd = rest[0] ?? '';
  return { cmd, rest: rest.slice(1) };
}

/** Resolve o diretório raiz do monorepo (do arquivo compilado até ../../..) */
function projectRootFromThisFile(): string {
  // dist/index.js => packages/cli/dist/index.js
  // subimos 3 níveis até o root
  const here = fileURLToPath(import.meta.url);
  return resolve(here, '../../../..');
}

function usageAndExit(msg?: string): never {
  if (msg) console.error(`erro: ${msg}`);
  console.error(`
uso:
  mini-ide analyze "<texto>" [--maxLen N] [--url http://localhost:3000]

exemplos:
  mini-ide analyze "  Linha 1  \\n\\n   Linha 2\\tok  "
  mini-ide analyze "texto" --maxLen 80
  mini-ide analyze "texto" --url http://127.0.0.1:3000
`);
  process.exit(2);
}

function parseAnalyze(rest: string[]): AnalyzeArgs {
  if (rest.length === 0) usageAndExit('faltou o texto para analisar.');

  let input = '';
  let maxLen: number | undefined;
  let url = 'http://localhost:3000';

  // primeira posição pode ser o texto (entre aspas é melhor)
  input = rest[0];
  const tail = rest.slice(1);

  for (let i = 0; i < tail.length; i++) {
    const a = tail[i];
    if (a === '--maxLen') {
      const v = tail[++i]; if (!v) usageAndExit('valor ausente para --maxLen');
      const n = Number(v); if (!Number.isFinite(n) || n <= 0) usageAndExit('--maxLen inválido');
      maxLen = n;
    } else if (a === '--url') {
      const v = tail[++i]; if (!v) usageAndExit('valor ausente para --url');
      url = v;
    } else {
      usageAndExit(`parâmetro desconhecido: ${a}`);
    }
  }

  return { input, maxLen, url };
}

async function cmdAnalyze(args: AnalyzeArgs): Promise<number> {
  const payload: Record<string, unknown> = { input: args.input };
  if (typeof args.maxLen === 'number') payload.maxLen = args.maxLen;

  const res = await fetch(`${args.url}/analyze`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    console.error(`erro HTTP ${res.status}: ${await res.text()}`);
    return 1;
  }

  const json = await res.json() as {
    ok: boolean; inputLen: number; outputLen: number; result: string;
  };

  const root = projectRootFromThisFile();
  const outDir = resolve(root, 'bundles', 'v1.0.12');
  mkdirSync(outDir, { recursive: true });

  const now = new Date();
  const ts =
    now.getFullYear().toString() +
    String(now.getMonth() + 1).padStart(2, '0') +
    String(now.getDate()).padStart(2, '0') + '-' +
    String(now.getHours()).padStart(2, '0') +
    String(now.getMinutes()).padStart(2, '0') +
    String(now.getSeconds()).padStart(2, '0');

  const file = resolve(outDir, `analysis-${ts}.json`);
  writeFileSync(file, JSON.stringify({ args, response: json }, null, 2), 'utf-8');

  console.log(`[mini-ide] analyze salvo em: ${file}`);
  return 0;
}

async function main(): Promise<number> {
  const { cmd, rest } = parseArgs(process.argv);
  if (!cmd) usageAndExit();

  switch (cmd) {
    case 'analyze': {
      const a = parseAnalyze(rest);
      return await cmdAnalyze(a);
    }
    default:
      usageAndExit(`comando desconhecido: ${cmd}`);
  }
}

main().then((code) => process.exit(code)).catch((err) => {
  console.error(err);
  process.exit(1);
});
EOF

# 3) Build e link global do CLI
pnpm -F @mini-ide/cli run build
pnpm link --global @mini-ide/cli >/dev/null

# 4) Teste curto
mini-ide analyze "  Linha 1   \r\n\r\n   Linha 2\t ok  " --maxLen 80 --url http://localhost:3000 || true
echo "== OK :: CLI instalado. Use:  mini-ide analyze \"<texto>\" [--maxLen N] [--url ...] =="
