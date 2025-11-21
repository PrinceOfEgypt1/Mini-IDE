// packages/ui/test/components/Toast.test.tsx
import { describe, expect, it, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Toast } from '../../src/components/common/Toast.js';
import type { ToastData } from '../../src/contexts/ToastContext.js';

describe('Toast', () => {
  it('deve renderizar mensagem e tipo', () => {
    const toast: ToastData = {
      id: 1,
      type: 'success',
      message: 'Operação concluída com sucesso',
    };

    const handleClose = vi.fn();

    render(<Toast toast={toast} onClose={handleClose} />);

    expect(screen.getByText(/opera[cç][aã]o conclu[ií]da com sucesso/i)).toBeInTheDocument();
    const container = screen.getByRole('status');
    expect(container).toHaveAttribute('data-type', 'success');
  });

  it('deve chamar onClose ao clicar no botão de fechar', () => {
    const toast: ToastData = {
      id: 2,
      type: 'error',
      message: 'Erro ao processar requisição',
    };

    const handleClose = vi.fn();

    render(<Toast toast={toast} onClose={handleClose} />);

    const closeButton = screen.getByRole('button', { name: /fechar notifica[cç][aã]o/i });
    fireEvent.click(closeButton);

    expect(handleClose).toHaveBeenCalledWith(2);
  });
});
