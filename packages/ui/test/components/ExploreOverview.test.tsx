/**
 * @file ExploreOverview.test.tsx
 * @description Testes do painel Overview do Explore Workspace
 */

import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreOverview } from '../../src/components/explore/ExploreOverview.js';

describe('ExploreOverview', () => {
  it('renderiza as três seções principais: Estado da Sessão, Projeto Atual e Últimas Análises', () => {
    render(<ExploreOverview />);

    expect(screen.getByText('Estado da Sessão')).toBeInTheDocument();
    expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
    expect(screen.getByText('Últimas Análises')).toBeInTheDocument();
  });

  it('renderiza as informações padrão do projeto Mini-IDE', () => {
    render(<ExploreOverview />);

    expect(screen.getByText('Mini-IDE')).toBeInTheDocument();
    expect(screen.getByText('PrinceOfEgypt1/Mini-IDE')).toBeInTheDocument();
    expect(screen.getByText('main')).toBeInTheDocument();
    expect(screen.getByText('~/workspace/Mini-IDE')).toBeInTheDocument();
  });

  it('exibe pelo menos uma análise mockada na lista de Últimas Análises', () => {
    render(<ExploreOverview />);

    // Strings usadas nos mocks originais (estado inicial)
    expect(screen.getByText(/Análise de estrutura de componentes React/i)).toBeInTheDocument();
  });
});
