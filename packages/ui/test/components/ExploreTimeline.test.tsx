/**
 * @file ExploreTimeline.test.tsx
 * @description Testes da Timeline de Exploração (aba Timeline)
 */

import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreTimeline } from '../../src/components/explore/ExploreTimeline.js';

describe('ExploreTimeline', () => {
  it('renderiza o cabeçalho da timeline e a contagem de eventos', () => {
    render(<ExploreTimeline />);

    expect(screen.getByText(/Timeline de Exploração/i)).toBeInTheDocument();
    expect(screen.getByText(/0\s+eventos/i)).toBeInTheDocument();
  });

  it('renderiza os filtros de categoria com 5 chips ativos', () => {
    render(<ExploreTimeline />);

    // Botões de filtro principais
    expect(screen.getByRole('button', { name: /habilitar todos os filtros/i })).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /desabilitar todos os filtros/i }),
    ).toBeInTheDocument();

    // Chips por tipo
    expect(screen.getByRole('button', { name: /filtrar por análise/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filtrar por discovery/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filtrar por projeto/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filtrar por execução/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /filtrar por sistema/i })).toBeInTheDocument();
  });

  it('exibe estado vazio quando não há eventos compatíveis com os filtros', () => {
    render(<ExploreTimeline />);

    expect(screen.getByText(/Nenhum evento encontrado com os filtros atuais/i)).toBeInTheDocument();
    expect(screen.getByText(/Ajuste os filtros acima para ver mais eventos/i)).toBeInTheDocument();
  });
});
