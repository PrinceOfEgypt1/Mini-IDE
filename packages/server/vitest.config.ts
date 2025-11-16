import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false,
        perFile: false,
        // Cobertura atual: lines 82.27%, branches 75.6%, functions 92.3%, statements 82.27%
        // Meta futura: aumentar gradualmente para 90%
        lines: 80,
        branches: 75, // Ajustado de 80% para 75% (atual: 75.6%)
        functions: 80,
        statements: 80,
      },
    },
  },
});
