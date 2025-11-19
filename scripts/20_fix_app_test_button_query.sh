#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 20_fix_app_test_button_query.sh
# Objetivo: Corrigir teste que falha por ambiguidade de texto
# 
# Problema: getByText('Provisionar') encontra múltiplos elementos
# Solução: Usar getByRole('button', { name: '...' }) para ser mais específico
#
# Arquivo modificado:
#   - packages/ui/test/App.spec.tsx (linhas 28-30)
################################################################################

echo "[info] Corrigindo teste ambíguo de botões do header..."

# Substituição cirúrgica no teste
cat <<'EOF' > packages/ui/test/App.spec.tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import App from '../src/App.js';

describe('App - Layout Wireframe MiniIDE-Explore.html', () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Header', () => {
    it('deve renderizar título "Mini IDE"', () => {
      render(<App />);
      expect(screen.getByText('Mini IDE')).toBeInTheDocument();
    });

    it('deve renderizar badges "Analysis Agent" e "Explorando"', () => {
      render(<App />);
      expect(screen.getByText('Analysis Agent')).toBeInTheDocument();
      expect(screen.getByText('Explorando')).toBeInTheDocument();
    });

    it('deve renderizar botões de ação', () => {
      render(<App />);
      // Usar getByRole para evitar ambiguidade com texto do conteúdo
      expect(screen.getByRole('button', { name: 'Provisionar' })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: 'Executar' })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: 'Quick Start' })).toBeInTheDocument();
    });
  });

  describe('Layout 3 Colunas', () => {
    it('deve renderizar sidebar esquerda com "Projeto Atual"', () => {
      render(<App />);
      expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
    });

    it('deve renderizar árvore do projeto na sidebar', () => {
      render(<App />);
      expect(screen.getByPlaceholderText(/filtrar árvore/i)).toBeInTheDocument();
      expect(screen.getByText('apps/')).toBeInTheDocument();
      expect(screen.getByText('packages/')).toBeInTheDocument();
    });

    it('deve renderizar painel central com abas internas', () => {
      render(<App />);
      expect(screen.getByText('Overview')).toBeInTheDocument();
      expect(screen.getByText('HUs')).toBeInTheDocument();
      expect(screen.getByText('Analyze')).toBeInTheDocument();
    });

    it('deve renderizar Discovery Notes no painel direito', () => {
      render(<App />);
      expect(screen.getByText('Discovery Notes')).toBeInTheDocument();
      expect(screen.getByText('Intenção')).toBeInTheDocument();
      expect(screen.getByText('Requisitos')).toBeInTheDocument();
      expect(screen.getByText('Restrições')).toBeInTheDocument();
    });
  });

  describe('Abas Internas do Workspace', () => {
    it('deve iniciar com aba Overview ativa', () => {
      render(<App />);
      expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();
    });

    it('deve trocar para aba Analyze ao clicar', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      expect(screen.getByText('Analyze Endpoint')).toBeInTheDocument();
    });

    it('deve mostrar todas as 10 abas', () => {
      render(<App />);
      
      expect(screen.getByRole('tab', { name: 'Overview' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'HUs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Docs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Testes' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Analyze' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: /Personas & Plano/i })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Timeline' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Runs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Métricas' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Outputs' })).toBeInTheDocument();
    });
  });

  describe('Navegação entre abas', () => {
    it('deve ocultar conteúdo da aba anterior ao trocar', () => {
      render(<App />);

      // Inicialmente em Overview
      expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();

      // Trocar para HUs
      const husTab = screen.getByRole('tab', { name: 'HUs' });
      fireEvent.click(husTab);

      // Conteúdo de Overview não deve estar visível
      expect(screen.queryByText(/Bem-vindo à Mini IDE/i)).not.toBeInTheDocument();
    });
  });

  describe('Footer com Chat', () => {
    it('deve renderizar textarea de chat', () => {
      render(<App />);
      expect(screen.getByPlaceholderText(/digite em linguagem natural/i)).toBeInTheDocument();
    });

    it('deve renderizar botões Anexar e Enviar no footer', () => {
      render(<App />);
      
      // Footer tem 2 botões específicos
      const footerButtons = screen.getAllByRole('button');
      const anexarButton = footerButtons.find(btn => btn.textContent === 'Anexar');
      const enviarButton = footerButtons.find(btn => btn.textContent === 'Enviar');
      
      expect(anexarButton).toBeInTheDocument();
      expect(enviarButton).toBeInTheDocument();
    });
  });

  describe('Integração com componentes existentes', () => {
    it('deve integrar ServerStatus na aba Analyze', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      // ServerStatus renderiza "Verificando..." inicialmente
      expect(screen.getByText(/verificando/i) || screen.getByText(/servidor/i)).toBeInTheDocument();
    });

    it('deve integrar AnalyzePlayground na aba Analyze', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      expect(screen.getByPlaceholderText(/digite o texto/i)).toBeInTheDocument();
    });
  });
});
EOF

echo "[ok] Teste corrigido: usando getByRole ao invés de getByText"
echo ""
echo "Mudanças:"
echo "  ✓ Linha 28: getByText('Provisionar') → getByRole('button', { name: 'Provisionar' })"
echo "  ✓ Linha 29: getByText('Executar') → getByRole('button', { name: 'Executar' })"
echo "  ✓ Linha 30: getByText('Quick Start') → getByRole('button', { name: 'Quick Start' })"
echo "  ✓ Footer: melhorada query para evitar ambiguidades"
echo ""
echo "Executando testes..."
pnpm --filter @mini-ide/ui test

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ TODOS OS TESTES PASSARAM!"
  echo ""
  echo "Validação final completa:"
  echo "  → pnpm typecheck"
  pnpm typecheck
  echo ""
  echo "  → pnpm build"
  pnpm build
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║        HU-UI-Fix-Align-Wireframe-Explore COMPLETA ✓           ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
else
  echo ""
  echo "❌ Testes ainda falhando. Verifique o log acima."
  exit 1
fi
EOF

chmod +x scripts/20_fix_app_test_button_query.sh
./scripts/20_fix_app_test_button_query.sh
