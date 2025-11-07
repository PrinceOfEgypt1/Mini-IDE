/**
 * @module CLI
 * @remarks
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
  const [, , ...rest] = argv;
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

  const input: string = first;
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


// Execução quando chamado como binário (não durante import/test)
const __isDirectRun = (import.meta.url === `file://${process.argv[1]}`);
const __isVitest = (process.env['VITEST'] ?? '') !== '' && (process.env['VITEST'] ?? '') !== '0' && (process.env['VITEST'] ?? '') !== 'false';

if (__isDirectRun && !__isVitest) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
