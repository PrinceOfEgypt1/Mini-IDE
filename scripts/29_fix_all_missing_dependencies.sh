#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 29_fix_all_missing_dependencies.sh
# Objetivo: Corrigir DEFINITIVAMENTE todos os problemas de dependências
#
# Problemas identificados:
#   1. getServerConfig não existe em config/server.ts
#   2. Testes esperam data-testid que não existe
#   3. Testes não mocam getServerConfig adequadamente
#
# Solução:
#   1. Restaurar config/server.ts original (que funciona)
#   2. Adicionar data-testid ao ServerStatus
#   3. Mockar getServerConfig nos testes
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║     CORREÇÃO DEFINITIVA - Método Científico Aplicado          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. Verificar e restaurar config/server.ts
# ═══════════════════════════════════════════════════════════════

echo "[1/4] Verificando config/server.ts..."

if [ ! -f packages/ui/src/config/server.ts ]; then
  echo "  ⚠ Arquivo não existe, criando..."
  cat <<'EOF' > packages/ui/src/config/server.ts
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
  echo "  ✓ config/server.ts criado"
else
  echo "  ✓ config/server.ts já existe"
fi

# ═══════════════════════════════════════════════════════════════
# 2. Adicionar data-testid ao ServerStatus
# ═══════════════════════════════════════════════════════════════

echo "[2/4] Adicionando data-testid ao ServerStatus..."

cat <<'EOF' > packages/ui/src/components/ServerStatus.tsx
import { useState, useEffect } from 'react';
import { getServerConfig } from '../config/server.js';
import styles from './ServerStatus.module.css';

type ServerState = 'checking' | 'online' | 'offline' | 'error';

interface ServerStatusProps {
  pollInterval?: number;
}

/**
 * ServerStatus - Indicador visual do status do servidor
 *
 * Verifica periodicamente o endpoint /healthz e exibe o status.
 */
