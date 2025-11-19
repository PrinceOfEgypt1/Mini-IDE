/**
 * Configuração global de testes para Vitest
 */

import '@testing-library/jest-dom';

// Mock de import.meta.env para testes
Object.defineProperty(globalThis, 'import', {
  value: {
    meta: {
      env: {
        VITE_MINI_IDE_SERVER_URL: 'http://127.0.0.1:3200',
      },
    },
  },
  writable: true,
});

// Mock de fetch global para testes (substituir quando necessário nos testes individuais)
globalThis.fetch = vi.fn();
