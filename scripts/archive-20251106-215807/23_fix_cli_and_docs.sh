# 23_fix_cli_and_docs.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE  (raiz do projeto)
# Objetivo:
#  - Corrigir o CLI @mini-ide/cli (tipagem e acesso a index signature) e remover teste legado quebrado
#  - Garantir binário "mini-ide" via pnpm link --global
#  - Regenerar documentação (TypeDoc) sem erros
#  - Validar build/test do workspace
# Idempotente: pode ser executado várias vezes sem efeitos colaterais.
# Requisitos: Node 22+, pnpm, jq (opcional), servidor @mini-ide/server em http://localhost:3000 (opcional p/ teste manual)
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
CLI="$ROOT/packages/cli"
DOCS="$ROOT/docs/api"

echo "== MINI-IDE :: 23_fix_cli_and_docs =="

# 1) Corrigir package.json do CLI (bin, scripts, descrição)
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
  sed -E -i 's#"description": "[^"]*"#"description": "Mini-IDE CLI (analyze, utilidades locais)"#' "$CLI/package.json"
  grep -q '"bin":' "$CLI/package.json" || sed -E -i 's#"main": "dist\/index.js"#"main": "dist\/index.js", "bin": { "mini-ide": "dist\/index.js" }#' "$CLI/package.json"
  sed -E -i 's#"build": "tsc -p tsconfig\.json"#"build": "tsc -p tsconfig.build.json"#' "$CLI/package.json"
  grep -q '"dev": "tsx watch src/index.ts"' "$CLI/package.json" || sed -E -i 's#"test:watch": "vitest"#"test:watch": "vitest", "dev": "tsx watch src\/index.ts"#' "$CLI/package.json"
fi
echo "[ok] @mini-ide/cli/package.json ajustado"

# 2) Reescrever CLI com TSDoc e tipagem correta (corrige TS2322/TS4111)
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
 *   - Salva o resultado em `bundles/v1.0.12/analysis-YYYYMMDD-HHMMSS.json`.
 */

import { writeFileSync, mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

/** Argumentos normalizados para o comando analyze. */
export type AnalyzeArgs = {
  /** Texto de entrada a ser compactado. */
  input: string;
  /** Limite máximo opcional para o resultado. */
  maxLen?: number;
  /** URL base do servidor Mini-IDE. */
  url: string;
};

/** Resultado esperado da API /analyze. */
export type AnalyzeResponse = {
  ok: boolean;
  inputLen: number;
  outputLen: number;
  result: string;
};

/**
 * Separa o comando e os argumentos crus.
 * @param argv process.argv
 */
export function parseArgs(argv: string[]): { cmd: string; rest: string[] } {
  const [_node, _file, ...rest] = argv;
  const cmd = rest[0] ?? '';
  return { cmd, rest: rest.slice(1) };
}

/** Resolve o diretório raiz do monorepo (do arquivo compilado até ../../..). */
export function projectRootFromThisFile(): string {
  // dist/index.js => packages/cli/dist/index.js
  // subimos 3 níveis até o root
  const here = fileURLToPath(import.meta.url);
  return resolve(here, '../../../..');
}

/**
 * Imprime uso e encerra com código 2.
 * @param msg Mensagem opcional de erro explicativo
 */
export function usageAndExit(msg?: string): never {
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

/**
 * Converte os argumentos crus em {@link AnalyzeArgs}.
 * Corrige TS2322 garantindo que "input" seja sempre string.
 */
export function parseAnalyze(rest: string[]): AnalyzeArgs {
  if (rest.length === 0) usageAndExit('faltou o texto para analisar.');

  const first = rest[0];
  if (typeof first !== 'string' || first.length === 0) {
    usageAndExit('texto inválido para analisar.');
  }

  let input: string = first;
  let maxLen: number | undefined;
  let url = 'http://localhost:3000';

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

/**
 * Executa o comando analyze contra o servidor local.
 * Corrige TS4111 acessando index signature via colchetes.
 */
export async function cmdAnalyze(args: AnalyzeArgs): Promise<number> {
  const payload: Record<string, unknown> = { input: args.input };
  if (typeof args.maxLen === 'number') payload['maxLen'] = args.maxLen;

  const res = await fetch(`${args.url}/analyze`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    console.error(`erro HTTP ${res.status}: ${await res.text()}`);
    return 1;
  }

  const json = await res.json() as AnalyzeResponse;

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

/** Função principal do CLI. */
export async function main(): Promise<number> {
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

// Execução quando chamado via binário
main().then((code) => process.exit(code)).catch((err) => {
  console.error(err);
  process.exit(1);
});
EOF
echo "[ok] @mini-ide/cli/src/index.ts reescrito com TSDoc e correções"

# 3) Corrigir teste legado do CLI (remover import de 'hello' inexistente)
mkdir -p "$CLI/test"
cat > "$CLI/test/basic.spec.ts" <<'EOF'
import { describe, it, expect } from 'vitest';
import { parseArgs, parseAnalyze } from '../src/index';

describe('CLI :: sanity', () => {
  it('parseArgs separa comando e resto', () => {
    const out = parseArgs(['node', '/x/y', 'analyze', 'texto']);
    expect(out.cmd).toBe('analyze');
    expect(out.rest[0]).toBe('texto');
  });

  it('parseAnalyze aceita maxLen e url', () => {
    const a = parseAnalyze(['texto', '--maxLen', '10', '--url', 'http://localhost:3000']);
    expect(a.input).toBe('texto');
    expect(a.maxLen).toBe(10);
    expect(a.url).toMatch(/^http/);
  });
});
EOF
echo "[ok] @mini-ide/cli/test/basic.spec.ts ajustado"

# 4) Build + Test do CLI, link global
pnpm -F @mini-ide/cli run build
pnpm -F @mini-ide/cli run test
pnpm link --global @mini-ide/cli >/dev/null
echo "[ok] CLI buildado, testado e linkado globalmente (mini-ide)"

# 5) Regenerar documentação (TypeDoc)
mkdir -p "$DOCS"
pnpm run docs

echo "== OK :: CLI corrigido e documentação regenerada =="
echo "Use agora: mini-ide analyze \"<texto>\" [--maxLen N] [--url http://localhost:3000]"
