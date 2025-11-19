#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11c_fix_test_failures.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Corrigir 5 testes falhando no pacote @mini-ide/ui
#
# Problemas corrigidos:
#   1. ServerStatus.spec.tsx - 4 testes com timeout (fake timers + async/await)
#   2. AnalyzePlayground.spec.tsx - 1 teste falhando (bug: setState não chamado)
#   3. AnalyzePlayground.tsx - Bug no tratamento de erro de validação
#
# Arquivos modificados:
#   - packages/ui/src/components/AnalyzePlayground.tsx (correção de bug)
#   - packages/ui/test/components/ServerStatus.spec.tsx (reescrita completa)
#   - packages/ui/test/components/AnalyzePlayground.spec.tsx (ajuste)
#
# Como reverter:
#   git restore packages/ui/
#
################################################################################

echo "[info] Corrigindo testes falhando no pacote @mini-ide/ui..."

# 1. Corrigir bug no AnalyzePlayground.tsx
echo "[info] Corrigindo bug em AnalyzePlayground.tsx..."

cat <<'EOF' > packages/ui/src/components/AnalyzePlayground.tsx
/**
 * Playground de requisições /analyze
 * 
 * @packageDocumentation
 * @module components/AnalyzePlayground
 * 
 * Componente que permite testar o endpoint POST /analyze interativamente.
 * Inclui formulário com textarea (text) e campo numérico (maxLen), exibindo
 * o resultado estruturado ou mensagens de erro amigáveis.
 */

import { useState } from 'react';
import { getAnalyzeUrl } from '../config/server.js';

/**
 * Estrutura da resposta do /analyze
 * (baseada no contrato oficial do servidor)
 */
export interface AnalyzeResponse {
  summary: string;
  inputLength: number;
  outputLength: number;
  timestamp: string;
  requestId: string;
  budgetUsed?: number;
  budgetRemaining?: number;
}

/**
 * Estado do componente durante a requisição
 */
type RequestState = 'idle' | 'loading' | 'success' | 'error';

/**
 * Propriedades do componente AnalyzePlayground
 */
export interface AnalyzePlaygroundProps {
  /**
   * Valor padrão para maxLen (padrão: 100)
   */
  defaultMaxLen?: number;
}

/**
 * Playground interativo para testar POST /analyze
 * 
 * @param props - Propriedades do componente
 * @returns Elemento React com formulário e resultado
 * 
 * @example
 * ```tsx
 * <AnalyzePlayground defaultMaxLen={150} />
 * ```
 */
