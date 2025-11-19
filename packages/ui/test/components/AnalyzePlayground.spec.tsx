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
      new Error('Network error'),
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
        }),
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
