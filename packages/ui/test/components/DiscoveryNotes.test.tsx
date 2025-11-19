/**
 * @file DiscoveryNotes.test.tsx
 * @description Testes do painel direito DiscoveryNotes (editor com persistência)
 */

import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { DiscoveryNotes } from '../../src/components/discovery/DiscoveryNotes.js';

describe('DiscoveryNotes', () => {
  it('renderiza o título e a descrição principal', () => {
    render(<DiscoveryNotes />);

    expect(screen.getByText('Discovery Notes')).toBeInTheDocument();
    expect(screen.getByText(/Coleta automática do que surge no chat/i)).toBeInTheDocument();
  });

  it('renderiza os quatro campos principais', () => {
    render(<DiscoveryNotes />);

    expect(screen.getByText('Intenção')).toBeInTheDocument();
    expect(screen.getByText('Requisitos')).toBeInTheDocument();
    expect(screen.getByText('Restrições')).toBeInTheDocument();
    expect(screen.getByText('Exemplos & Referências')).toBeInTheDocument();
  });

  it('permite editar o campo de intenção e persiste no localStorage', () => {
    const setItemSpy = vi.spyOn(window.localStorage.__proto__, 'setItem');

    render(<DiscoveryNotes />);

    const intentionField = screen.getByLabelText('Campo de intenção');

    fireEvent.change(intentionField, {
      target: { value: 'Explorar a UI da Mini-IDE' },
    });

    expect(intentionField).toHaveValue('Explorar a UI da Mini-IDE');
    // Não validamos a chave exata, apenas que algo foi salvo
    expect(setItemSpy).toHaveBeenCalled();

    setItemSpy.mockRestore();
  });
});
