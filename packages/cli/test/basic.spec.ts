import { describe, it, expect } from 'vitest';
import { hello } from '../src/index';

describe('basic', () => {
  it('hello()', () => {
    expect(hello('mini-ide')).toBe('hello, mini-ide');
  });
});
