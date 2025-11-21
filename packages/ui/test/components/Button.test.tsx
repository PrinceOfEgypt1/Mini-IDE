// packages/ui/test/components/Button.test.tsx
import { describe, expect, it, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../../src/components/common/Button.js';

describe('Button', () => {
  it('deve renderizar com o texto fornecido', () => {
    render(<Button>Enviar</Button>);

    const button = screen.getByRole('button', { name: /enviar/i });
    expect(button).toBeInTheDocument();
  });

  it('deve chamar onClick quando clicado', () => {
    const handleClick = vi.fn();

    render(<Button onClick={handleClick}>Executar</Button>);

    const button = screen.getByRole('button', { name: /executar/i });
    fireEvent.click(button);

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('não deve chamar onClick quando desabilitado', () => {
    const handleClick = vi.fn();

    render(
      <Button disabled onClick={handleClick}>
        Provisionar
      </Button>,
    );

    const button = screen.getByRole('button', { name: /provisionar/i });
    fireEvent.click(button);

    expect(handleClick).not.toHaveBeenCalled();
  });
});
