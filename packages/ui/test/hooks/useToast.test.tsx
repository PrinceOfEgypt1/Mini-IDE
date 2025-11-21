// packages/ui/test/hooks/useToast.test.tsx
import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { ToastProvider } from '../../src/contexts/ToastProvider.js';
import { useToast } from '../../src/hooks/useToast.js';

function TestComponent() {
  const { showSuccess } = useToast();

  return (
    <button type="button" onClick={() => showSuccess('Toast de sucesso acionado')}>
      Disparar toast
    </button>
  );
}

describe('useToast', () => {
  it('deve exibir toast de sucesso quando showSuccess é chamado', async () => {
    render(
      <ToastProvider>
        <TestComponent />
      </ToastProvider>,
    );

    const button = screen.getByRole('button', { name: /disparar toast/i });
    fireEvent.click(button);

    const toast = await screen.findByText(/toast de sucesso acionado/i);
    expect(toast).toBeInTheDocument();
  });
});
