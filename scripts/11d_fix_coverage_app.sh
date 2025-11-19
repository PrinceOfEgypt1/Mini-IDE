#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11d_fix_coverage_app.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Adicionar teste básico para App.tsx e atingir threshold de coverage 80%
#
# Problema:
#   - Coverage total: 74.84% (threshold: 80%)
#   - App.tsx: 0% coverage (não tem testes)
#   - Componentes individuais estão OK (97-100%)
#
# Solução:
#   - Criar test/App.spec.tsx com testes básicos de renderização
#   - Coverage deve subir de 74.84% para ~85%+
#
# Arquivos criados:
#   - packages/ui/test/App.spec.tsx
#
# Como reverter:
#   rm packages/ui/test/App.spec.tsx
#
################################################################################

echo "[info] Criando teste básico para App.tsx..."

cat <<'EOF' > packages/ui/test/App.spec.tsx
/**
 * Testes para componente App
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { App } from '../src/App.js';

describe('App', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    
    // Mock de fetch para healthz (ServerStatus)
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
    });
  });

  it('deve renderizar estrutura principal da aplicação', () => {
    render(<App />);

    // Header
    expect(screen.getByText('Mini IDE')).toBeInTheDocument();
    expect(screen.getByText('Analysis Agent')).toBeInTheDocument();
    
    // ServerStatus deve estar presente
    expect(screen.getByTestId('server-status')).toBeInTheDocument();
  });

  it('deve renderizar tabs de navegação', () => {
    render(<App />);

    expect(screen.getByText('Overview')).toBeInTheDocument();
    expect(screen.getByText('Analyze')).toBeInTheDocument();
  });

  it('deve mostrar tab Overview por padrão', () => {
    render(<App />);

    const overviewTab = screen.getByText('Overview');
    expect(overviewTab.className).toContain('active');
    
    expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();
  });

  it('deve trocar para tab Analyze ao clicar', async () => {
    const user = userEvent.setup();
    render(<App />);

    const analyzeTab = screen.getByText('Analyze');
    await user.click(analyzeTab);

    // Tab Analyze deve estar ativa
    expect(analyzeTab.className).toContain('active');
    
    // Playground deve estar visível
    expect(screen.getByTestId('analyze-playground')).toBeInTheDocument();
  });

  it('deve mostrar sidebar esquerda com "Projeto Atual"', () => {
    render(<App />);

    expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
    expect(screen.getByText('pronto')).toBeInTheDocument();
  });

  it('deve renderizar layout 3 colunas', () => {
    const { container } = render(<App />);

    const main = container.querySelector('.main');
    expect(main).toBeInTheDocument();
    
    // Deve ter 3 children (sidebar, workspace, right panel)
    expect(main?.children.length).toBe(3);
  });

  it('deve ocultar Overview ao mudar para Analyze', async () => {
    const user = userEvent.setup();
    render(<App />);

    // Verificar que Overview está visível
    expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();

    // Clicar em Analyze
    const analyzeTab = screen.getByText('Analyze');
    await user.click(analyzeTab);

    // Overview não deve mais estar visível
    expect(screen.queryByText(/Bem-vindo à Mini IDE/i)).not.toBeInTheDocument();
  });

  it('deve voltar para Overview ao clicar novamente', async () => {
    const user = userEvent.setup();
    render(<App />);

    const analyzeTab = screen.getByText('Analyze');
    const overviewTab = screen.getByText('Overview');

    // Ir para Analyze
    await user.click(analyzeTab);
    expect(screen.getByTestId('analyze-playground')).toBeInTheDocument();

    // Voltar para Overview
    await user.click(overviewTab);
    expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();
    expect(screen.queryByTestId('analyze-playground')).not.toBeInTheDocument();
  });

  it('deve chamar /healthz automaticamente (ServerStatus)', async () => {
    render(<App />);

    // Aguardar que ServerStatus faça a primeira chamada
    await waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalled();
    });

    // Verificar que chamou o endpoint correto
    const calls = (globalThis.fetch as ReturnType<typeof vi.fn>).mock.calls;
    const healthzCall = calls.find(call => 
      call[0]?.toString().includes('/healthz')
    );
    
    expect(healthzCall).toBeDefined();
  });
});
EOF

echo "[ok] test/App.spec.tsx criado com 9 testes"

echo ""
echo "============================================================"
echo "✅ TESTE CRIADO"
echo "============================================================"
echo ""
echo "Arquivo criado:"
echo "  📄 packages/ui/test/App.spec.tsx"
echo ""
echo "Testes adicionados: 9"
echo "  ✅ deve renderizar estrutura principal da aplicação"
echo "  ✅ deve renderizar tabs de navegação"
echo "  ✅ deve mostrar tab Overview por padrão"
echo "  ✅ deve trocar para tab Analyze ao clicar"
echo "  ✅ deve mostrar sidebar esquerda com 'Projeto Atual'"
echo "  ✅ deve renderizar layout 3 colunas"
echo "  ✅ deve ocultar Overview ao mudar para Analyze"
echo "  ✅ deve voltar para Overview ao clicar novamente"
echo "  ✅ deve chamar /healthz automaticamente (ServerStatus)"
echo ""
echo "============================================================"
echo "📊 IMPACTO NO COVERAGE"
echo "============================================================"
echo ""
echo "Antes:"
echo "  ❌ App.tsx: 0% coverage"
echo "  ❌ Total: 74.84% (threshold: 80%)"
echo ""
echo "Depois (esperado):"
echo "  ✅ App.tsx: ~85%+ coverage"
echo "  ✅ Total: ~85%+ (acima do threshold)"
echo ""
echo "============================================================"
echo "🔄 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Rodar testes novamente (deve passar 31/31):"
echo "   pnpm --filter @mini-ide/ui test"
echo ""
echo "2. Verificar coverage (deve estar ≥80%):"
echo "   pnpm --filter @mini-ide/ui test:coverage"
echo ""
echo "3. Se coverage passar, continuar pipeline:"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "4. Pipeline completa do monorepo:"
echo "   REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
echo "============================================================"
