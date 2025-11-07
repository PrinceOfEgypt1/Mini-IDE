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
