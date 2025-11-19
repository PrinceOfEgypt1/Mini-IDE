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
      new Error('Network error'),
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
      { timeout: 200 },
    );
  });
});