export function ServerStatus({ pollInterval = 30000 }: ServerStatusProps) {
  const [status, setStatus] = useState<ServerState>('checking');

  useEffect(() => {
    const checkHealth = async (): Promise<void> => {
      try {
        const config = getServerConfig();
        const response = await fetch(`${config.baseUrl}/healthz`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (response.ok) {
          setStatus('online');
        } else {
          setStatus('offline');
        }
      } catch (error) {
        console.error('[ServerStatus] Erro ao verificar /healthz:', error);
        setStatus('error');
      }
    };

    // Primeira verificação imediata
    void checkHealth();

    // Configurar polling
    const intervalId = setInterval(() => {
      void checkHealth();
    }, pollInterval);

    return () => clearInterval(intervalId);
  }, [pollInterval]);

  const getStatusText = (): string => {
    switch (status) {
      case 'checking':
        return 'Verificando servidor...';
      case 'online':
        return 'Servidor disponível';
      case 'offline':
        return 'Servidor offline';
      case 'error':
        return 'Servidor indisponível';
      default:
        return 'Status desconhecido';
    }
  };

  const getStatusClass = (): string => {
    return `${styles.status} ${styles[status]}`;
  };

  return (
    <div 
      className={getStatusClass()} 
      role="status" 
      aria-live="polite"
      data-testid="server-status"
    >
      <span className={styles.indicator} />
      <span className={styles.text}>{getStatusText()}</span>
    </div>
  );
}
EOF

echo "  ✓ ServerStatus com data-testid"

# ═══════════════════════════════════════════════════════════════
# 3. Corrigir testes para mockar getServerConfig
# ═══════════════════════════════════════════════════════════════

echo "[3/4] Corrigindo testes com mocks adequados..."

# ServerStatus.spec.tsx
cat <<'EOF' > packages/ui/test/components/ServerStatus.spec.tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { ServerStatus } from '../../src/components/ServerStatus.js';
import * as serverConfig from '../../src/config/server.js';

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

# AnalyzePlayground.spec.tsx
cat <<'EOF' > packages/ui/test/components/AnalyzePlayground.spec.tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { AnalyzePlayground } from '../../src/components/AnalyzePlayground.js';

// Mock do módulo getServerConfig
vi.mock('../../src/config/server.js', () => ({
  getServerConfig: vi.fn(() => ({
    baseUrl: 'http://localhost:3200',
    timeout: 30000,
  })),
}));

describe('AnalyzePlayground', () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('deve renderizar campos de entrada', () => {
    render(<AnalyzePlayground />);

    expect(screen.getByPlaceholderText(/digite o texto/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/comprimento máximo/i)).toBeInTheDocument();
    expect(screen.getByText('Analisar')).toBeInTheDocument();
  });

  it('deve desabilitar botão quando texto está vazio', () => {
    render(<AnalyzePlayground />);

    const button = screen.getByText('Analisar');
    expect(button).toBeDisabled();
  });

  it('deve habilitar botão quando texto é digitado', () => {
    render(<AnalyzePlayground />);

    const textarea = screen.getByPlaceholderText(/digite o texto/i);
    fireEvent.change(textarea, { target: { value: 'Teste' } });

    const button = screen.getByText('Analisar');
    expect(button).not.toBeDisabled();
  });

  it('deve fazer requisição ao clicar em Analisar', async () => {
    const mockResponse = {
      summary: 'Análise de teste',
      inputLength: 5,
      outputLength: 17,
      tokensUsed: 10,
    };

    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(mockResponse),
    });

    render(<AnalyzePlayground />);

    const textarea = screen.getByPlaceholderText(/digite o texto/i);
    fireEvent.change(textarea, { target: { value: 'Teste' } });

    const button = screen.getByText('Analisar');
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/Resultado:/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/Análise de teste/i)).toBeInTheDocument();
  });

  it('deve exibir erro quando requisição falha', async () => {
    const errorMessage = 'Erro de teste';

    (globalThis.fetch as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ok: false,
      status: 400,
      json: () => Promise.resolve({ error: errorMessage }),
    });

    render(<AnalyzePlayground />);

    const textarea = screen.getByPlaceholderText(/digite o texto/i);
    fireEvent.change(textarea, { target: { value: 'Teste' } });

    const button = screen.getByText('Analisar');
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/Erro:/i)).toBeInTheDocument();
    });

    expect(screen.getByText(errorMessage)).toBeInTheDocument();
  });

  it('deve exibir erro de rede quando fetch falha', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockRejectedValueOnce(
      new Error('Network error')
    );

    render(<AnalyzePlayground />);

    const textarea = screen.getByPlaceholderText(/digite o texto/i);
    fireEvent.change(textarea, { target: { value: 'Teste' } });

    const button = screen.getByText('Analisar');
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/Erro:/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/Network error/i)).toBeInTheDocument();
  });

  it('deve permitir alterar maxLen', () => {
    render(<AnalyzePlayground />);

    const input = screen.getByLabelText(/comprimento máximo/i);
    fireEvent.change(input, { target: { value: '200' } });

    expect(input).toHaveValue(200);
  });

  it('deve mostrar estado de loading durante requisição', async () => {
    (globalThis.fetch as ReturnType<typeof vi.fn>).mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          setTimeout(() => {
            resolve({
              ok: true,
              json: () =>
                Promise.resolve({
                  summary: 'Test',
                  inputLength: 4,
                  outputLength: 4,
                  tokensUsed: 1,
                }),
            });
          }, 100);
        })
    );

    render(<AnalyzePlayground />);

    const textarea = screen.getByPlaceholderText(/digite o texto/i);
    fireEvent.change(textarea, { target: { value: 'Teste' } });

    const button = screen.getByText('Analisar');
    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText('Analisando...')).toBeInTheDocument();
    });

    await waitFor(() => {
      expect(screen.getByText('Analisar')).toBeInTheDocument();
    });
  });
});
EOF

echo "  ✓ Testes corrigidos com mocks"

# ═══════════════════════════════════════════════════════════════
# 4. VALIDAÇÃO COMPLETA
# ═══════════════════════════════════════════════════════════════

echo "[4/4] Executando validação completa..."
echo ""

echo "→ TypeScript..."
if pnpm --filter @mini-ide/ui typecheck > /dev/null 2>&1; then
  echo "  ✅ TypeCheck passou"
else
  echo "  ❌ TypeCheck falhou"
  pnpm --filter @mini-ide/ui typecheck
  exit 1
fi

echo "→ ESLint..."
if pnpm --filter @mini-ide/ui lint > /dev/null 2>&1; then
  echo "  ✅ ESLint passou"
else
  echo "  ❌ ESLint falhou"
  pnpm --filter @mini-ide/ui lint
  exit 1
fi

echo "→ Testes..."
if pnpm --filter @mini-ide/ui test; then
  echo "  ✅ Testes passaram"
else
  echo "  ❌ Testes falharam"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           CORREÇÃO COMPLETA - 100% FUNCIONAL ✓                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ config/server.ts criado/restaurado"
echo "✅ ServerStatus com data-testid"
echo "✅ Testes com mocks adequados"
echo "✅ TypeScript, ESLint e Testes passando"
echo ""
echo "Próximo passo:"
echo "  git add ."
echo "  git commit -m 'feat(ui)!: restaurar wireframe MiniIDE-Explore.html'"
echo ""
echo "[info] Sistema pronto para commit!"
