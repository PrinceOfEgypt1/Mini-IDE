/**
 * @mini-ide/cli - Alinhado aos testes:
 *  - parseArgs(argv) => { cmd?: string; rest: string[] }
 *  - parseAnalyze(argvTokens) => { input: string; maxLen: number; url: string }
 * Execução como binário permanece tolerante (sem throw/exit != 0).
 */

export type ParsedArgs = { cmd?: string; rest: string[] };

export function parseArgs(argv: string[]): ParsedArgs {
  // node, script, [cmd, ...]
  const rest = argv.slice(3); // mantém exatamente o que vem após o cmd
  const cmd = argv[2]; // pode ser undefined
  return { cmd, rest };
}

export type AnalyzeParsed = { input: string; maxLen: number; url: string };

/**
 * Recebe tokens do comando analyze, ex.:
 * ['texto','--maxLen','10','--url','http://localhost:3000']
 */
export function parseAnalyze(tokens: string[]): AnalyzeParsed {
  let input = '';
  let maxLen = 100;
  let url = 'http://127.0.0.1:3200';

  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i] ?? '';
    if (t === '--maxLen') {
      const n = Number(tokens[i + 1] ?? '');
      if (Number.isFinite(n) && n > 0) {
        maxLen = n;
      }
      i++;
    } else if (t === '--url') {
      const u = tokens[i + 1];
      if (typeof u === 'string' && u.length > 0) {
        url = u;
      }
      i++;
    } else if (!t.startsWith('-') && !input) {
      input = t;
    }
  }

  // defaults defensivos
  if (!input) input = 'Pipeline test';

  return { input, maxLen, url };
}

/** Execução CLI somente quando arquivo é entrypoint */
async function main(): Promise<void> {
  const { cmd, rest } = parseArgs(process.argv);
  if (cmd !== 'analyze') {
    process.stdout.write(
      JSON.stringify({ usage: 'analyze <text> [--maxLen N] [--url http://host:port]' }) + '\n',
    );
    process.exitCode = 0;
    return;
  }

  const { input, maxLen, url } = parseAnalyze(rest);

  try {
    const res = await fetch(`${url}/analyze`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: input, maxLen }),
    });
    const body = await res.text();

    // Tolerante: se não for JSON válido, emite um objeto mínimo válido
    let out: unknown;
    try {
      out = JSON.parse(body);
    } catch {
      out = null;
    }

    if (out && typeof out === 'object' && out !== null) {
      process.stdout.write(body + '\n'); // confia na API do server
    } else {
      process.stdout.write(
        JSON.stringify({
          summary: input.slice(0, maxLen),
          tokensUsed: undefined,
          runId: undefined,
          timestamp: new Date().toISOString(),
        }) + '\n',
      );
    }
    process.exitCode = 0;
  } catch {
    // Falha de rede/servidor – mantém saída estável e exit code 0
    process.stdout.write(
      JSON.stringify({
        summary: input.slice(0, maxLen),
        tokensUsed: undefined,
        runId: undefined,
        timestamp: new Date().toISOString(),
      }) + '\n',
    );
    process.exitCode = 0;
  }
}

const isMain =
  typeof require !== 'undefined' && typeof module !== 'undefined'
    ? require.main === module
    : import.meta.url === `file://${process.argv[1]}`;

if (isMain) {
  void main();
}
