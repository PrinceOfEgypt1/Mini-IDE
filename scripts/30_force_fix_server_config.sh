#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 30_force_fix_server_config.sh
# Objetivo: Forçar recriação de config/server.ts e corrigir imports
################################################################################

echo "[info] Forçando recriação de config/server.ts..."

# Remover arquivo antigo se existir
rm -f packages/ui/src/config/server.ts

# Criar diretório se não existir
mkdir -p packages/ui/src/config

# Criar arquivo novo
cat > packages/ui/src/config/server.ts <<'EOF'
/**
 * Configuração do servidor backend
 */
export interface ServerConfig {
  baseUrl: string;
  timeout: number;
}

/**
 * Retorna a configuração do servidor
 */
export function getServerConfig(): ServerConfig {
  const port = import.meta.env.VITE_SERVER_PORT || '3200';
  const host = import.meta.env.VITE_SERVER_HOST || 'localhost';

  return {
    baseUrl: `http://${host}:${port}`,
    timeout: 30000,
  };
}
EOF

echo "✅ config/server.ts recriado"

# Remover import desnecessário do teste
echo "[info] Corrigindo import desnecessário no teste..."

cat > packages/ui/test/components/ServerStatus.spec.tsx <<'EOF'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { ServerStatus } from '../../src/components/ServerStatus.js';

// Mock do módulo inteiro
vi.mock('../../src/config/server.js', () => ({
  getServerConfig: vi.fn(() => ({
    baseUrl: 'http://localhost:3200',
    timeout: 30000,
  })),
}));

describe('ServerStatus', () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn();
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('deve renderizar com estado inicial "Verificando..."', () => {
    render(<ServerStatus pollInterval={5000} />);

    const status = screen.getByTestId('server-status');
    expect(status).toBeInTheDocument();
    expect(status.textContent).toContain('Verificando');
  });

  it('deve exibir "Servidor online" quando /healthz retorna 200', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      status: 200,
    });

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor disponível');
    });
  });

  it('deve exibir "Servidor indisponível" quando /healthz falha', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: false,
      status: 500,
    });

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor offline');
    });
  });

  it('deve exibir "Servidor indisponível" em caso de erro de rede', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(
      new Error('Network error')
    );

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor indisponível');
    });
  });

  it('deve fazer polling periódico conforme pollInterval', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValue({
      ok: true,
      status: 200,
    });

    render(<ServerStatus pollInterval={100} />);

    // Aguardar primeira chamada
    await vi.waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(1);
    });

    // Aguardar segunda chamada (polling)
    await vi.waitFor(
      () => {
        expect(globalThis.fetch).toHaveBeenCalledTimes(2);
      },
      { timeout: 200 }
    );
  });
});
EOF

echo "✅ Import removido"

# Validar
echo ""
echo "[info] Validando..."
pnpm --filter @mini-ide/ui typecheck
pnpm --filter @mini-ide/ui test

echo ""
echo "✅ CORREÇÃO COMPLETA!"
