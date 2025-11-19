#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11e_fix_app_tests_selectors.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Corrigir testes do App.spec.tsx usando seletores específicos
#
# Problema identificado:
#   - Texto "Analyze" aparece em 2 lugares:
#     1. Tab de navegação: <div class="tab">Analyze</div>
#     2. Texto Overview: <strong>Analyze</strong>
#   - getByText('Analyze') encontra múltiplos elementos
#
# Causa raiz:
#   - App.tsx menciona "Analyze" no texto da Overview
#   - Testes usam getByText genérico
#
# Solução:
#   - Adicionar data-testid nas tabs do App.tsx
#   - Usar getByTestId nos testes em vez de getByText
#   - Solução mais robusta e específica
#
# Arquivos modificados:
#   - packages/ui/src/App.tsx (adicionar data-testid)
#   - packages/ui/test/App.spec.tsx (usar getByTestId)
#
# Como reverter:
#   git restore packages/ui/src/App.tsx packages/ui/test/App.spec.tsx
#
################################################################################

echo "[info] Aplicando correção científica nos testes do App..."

# 1. Atualizar App.tsx com data-testid nas tabs
echo "[info] Adicionando data-testid nas tabs do App.tsx..."

cat <<'EOF' > packages/ui/src/App.tsx
/**
 * Componente principal da Mini-IDE UI
 * 
 * @packageDocumentation
 * @module App
 * 
 * Layout baseado no wireframe MiniIDE-Explore.html:
 * - Header com título, ServerStatus e botões
 * - Main com 3 colunas: sidebar, workspace central, right panel
 * - Workspace com tabs (Overview, Analyze)
 * - AnalyzePlayground integrado na tab Analyze
 */

import { useState } from 'react';
import { ServerStatus } from './components/ServerStatus.js';
import { AnalyzePlayground } from './components/AnalyzePlayground.js';
import './styles/global.css';

type ActiveTab = 'overview' | 'analyze';

/**
 * Componente raiz da aplicação Mini-IDE
 * 
 * @returns Elemento React com layout completo
 */
