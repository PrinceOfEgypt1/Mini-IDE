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
