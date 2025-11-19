#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 26_fix_all_typescript_strict_errors.sh
# Objetivo: Corrigir TODOS os 11 erros de TypeScript strict de uma vez
# 
# Erros a corrigir:
#   - AnalyzePlayground.tsx: 5 erros (unsafe any, no-misused-promises)
#   - ServerStatus.tsx: 2 erros (no-floating-promises, no-misused-promises)
#   - AnalyzePlayground.spec.tsx: 4 erros (require-await, unnecessary assertion)
################################################################################

echo "[info] Corrigindo TODOS os erros de TypeScript strict..."
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. AnalyzePlayground.tsx - Corrigir tipos any e promises
# ═══════════════════════════════════════════════════════════════

echo "[1/3] Corrigindo AnalyzePlayground.tsx..."

cat <<'EOF' > packages/ui/src/components/AnalyzePlayground.tsx
import { useState } from 'react';
import { getServerConfig } from '../config/server.js';
import styles from './AnalyzePlayground.module.css';

interface AnalyzeResponse {
  summary: string;
  inputLength: number;
  outputLength: number;
  tokensUsed: number;
}

/**
 * AnalyzePlayground - Componente para testar o endpoint /analyze
 *
 * Permite enviar texto para análise e visualizar a resposta.
 */
export const AnalyzePlayground: React.FC = () => {
  const [text, setText] = useState('');
  const [maxLen, setMaxLen] = useState(100);
  const [response, setResponse] = useState<AnalyzeResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async (): Promise<void> => {
    if (!text.trim()) {
      setError('Por favor, digite algum texto');
      return;
    }

    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      const config = getServerConfig();
      const res = await fetch(`${config.baseUrl}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: text.trim(),
          maxLen,
        }),
      });

      if (!res.ok) {
        let errorMsg = `Erro ${res.status}`;
        try {
          const errorData = (await res.json()) as { error?: string };
          if (errorData.error) {
            errorMsg = errorData.error;
          }
        } catch {
          // Se não conseguir parsear JSON, usa mensagem padrão
        }
        throw new Error(errorMsg);
      }

      const data = (await res.json()) as AnalyzeResponse;
      setResponse(data);
    } catch (err) {
      console.error('[AnalyzePlayground] Erro ao analisar:', err);
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Erro desconhecido ao analisar texto');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.playground}>
      <div className={styles.inputGroup}>
        <label htmlFor="analyze-text" className={styles.label}>
          Texto para análise:
        </label>
        <textarea
          id="analyze-text"
          className={styles.textarea}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Digite o texto que deseja analisar..."
          rows={6}
          disabled={loading}
        />
      </div>

      <div className={styles.inputGroup}>
        <label htmlFor="analyze-maxlen" className={styles.label}>
          Comprimento máximo da resposta:
        </label>
        <input
          id="analyze-maxlen"
          type="number"
          className={styles.input}
          value={maxLen}
          onChange={(e) => setMaxLen(Number(e.target.value))}
          min={1}
          max={1000}
          disabled={loading}
        />
      </div>

      <button
        className={styles.button}
        onClick={() => {
          void handleAnalyze();
        }}
        disabled={loading || !text.trim()}
      >
        {loading ? 'Analisando...' : 'Analisar'}
      </button>

      {error && (
        <div className={styles.error} role="alert">
          <strong>Erro:</strong> {error}
        </div>
      )}

      {response && (
        <div className={styles.response}>
          <h3 className={styles.responseTitle}>Resultado:</h3>
          <div className={styles.responseContent}>
            <p>
              <strong>Resumo:</strong> {response.summary}
            </p>
            <div className={styles.metrics}>
              <span className={styles.metric}>
                Entrada: {response.inputLength} chars
              </span>
              <span className={styles.metric}>
                Saída: {response.outputLength} chars
              </span>
              <span className={styles.metric}>Tokens: {response.tokensUsed}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
EOF

echo "  ✓ AnalyzePlayground.tsx corrigido"

# ═══════════════════════════════════════════════════════════════
# 2. ServerStatus.tsx - Corrigir floating promises
# ═══════════════════════════════════════════════════════════════

echo "[2/3] Corrigindo ServerStatus.tsx..."

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
export const ServerStatus: React.FC<ServerStatusProps> = ({
  pollInterval = 30000,
}) => {
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
    <div className={getStatusClass()} role="status" aria-live="polite">
      <span className={styles.indicator} />
      <span className={styles.text}>{getStatusText()}</span>
    </div>
  );
};
EOF

echo "  ✓ ServerStatus.tsx corrigido"

# ═══════════════════════════════════════════════════════════════
# 3. AnalyzePlayground.spec.tsx - Corrigir async e assertions
# ═══════════════════════════════════════════════════════════════

echo "[3/3] Corrigindo AnalyzePlayground.spec.tsx..."

cat <<'EOF' > packages/ui/test/components/AnalyzePlayground.spec.tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { AnalyzePlayground } from '../../src/components/AnalyzePlayground.js';

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

echo "  ✓ AnalyzePlayground.spec.tsx corrigido"

# ═══════════════════════════════════════════════════════════════
# 4. VALIDAÇÃO
# ═══════════════════════════════════════════════════════════════

echo ""
echo "[info] Validando correções..."
echo ""

# ESLint nos arquivos corrigidos
echo "→ Validando ESLint nos arquivos corrigidos..."
if pnpm --filter @mini-ide/ui exec eslint \
  src/components/AnalyzePlayground.tsx \
  src/components/ServerStatus.tsx \
  test/components/AnalyzePlayground.spec.tsx \
  --max-warnings=0; then
  echo "✅ ESLint passou nos arquivos corrigidos"
else
  echo "❌ ESLint ainda com erros"
  exit 1
fi

echo ""
echo "→ Validando testes..."
if pnpm --filter @mini-ide/ui test > /dev/null 2>&1; then
  echo "✅ Testes passaram"
else
  echo "❌ Testes falharam"
  exit 1
fi

echo ""
echo "→ Validando TypeScript..."
if pnpm --filter @mini-ide/ui typecheck > /dev/null 2>&1; then
  echo "✅ TypeCheck passou"
else
  echo "❌ TypeCheck falhou"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          TODOS OS ERROS TYPESCRIPT STRICT CORRIGIDOS ✓        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Correções aplicadas:"
echo "  ✓ AnalyzePlayground.tsx: tipos any corrigidos, promises com void"
echo "  ✓ ServerStatus.tsx: floating promises corrigidas com void"
echo "  ✓ AnalyzePlayground.spec.tsx: async/await e assertions corrigidos"
echo ""
echo "Próximo passo:"
echo "  git add ."
echo "  git commit (o pre-commit hook agora vai passar)"
echo ""
echo "[info] Correção concluída!"
