/**
 * @file App.spec.tsx
 * @description Testes de alto nível do layout da Mini-IDE (wireframe Explore)
 */

import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import App from '../src/App';

describe('App - Layout Wireframe MiniIDE-Explore.html', () => {
  describe('Header', () => {
    it('deve renderizar título "Mini IDE"', () => {
      render(<App />);
      expect(screen.getByRole('heading', { name: /mini ide/i })).toBeInTheDocument();
    });

    it('deve renderizar badge "Analysis Agent"', () => {
      render(<App />);
      expect(screen.getByText(/analysis agent/i)).toBeInTheDocument();
    });

    it('deve renderizar badge de status "Explorando"', () => {
      render(<App />);
      expect(screen.getByText(/explorando/i)).toBeInTheDocument();
    });
  });

  describe('Layout 3 Colunas', () => {
    it('deve renderizar sidebar esquerda com título "Projeto Atual"', () => {
      render(<App />);

      // Há mais de uma ocorrência de "Projeto Atual" (Sidebar + Overview).
      // O critério de aceite é: existir pelo menos um título "Projeto Atual"
      // na UI, então aceitamos múltiplos matches.
      const matches = screen.getAllByText(/projeto atual/i);
      expect(matches.length).toBeGreaterThanOrEqual(1);
    });

    it('deve renderizar painel central com abas do WorkspaceTabs', () => {
      render(<App />);
      expect(screen.getByRole('button', { name: /overview/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /analyze/i })).toBeInTheDocument();
    });

    it('deve renderizar painel direito com Discovery Notes', () => {
      render(<App />);
      expect(screen.getByText(/discovery notes/i)).toBeInTheDocument();
    });

    it('deve ter pelo menos 3 painéis principais no DOM', () => {
      const { container } = render(<App />);
      const mainElement = container.querySelector('main');
      expect(mainElement).toBeInTheDocument();
      expect(mainElement?.children.length ?? 0).toBeGreaterThanOrEqual(3);
    });
  });

  describe('Abas Internas do Workspace', () => {
    it('deve iniciar com aba Overview ativa (aria-current="page")', () => {
      render(<App />);

      const overviewButton = screen.getByRole('button', { name: /overview/i });

      expect(overviewButton).toBeInTheDocument();
      expect(overviewButton).toHaveAttribute('aria-current', 'page');
    });

    it('deve trocar para aba Analyze ao clicar, marcando-a como ativa', () => {
      render(<App />);

      const overviewButton = screen.getByRole('button', { name: /overview/i });
      const analyzeButton = screen.getByRole('button', { name: /analyze/i });

      // Estado inicial
      expect(overviewButton).toHaveAttribute('aria-current', 'page');
      expect(analyzeButton).not.toHaveAttribute('aria-current', 'page');

      // Navegação
      fireEvent.click(analyzeButton);

      expect(analyzeButton).toHaveAttribute('aria-current', 'page');
      expect(overviewButton).not.toHaveAttribute('aria-current', 'page');
    });

    it('deve mostrar todas as 10 abas definidas no wireframe', () => {
      render(<App />);

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

  describe('Navegação entre abas', () => {
    it('não deve quebrar ao navegar entre abas (ex.: Overview → Analyze)', () => {
      const { container } = render(<App />);

      const analyzeButton = screen.getByRole('button', { name: /analyze/i });
      fireEvent.click(analyzeButton);

      // Garantir que o conjunto de abas continua existindo
      const tabButtons = container.querySelectorAll('button');
      expect(tabButtons.length).toBeGreaterThanOrEqual(10);
    });
  });

  describe('Footer com Chat', () => {
    it('deve renderizar textarea para mensagens', () => {
      render(<App />);
      const textarea = screen.getByPlaceholderText(/digite/i);
      expect(textarea).toBeInTheDocument();
    });

    it('deve renderizar botão Enviar', () => {
      render(<App />);
      expect(screen.getByRole('button', { name: /enviar/i })).toBeInTheDocument();
    });
  });

  describe('Integração com componentes existentes (verificações leves)', () => {
    it('deve permitir navegar até a aba Analyze sem erros de renderização', () => {
      const { container } = render(<App />);

      const analyzeButton = screen.getByRole('button', { name: /analyze/i });
      fireEvent.click(analyzeButton);

      // Aba Analyze marcada como atual
      expect(analyzeButton).toHaveAttribute('aria-current', 'page');

      // Layout central ainda contém o grupo de abas
      const tabsContainer = container.querySelector('[class*="tabs"]');
      expect(tabsContainer).toBeInTheDocument();
    });
  });
});
