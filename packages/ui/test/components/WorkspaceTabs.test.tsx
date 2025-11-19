/**
 * @file WorkspaceTabs.test.tsx
 * @description Testes de integração do sistema de abas WorkspaceTabs
 */

import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { WorkspaceTabs } from '../../src/components/WorkspaceTabs.js';

function renderWorkspaceTabs() {
  return render(<WorkspaceTabs />);
}

describe('WorkspaceTabs - estrutura básica', () => {
  it('renderiza as 10 abas com rótulos esperados', () => {
    renderWorkspaceTabs();

    const labels = [
      'Overview',
      'HUs',
      'Docs',
      'Testes',
      'Analyze',
      'Personas & Plano',
      'Timeline',
      'Runs',
      'Métricas',
      'Outputs',
    ];

    labels.forEach((label) => {
      expect(
        screen.getByRole('button', { name: new RegExp(`\\b${label}\\b`, 'i') }),
      ).toBeInTheDocument();
    });
  });

  it('inicia com a aba Overview ativa (aria-current="page")', () => {
    renderWorkspaceTabs();

    const overviewButton = screen.getByRole('button', { name: /overview/i });

    expect(overviewButton).toBeInTheDocument();
    expect(overviewButton).toHaveAttribute('aria-current', 'page');
  });
});

describe('WorkspaceTabs - navegação entre abas', () => {
  it('permite navegar para aba Analyze e marcá-la como ativa', () => {
    renderWorkspaceTabs();

    const overviewButton = screen.getByRole('button', { name: /overview/i });
    const analyzeButton = screen.getByRole('button', { name: /analyze/i });

    // Estado inicial
    expect(overviewButton).toHaveAttribute('aria-current', 'page');
    expect(analyzeButton).not.toHaveAttribute('aria-current', 'page');

    // Navega para aba Analyze
    fireEvent.click(analyzeButton);

    expect(analyzeButton).toHaveAttribute('aria-current', 'page');
    expect(overviewButton).not.toHaveAttribute('aria-current', 'page');
  });

  it('mantém todas as abas presentes após navegação', () => {
    renderWorkspaceTabs();

    const analyzeButton = screen.getByRole('button', { name: /analyze/i });
    fireEvent.click(analyzeButton);

    const labels = [
      'Overview',
      'HUs',
      'Docs',
      'Testes',
      'Analyze',
      'Personas & Plano',
      'Timeline',
      'Runs',
      'Métricas',
      'Outputs',
    ];

    labels.forEach((label) => {
      expect(
        screen.getByRole('button', { name: new RegExp(`\\b${label}\\b`, 'i') }),
      ).toBeInTheDocument();
    });
  });
});