export function AnalyzePlayground({ defaultMaxLen = 100 }: AnalyzePlaygroundProps) {
  const [text, setText] = useState('');
  const [maxLen, setMaxLen] = useState(defaultMaxLen);
  const [state, setState] = useState<RequestState>('idle');
  const [result, setResult] = useState<AnalyzeResponse | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleAnalyze = async () => {
    if (!text.trim()) {
      setErrorMessage('Por favor, insira um texto para análise.');
      setState('error'); // FIX: Adicionar setState para renderizar o erro
      return;
    }

    setState('loading');
    setErrorMessage(null);
    setResult(null);

    try {
      const response = await fetch(getAnalyzeUrl(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, maxLen }),
      });

      if (!response.ok) {
        // Erro 4xx ou 5xx
        const errorData = await response.json().catch(() => ({}));
        setErrorMessage(
          errorData.message || `Erro ao processar análise (${response.status}). Tente novamente.`
        );
        setState('error');
        return;
      }

      const data: AnalyzeResponse = await response.json();
      setResult(data);
      setState('success');
    } catch (error) {
      // Erro de rede
      console.error('[AnalyzePlayground] Erro de rede:', error);
      setErrorMessage('Erro de conexão. Verifique se o servidor está rodando.');
      setState('error');
    }
  };

  return (
    <div className="card" data-testid="analyze-playground">
      <h3>Playground /analyze</h3>
      <p className="muted" style={{ marginBottom: '12px' }}>
        Teste o endpoint POST /analyze interativamente.
      </p>

      <div style={{ marginBottom: '12px' }}>
        <label htmlFor="analyze-text" style={{ display: 'block', marginBottom: '6px' }}>
          Texto para análise:
        </label>
        <textarea
          id="analyze-text"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Digite o texto que deseja analisar..."
          rows={6}
          style={{ width: '100%' }}
          disabled={state === 'loading'}
        />
      </div>

      <div style={{ marginBottom: '12px' }}>
        <label htmlFor="analyze-maxlen" style={{ display: 'block', marginBottom: '6px' }}>
          Tamanho máximo do resumo (maxLen):
        </label>
        <input
          id="analyze-maxlen"
          type="number"
          value={maxLen}
          onChange={(e) => setMaxLen(parseInt(e.target.value, 10) || defaultMaxLen)}
          min={1}
          max={1000}
          style={{
            height: '34px',
            borderRadius: '10px',
            border: '1px solid var(--border)',
            background: 'var(--panel-2)',
            color: 'var(--text)',
            padding: '0 10px',
            width: '120px',
          }}
          disabled={state === 'loading'}
        />
      </div>

      <button
        className={`btn primary ${state === 'loading' ? 'loading' : ''}`}
        onClick={handleAnalyze}
        disabled={state === 'loading'}
        data-testid="analyze-button"
      >
        {state === 'loading' ? '⏳ Analisando...' : 'Analisar'}
      </button>

      {/* Resultado */}
      {state === 'success' && result && (
        <div
          className="card"
          style={{ marginTop: '16px', background: 'var(--panel-3)' }}
          data-testid="analyze-result"
        >
          <h4>Resultado da análise</h4>
          <div style={{ display: 'grid', gap: '8px' }}>
            <div>
              <strong>Summary:</strong> {result.summary}
            </div>
            <div>
              <strong>Input Length:</strong> {result.inputLength}
            </div>
            <div>
              <strong>Output Length:</strong> {result.outputLength}
            </div>
            <div className="muted" style={{ fontSize: '12px' }}>
              <strong>Timestamp:</strong> {result.timestamp}
            </div>
            <div className="muted" style={{ fontSize: '12px' }}>
              <strong>Request ID:</strong> {result.requestId}
            </div>
            {result.budgetUsed !== undefined && (
              <div className="muted" style={{ fontSize: '12px' }}>
                <strong>Budget Used:</strong> {result.budgetUsed}
              </div>
            )}
            {result.budgetRemaining !== undefined && (
              <div className="muted" style={{ fontSize: '12px' }}>
                <strong>Budget Remaining:</strong> {result.budgetRemaining}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Erro */}
      {state === 'error' && errorMessage && (
        <div
          className="card warn"
          style={{ marginTop: '16px' }}
          data-testid="analyze-error"
        >
          <strong>⚠️ Erro</strong>
          <p>{errorMessage}</p>
        </div>
      )}
    </div>
  );
}
EOF

echo "[ok] AnalyzePlayground.tsx corrigido (setState('error') adicionado)"

# 2. Reescrever ServerStatus.spec.tsx sem fake timers
echo "[info] Reescrevendo ServerStatus.spec.tsx (sem fake timers)..."

cat <<'EOF' > packages/ui/test/components/ServerStatus.spec.tsx
/**
 * Testes para componente ServerStatus
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { ServerStatus } from '../../src/components/ServerStatus.js';

describe('ServerStatus', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('deve renderizar com estado inicial "Verificando..."', () => {
    // Mock fetch que nunca resolve (para manter estado inicial)
    globalThis.fetch = vi.fn(() => new Promise(() => {}));
    
    render(<ServerStatus pollInterval={5000} />);
    
    const status = screen.getByTestId('server-status');
    expect(status).toBeInTheDocument();
    expect(status.textContent).toContain('Verificando');
  });

  it('deve exibir "Servidor online" quando /healthz retorna 200', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
    });

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor online');
      expect(status.className).toContain('ok');
    });

    expect(globalThis.fetch).toHaveBeenCalledTimes(1);
  });

  it('deve exibir "Servidor indisponível" quando /healthz falha', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 500,
    });

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor indisponível');
      expect(status.className).toContain('warn');
    });

    expect(globalThis.fetch).toHaveBeenCalledTimes(1);
  });

  it('deve exibir "Servidor indisponível" em caso de erro de rede', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor indisponível');
      expect(status.className).toContain('warn');
    });

    expect(globalThis.fetch).toHaveBeenCalledTimes(1);
  });

  it('deve fazer polling periódico conforme pollInterval', async () => {
    vi.useFakeTimers();
    
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
    });

    render(<ServerStatus pollInterval={1000} />);

    // Aguardar primeira chamada
    await vi.waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(1);
    });

    // Avançar 1 segundo
    vi.advanceTimersByTime(1000);

    // Aguardar segunda chamada
    await vi.waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(2);
    });

    // Avançar mais 1 segundo
    vi.advanceTimersByTime(1000);

    // Aguardar terceira chamada
    await vi.waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(3);
    });

    vi.useRealTimers();
  });
});
EOF

echo "[ok] ServerStatus.spec.tsx reescrito (sem deadlock com fake timers)"

# 3. Ajustar AnalyzePlayground.spec.tsx para aguardar o estado corretamente
echo "[info] Ajustando AnalyzePlayground.spec.tsx..."

cat <<'EOF' > packages/ui/test/components/AnalyzePlayground.spec.tsx
/**
 * Testes para componente AnalyzePlayground
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AnalyzePlayground } from '../../src/components/AnalyzePlayground.js';

describe('AnalyzePlayground', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('deve renderizar formulário com textarea, input e botão', () => {
    render(<AnalyzePlayground defaultMaxLen={100} />);

    expect(screen.getByLabelText(/Texto para análise/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Tamanho máximo/i)).toBeInTheDocument();
    expect(screen.getByTestId('analyze-button')).toBeInTheDocument();
  });

  it('deve mostrar erro se tentar analisar sem texto', async () => {
    const user = userEvent.setup();
    render(<AnalyzePlayground defaultMaxLen={100} />);

    const button = screen.getByTestId('analyze-button');
    await user.click(button);

    // Aguardar que o estado 'error' seja setado e o componente renderize
    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
    });

    expect(screen.getByText(/insira um texto/i)).toBeInTheDocument();
  });

  it('deve exibir resultado quando /analyze retorna 200', async () => {
    const user = userEvent.setup();
    
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        summary: 'Test summary',
        inputLength: 50,
        outputLength: 12,
        timestamp: '2025-11-16T12:00:00Z',
        requestId: 'req-123',
      }),
    });

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await user.type(textarea, 'Olá Mini-IDE, analise este texto!');

    const button = screen.getByTestId('analyze-button');
    await user.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-result')).toBeInTheDocument();
    });

    expect(screen.getByText(/Test summary/i)).toBeInTheDocument();
    expect(screen.getByText(/Input Length:/i)).toBeInTheDocument();
  });

  it('deve exibir erro quando /analyze retorna 4xx', async () => {
    const user = userEvent.setup();
    
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 400,
      json: async () => ({ message: 'Invalid request' }),
    });

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await user.type(textarea, 'Texto de teste');

    const button = screen.getByTestId('analyze-button');
    await user.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
    });

    expect(screen.getByText(/Invalid request/i)).toBeInTheDocument();
  });

  it('deve exibir erro de rede quando fetch falha', async () => {
    const user = userEvent.setup();
    
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await user.type(textarea, 'Texto de teste');

    const button = screen.getByTestId('analyze-button');
    await user.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
    });

    expect(screen.getByText(/Erro de conexão/i)).toBeInTheDocument();
  });

  it('deve desabilitar campos durante loading', async () => {
    const user = userEvent.setup();
    
    // Mock de fetch que demora para resolver
    globalThis.fetch = vi.fn().mockImplementation(
      () =>
        new Promise((resolve) => {
          setTimeout(
            () =>
              resolve({
                ok: true,
                status: 200,
                json: async () => ({
                  summary: 'Result',
                  inputLength: 10,
                  outputLength: 10,
                  timestamp: '2025-11-16T12:00:00Z',
                  requestId: 'req-456',
                }),
              }),
            100
          );
        })
    );

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await user.type(textarea, 'Test');

    const button = screen.getByTestId('analyze-button');
    await user.click(button);

    // Verificar que o botão está desabilitado durante loading
    expect(button).toBeDisabled();
    expect(button.textContent).toContain('Analisando');

    // Aguardar resolução
    await waitFor(
      () => {
        expect(screen.getByTestId('analyze-result')).toBeInTheDocument();
      },
      { timeout: 200 }
    );
  });

  it('deve usar defaultMaxLen quando fornecido', () => {
    render(<AnalyzePlayground defaultMaxLen={150} />);

    const input = screen.getByLabelText(/Tamanho máximo/i) as HTMLInputElement;
    expect(input.value).toBe('150');
  });
});
EOF

echo "[ok] AnalyzePlayground.spec.tsx ajustado (userEvent.setup + waitFor)"

echo ""
echo "============================================================"
echo "✅ CORREÇÃO CONCLUÍDA"
echo "============================================================"
echo ""
echo "Mudanças aplicadas:"
echo ""
echo "  ✅ AnalyzePlayground.tsx:"
echo "     - Corrigido bug: setState('error') agora é chamado na validação"
echo "     - Erro renderiza corretamente quando texto vazio"
echo ""
echo "  ✅ ServerStatus.spec.tsx:"
echo "     - Reescrito completamente sem uso incorreto de fake timers"
echo "     - Usa waitFor() para aguardar estados async"
echo "     - Teste de polling usa vi.waitFor() em vez de waitFor()"
echo "     - Remove deadlock entre fake timers e async/await"
echo ""
echo "  ✅ AnalyzePlayground.spec.tsx:"
echo "     - Usa userEvent.setup() (padrão recomendado v14+)"
echo "     - Aguarda renderização de erro com waitFor()"
echo "     - Testes mais robustos e sem race conditions"
echo ""
echo "============================================================"
echo "🔄 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Executar testes novamente (deve passar 22/22):"
echo "   pnpm --filter @mini-ide/ui test"
echo ""
echo "2. Executar com coverage (threshold 80%):"
echo "   pnpm --filter @mini-ide/ui test:coverage"
echo ""
echo "3. Validar pipeline completa:"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "4. Se todos passarem: pipeline verde! ✅"
echo ""
echo "============================================================"
echo "📊 TESTES CORRIGIDOS"
echo "============================================================"
echo ""
echo "  ServerStatus.spec.tsx:"
echo "  ✅ deve renderizar com estado inicial 'Verificando...'"
echo "  ✅ deve exibir 'Servidor online' quando /healthz retorna 200"
echo "  ✅ deve exibir 'Servidor indisponível' quando /healthz falha"
echo "  ✅ deve exibir 'Servidor indisponível' em caso de erro de rede"
echo "  ✅ deve fazer polling periódico conforme pollInterval"
echo ""
echo "  AnalyzePlayground.spec.tsx:"
echo "  ✅ deve mostrar erro se tentar analisar sem texto"
echo ""
echo "  Total: 6 testes corrigidos (5 falhando → 0 falhando)"
echo ""
echo "  Resultado esperado: 22 passed (22) ✅"
echo ""
echo "============================================================"
echo "🐛 BUGS CORRIGIDOS"
echo "============================================================"
echo ""
echo "  Bug #1: AnalyzePlayground não renderizava erro de validação"
echo "  Causa: setState('error') não era chamado"
echo "  Fix: Adicionada linha setState('error') na validação de texto vazio"
echo ""
echo "  Bug #2: Testes ServerStatus com deadlock (timeout 5s)"
echo "  Causa: Fake timers impediam resolução de Promises async"
echo "  Fix: Removido fake timers dos testes async, usado waitFor()"
echo ""
echo "  Bug #3: Teste de polling com fake timers travava"
echo "  Causa: waitFor() não funciona com fake timers"
echo "  Fix: Usado vi.waitFor() que é compatível com fake timers"
echo ""
echo "============================================================"
