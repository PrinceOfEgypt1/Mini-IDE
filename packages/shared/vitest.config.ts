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
        autoUpdate: false, // CRITICAL: impede atualização automática
        perFile: false, // threshold global, não por arquivo
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