export function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('overview');

  return (
    <div className="app">
      {/* Header */}
      <header>
        <div className="title">Mini IDE</div>
        <div className="pill">Analysis Agent</div>
        <ServerStatus pollInterval={10000} />
        <div className="spacer"></div>
      </header>

      {/* Main layout */}
      <div className="main">
        {/* Sidebar esquerda */}
        <aside className="panel sidebar">
          <div className="row" style={{ justifyContent: 'space-between' }}>
            <strong>Projeto Atual</strong>
            <span className="pill ok">pronto</span>
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <p className="muted" style={{ textAlign: 'center', fontSize: '12px' }}>
              Sidebar placeholder
            </p>
          </div>
        </aside>

        {/* Workspace central */}
        <section className="panel workspace">
          <div className="tabs">
            <div
              className={`tab ${activeTab === 'overview' ? 'active' : ''}`}
              onClick={() => setActiveTab('overview')}
              data-testid="tab-overview"
            >
              Overview
            </div>
            <div
              className={`tab ${activeTab === 'analyze' ? 'active' : ''}`}
              onClick={() => setActiveTab('analyze')}
              data-testid="tab-analyze"
            >
              Analyze
            </div>
          </div>

          {/* Tab Overview */}
          {activeTab === 'overview' && (
            <div className="cards">
              <div className="card">
                <h3>Bem-vindo à Mini IDE</h3>
                <p>
                  Este é o painel de interface da Mini-IDE. Use a tab{' '}
                  <strong>Analyze</strong> para testar o endpoint POST /analyze
                  interativamente.
                </p>
                <ul style={{ marginTop: '12px' }}>
                  <li>Servidor configurável via VITE_MINI_IDE_SERVER_URL</li>
                  <li>Indicador de status do servidor em tempo real</li>
                  <li>Playground para requisições /analyze</li>
                </ul>
              </div>
            </div>
          )}

          {/* Tab Analyze (Playground) */}
          {activeTab === 'analyze' && (
            <div className="cards">
              <AnalyzePlayground defaultMaxLen={100} />
            </div>
          )}
        </section>

        {/* Right panel */}
        <aside className="panel sidebar">
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <p className="muted" style={{ textAlign: 'center', fontSize: '12px' }}>
              Right panel placeholder
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
EOF

echo "[ok] App.tsx atualizado (data-testid adicionados)"

# 2. Reescrever App.spec.tsx com seletores específicos
echo "[info] Reescrevendo App.spec.tsx com seletores robustos..."

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

    // Usar data-testid para buscar tabs específicas
    expect(screen.getByTestId('tab-overview')).toBeInTheDocument();
    expect(screen.getByTestId('tab-analyze')).toBeInTheDocument();
  });

  it('deve mostrar tab Overview por padrão', () => {
    render(<App />);

    const overviewTab = screen.getByTestId('tab-overview');
    expect(overviewTab.className).toContain('active');
    
    expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();
  });

  it('deve trocar para tab Analyze ao clicar', async () => {
    const user = userEvent.setup();
    render(<App />);

    const analyzeTab = screen.getByTestId('tab-analyze');
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

    // Clicar em Analyze usando data-testid
    const analyzeTab = screen.getByTestId('tab-analyze');
    await user.click(analyzeTab);

    // Overview não deve mais estar visível
    expect(screen.queryByText(/Bem-vindo à Mini IDE/i)).not.toBeInTheDocument();
  });

  it('deve voltar para Overview ao clicar novamente', async () => {
    const user = userEvent.setup();
    render(<App />);

    const analyzeTab = screen.getByTestId('tab-analyze');
    const overviewTab = screen.getByTestId('tab-overview');

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

echo "[ok] App.spec.tsx reescrito com seletores específicos"

echo ""
echo "============================================================"
echo "✅ CORREÇÃO CIENTÍFICA APLICADA"
echo "============================================================"
echo ""
echo "🔬 ANÁLISE DO PROBLEMA"
echo "============================================================"
echo ""
echo "Observação:"
echo "  • 4 testes falhando com 'Found multiple elements with text: Analyze'"
echo ""
echo "Causa Raiz Identificada:"
echo "  • Texto 'Analyze' aparece em 2 lugares:"
echo "    1. Tab de navegação: <div class='tab'>Analyze</div>"
echo "    2. Texto da Overview: <strong>Analyze</strong>"
echo "  • getByText('Analyze') é ambíguo"
echo ""
echo "Hipótese da Solução:"
echo "  • Usar seletores específicos (data-testid)"
echo "  • Eliminar ambiguidade nos queries"
echo ""
echo "============================================================"
echo "🔧 SOLUÇÃO IMPLEMENTADA"
echo "============================================================"
echo ""
echo "App.tsx:"
echo "  ✅ Adicionado data-testid='tab-overview' na tab Overview"
echo "  ✅ Adicionado data-testid='tab-analyze' na tab Analyze"
echo ""
echo "App.spec.tsx:"
echo "  ✅ Substituído getByText('Analyze') por getByTestId('tab-analyze')"
echo "  ✅ Substituído getByText('Overview') por getByTestId('tab-overview')"
echo "  ✅ Todos os 9 testes agora usam seletores específicos"
echo ""
echo "============================================================"
echo "📊 RESULTADO ESPERADO"
echo "============================================================"
echo ""
echo "Antes:"
echo "  ❌ Test Files: 1 failed | 4 passed (5)"
echo "  ❌ Tests: 4 failed | 27 passed (31)"
echo ""
echo "Depois:"
echo "  ✅ Test Files: 5 passed (5)"
echo "  ✅ Tests: 31 passed (31)"
echo ""
echo "============================================================"
echo "🔄 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Executar testes (deve passar 31/31):"
echo "   pnpm --filter @mini-ide/ui test"
echo ""
echo "2. Verificar coverage (deve estar ≥80%):"
echo "   pnpm --filter @mini-ide/ui test:coverage"
echo ""
echo "3. Continuar pipeline:"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "============================================================"
echo "🎯 VALIDAÇÃO CIENTÍFICA"
echo "============================================================"
echo ""
echo "Método aplicado:"
echo "  1. ✅ Observação: Analisar logs de erro"
echo "  2. ✅ Hipótese: Ambiguidade em seletores"
echo "  3. ✅ Experimento: Usar data-testid específicos"
echo "  4. ⏳ Validação: Executar testes novamente"
echo "  5. ⏳ Conclusão: Confirmar 31/31 passando"
echo ""
echo "============================================================"
