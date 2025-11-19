#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 12_ui_tabs_explore_design_execute.sh
# Objetivo: Implementar HU-UI-Tabs-004 - Sistema de Abas Dinâmicas
# 
# Arquivos criados/modificados:
#   - packages/ui/src/components/TabsNavigation.tsx (novo)
#   - packages/ui/src/components/TabsNavigation.module.css (novo)
#   - packages/ui/src/components/tabs/ExploreTab.tsx (novo)
#   - packages/ui/src/components/tabs/DesignTab.tsx (novo)
#   - packages/ui/src/components/tabs/ExecuteTab.tsx (novo)
#   - packages/ui/src/components/tabs/AnalyzeTab.tsx (novo)
#   - packages/ui/src/App.tsx (atualizado)
#   - packages/ui/src/App.module.css (atualizado)
#   - packages/ui/src/components/TabsNavigation.spec.tsx (novo)
#
# Modo de uso:
#   1. Salve este script como scripts/12_ui_tabs_explore_design_execute.sh
#   2. chmod +x scripts/12_ui_tabs_explore_design_execute.sh
#   3. ./scripts/12_ui_tabs_explore_design_execute.sh
#   4. Valide: pnpm lint && pnpm test && pnpm typecheck && pnpm build
#
# Premissas:
#   - Projeto no estado v1.0.17
#   - ServerStatus e AnalyzePlayground já existem
#   - Estrutura packages/ui/src/{components,config,styles} já existe
#
# Riscos:
#   - Se App.tsx tiver estrutura muito diferente, pode precisar ajuste manual
#
# Rollback:
#   - git checkout packages/ui/src/App.tsx packages/ui/src/App.module.css
#   - git clean -fd packages/ui/src/components/tabs/
#   - rm packages/ui/src/components/TabsNavigation.{tsx,module.css,spec.tsx}
################################################################################

echo "[info] Iniciando implementação HU-UI-Tabs-004..."

# Criar diretório para componentes de abas
mkdir -p packages/ui/src/components/tabs

# 1. Criar componente TabsNavigation
cat <<'EOF' > packages/ui/src/components/TabsNavigation.tsx
import React from 'react';
import styles from './TabsNavigation.module.css';

export type TabId = 'explore' | 'design' | 'execute' | 'analyze';

export interface Tab {
  id: TabId;
  label: string;
  ariaLabel: string;
}

export interface TabsNavigationProps {
  activeTab: TabId;
  onTabChange: (tabId: TabId) => void;
  tabs?: Tab[];
}

const DEFAULT_TABS: Tab[] = [
  { id: 'explore', label: 'Explore', ariaLabel: 'Tab Explorar projeto' },
  { id: 'design', label: 'Design', ariaLabel: 'Tab Design de arquitetura' },
  { id: 'execute', label: 'Execute', ariaLabel: 'Tab Executar análises' },
  { id: 'analyze', label: 'Analyze', ariaLabel: 'Tab Analisar resultados' },
];

/**
 * TabsNavigation - Sistema de navegação por abas
 * 
 * Componente que implementa a navegação entre diferentes modos do workspace.
 * Suporta navegação por teclado (Ctrl+1-4) e mantém estado de aba ativa.
 * 
 * @example
 * ```tsx
 * const [activeTab, setActiveTab] = useState<TabId>('explore');
 * <TabsNavigation activeTab={activeTab} onTabChange={setActiveTab} />
 * ```
 */
export const TabsNavigation: React.FC<TabsNavigationProps> = ({
  activeTab,
  onTabChange,
  tabs = DEFAULT_TABS,
}) => {
  React.useEffect(() => {
    const handleKeyboard = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key >= '1' && e.key <= '4') {
        e.preventDefault();
        const index = parseInt(e.key, 10) - 1;
        if (tabs[index]) {
          onTabChange(tabs[index].id);
        }
      }
    };

    window.addEventListener('keydown', handleKeyboard);
    return () => window.removeEventListener('keydown', handleKeyboard);
  }, [onTabChange, tabs]);

  return (
    <div className={styles.tabsContainer} role="tablist" aria-label="Workspace navigation">
      {tabs.map((tab, index) => (
        <button
          key={tab.id}
          role="tab"
          aria-selected={activeTab === tab.id}
          aria-label={tab.ariaLabel}
          aria-controls={`tabpanel-${tab.id}`}
          tabIndex={activeTab === tab.id ? 0 : -1}
          className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
          onClick={() => onTabChange(tab.id)}
          title={`${tab.label} (Ctrl+${index + 1})`}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
};
EOF

# 2. Criar estilos para TabsNavigation (baseado no wireframe)
cat <<'EOF' > packages/ui/src/components/TabsNavigation.module.css
.tabsContainer {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  padding: 0;
  margin: 0 0 16px 0;
}

.tab {
  padding: 6px 12px;
  border: 1px solid var(--border, #24304a);
  border-radius: 999px;
  background: var(--panel-2, #101727);
  color: var(--muted, #9fb0d3);
  cursor: pointer;
  font-size: 14px;
  font-family: inherit;
  transition: all 0.15s ease;
  outline: none;
}

.tab:hover {
  background: var(--panel, #141b2b);
  color: var(--text, #e6ecff);
}

.tab:focus-visible {
  box-shadow: 0 0 0 2px var(--brand, #4ba3ff);
}

.tab.active {
  background: var(--brand, #4ba3ff);
  color: white;
  border-color: transparent;
  font-weight: 500;
}

@media (prefers-color-scheme: light) {
  .tab {
    background: var(--panel-2, #f3f6fb);
    color: var(--muted, #4a5977);
    border-color: var(--border, #d7e0f5);
  }

  .tab:hover {
    background: var(--panel, #ffffff);
    color: var(--text, #0b162b);
  }

  .tab.active {
    background: var(--brand, #0b63ff);
    color: white;
  }
}
EOF

# 3. Criar componente ExploreTab (placeholder)
cat <<'EOF' > packages/ui/src/components/tabs/ExploreTab.tsx
import React from 'react';

/**
 * ExploreTab - Aba de exploração do projeto
 * 
 * Futura implementação: visualização de estrutura de arquivos,
 * discovery notes, timeline de exploração.
 */
export const ExploreTab: React.FC = () => {
  return (
    <div role="tabpanel" id="tabpanel-explore" aria-labelledby="tab-explore">
      <div style={{ padding: '24px' }}>
        <h2 style={{ margin: '0 0 12px 0', fontSize: '20px' }}>Explore</h2>
        <p style={{ color: 'var(--muted, #9fb0d3)', lineHeight: '1.6' }}>
          Modo de exploração do projeto. Aqui você poderá visualizar a estrutura
          de arquivos, discovery notes e timeline de exploração.
        </p>
        <p style={{ color: 'var(--muted, #9fb0d3)', marginTop: '12px', fontSize: '13px' }}>
          🚧 Em desenvolvimento – próximas HUs do Lote 2
        </p>
      </div>
    </div>
  );
};
EOF

# 4. Criar componente DesignTab (placeholder)
cat <<'EOF' > packages/ui/src/components/tabs/DesignTab.tsx
import React from 'react';

/**
 * DesignTab - Aba de design de arquitetura
 * 
 * Futura implementação: diagramas de arquitetura, decisões técnicas (ADRs),
 * visualização de dependências.
 */
export const DesignTab: React.FC = () => {
  return (
    <div role="tabpanel" id="tabpanel-design" aria-labelledby="tab-design">
      <div style={{ padding: '24px' }}>
        <h2 style={{ margin: '0 0 12px 0', fontSize: '20px' }}>Design</h2>
        <p style={{ color: 'var(--muted, #9fb0d3)', lineHeight: '1.6' }}>
          Visualização de design e arquitetura do projeto. Incluirá diagramas,
          ADRs (Architectural Decision Records) e análise de dependências.
        </p>
        <p style={{ color: 'var(--muted, #9fb0d3)', marginTop: '12px', fontSize: '13px' }}>
          🚧 Em desenvolvimento – próximas HUs do Lote 2
        </p>
      </div>
    </div>
  );
};
EOF

# 5. Criar componente ExecuteTab (placeholder)
cat <<'EOF' > packages/ui/src/components/tabs/ExecuteTab.tsx
import React from 'react';

/**
 * ExecuteTab - Aba de execução de análises
 * 
 * Futura implementação: histórico de execuções, métricas de performance,
 * logs estruturados.
 */
export const ExecuteTab: React.FC = () => {
  return (
    <div role="tabpanel" id="tabpanel-execute" aria-labelledby="tab-execute">
      <div style={{ padding: '24px' }}>
        <h2 style={{ margin: '0 0 12px 0', fontSize: '20px' }}>Execute</h2>
        <p style={{ color: 'var(--muted, #9fb0d3)', lineHeight: '1.6' }}>
          Execução e monitoramento de análises. Visualize histórico de execuções,
          métricas de performance e logs detalhados.
        </p>
        <p style={{ color: 'var(--muted, #9fb0d3)', marginTop: '12px', fontSize: '13px' }}>
          🚧 Em desenvolvimento – próximas HUs do Lote 2
        </p>
      </div>
    </div>
  );
};
EOF

# 6. Criar componente AnalyzeTab (usa componentes existentes)
cat <<'EOF' > packages/ui/src/components/tabs/AnalyzeTab.tsx
import React from 'react';
import { ServerStatus } from '../ServerStatus.js';
import { AnalyzePlayground } from '../AnalyzePlayground.js';

/**
 * AnalyzeTab - Aba de análise com playground do /analyze
 * 
 * Integra os componentes existentes ServerStatus e AnalyzePlayground
 * para manter a funcionalidade já implementada nas HUs anteriores.
 */
export const AnalyzeTab: React.FC = () => {
  return (
    <div role="tabpanel" id="tabpanel-analyze" aria-labelledby="tab-analyze">
      <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <h2 style={{ margin: 0, fontSize: '18px' }}>Analyze Endpoint</h2>
          <ServerStatus />
        </div>
        <AnalyzePlayground />
      </div>
    </div>
  );
};
EOF

# 7. Atualizar App.tsx para usar o sistema de abas
cat <<'EOF' > packages/ui/src/App.tsx
import React, { useState } from 'react';
import { TabsNavigation, type TabId } from './components/TabsNavigation.js';
import { ExploreTab } from './components/tabs/ExploreTab.js';
import { DesignTab } from './components/tabs/DesignTab.js';
import { ExecuteTab } from './components/tabs/ExecuteTab.js';
import { AnalyzeTab } from './components/tabs/AnalyzeTab.js';
import styles from './App.module.css';

/**
 * App - Componente principal da Mini-IDE UI
 * 
 * Implementa o layout base com sistema de abas para navegação
 * entre diferentes modos do workspace (Explore, Design, Execute, Analyze).
 */
function App() {
  const [activeTab, setActiveTab] = useState<TabId>('analyze');

  const renderTabContent = () => {
    switch (activeTab) {
      case 'explore':
        return <ExploreTab />;
      case 'design':
        return <DesignTab />;
      case 'execute':
        return <ExecuteTab />;
      case 'analyze':
        return <AnalyzeTab />;
      default:
        return <AnalyzeTab />;
    }
  };

  return (
    <div className={styles.app}>
      <header className={styles.header}>
        <div className={styles.headerContent}>
          <h1 className={styles.title}>Mini-IDE</h1>
          <span className={styles.version}>v1.0.17</span>
        </div>
      </header>

      <main className={styles.main}>
        <div className={styles.workspace}>
          <TabsNavigation activeTab={activeTab} onTabChange={setActiveTab} />
          <div className={styles.tabContent}>
            {renderTabContent()}
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;
EOF

# 8. Atualizar estilos do App.module.css
cat <<'EOF' > packages/ui/src/App.module.css
:root {
  --bg: #0f1420;
  --panel: #141b2b;
  --panel-2: #101727;
  --text: #e6ecff;
  --muted: #9fb0d3;
  --brand: #4ba3ff;
  --border: #24304a;
  --shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

@media (prefers-color-scheme: light) {
  :root {
    --bg: #f7f9fc;
    --panel: #ffffff;
    --panel-2: #f3f6fb;
    --text: #0b162b;
    --muted: #4a5977;
    --brand: #0b63ff;
    --border: #d7e0f5;
    --shadow: 0 4px 12px rgba(15, 20, 32, 0.08);
  }
}

* {
  box-sizing: border-box;
}

.app {
  min-height: 100vh;
  background: var(--bg);
  color: var(--text);
  display: flex;
  flex-direction: column;
}

.header {
  background: var(--panel);
  border-bottom: 1px solid var(--border);
  padding: 0 24px;
  height: 56px;
  display: flex;
  align-items: center;
  box-shadow: var(--shadow);
  position: sticky;
  top: 0;
  z-index: 100;
}

.headerContent {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
}

.title {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
  letter-spacing: 0.3px;
}

.version {
  font-size: 12px;
  color: var(--muted);
  padding: 3px 8px;
  background: var(--panel-2);
  border: 1px solid var(--border);
  border-radius: 12px;
}

.main {
  flex: 1;
  display: flex;
  padding: 24px;
  max-width: 1600px;
  width: 100%;
  margin: 0 auto;
}

.workspace {
  flex: 1;
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 20px;
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
  min-height: 600px;
}

.tabContent {
  flex: 1;
  background: var(--panel-2);
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: auto;
}

@media (max-width: 768px) {
  .main {
    padding: 12px;
  }

  .workspace {
    padding: 16px;
  }

  .header {
    padding: 0 16px;
  }
}
EOF

# 9. Criar testes para TabsNavigation
cat <<'EOF' > packages/ui/src/components/TabsNavigation.spec.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { TabsNavigation, type TabId } from './TabsNavigation.js';

describe('TabsNavigation', () => {
  it('deve renderizar todas as abas padrão', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    expect(screen.getByText('Explore')).toBeInTheDocument();
    expect(screen.getByText('Design')).toBeInTheDocument();
    expect(screen.getByText('Execute')).toBeInTheDocument();
    expect(screen.getByText('Analyze')).toBeInTheDocument();
  });

  it('deve marcar a aba ativa corretamente', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="analyze" onTabChange={mockOnChange} />);

    const analyzeTab = screen.getByText('Analyze');
    expect(analyzeTab).toHaveAttribute('aria-selected', 'true');

    const exploreTab = screen.getByText('Explore');
    expect(exploreTab).toHaveAttribute('aria-selected', 'false');
  });

  it('deve chamar onTabChange ao clicar em uma aba', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    const designTab = screen.getByText('Design');
    fireEvent.click(designTab);

    expect(mockOnChange).toHaveBeenCalledWith('design');
  });

  it('deve ter role="tablist" no container', () => {
    const mockOnChange = vi.fn();
    const { container } = render(
      <TabsNavigation activeTab="explore" onTabChange={mockOnChange} />
    );

    const tablist = container.querySelector('[role="tablist"]');
    expect(tablist).toBeInTheDocument();
  });

  it('deve ter role="tab" em cada aba', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    const tabs = screen.getAllByRole('tab');
    expect(tabs).toHaveLength(4);
  });

  it('deve suportar abas customizadas', () => {
    const mockOnChange = vi.fn();
    const customTabs = [
      { id: 'explore' as TabId, label: 'Custom Explore', ariaLabel: 'Custom tab' },
      { id: 'analyze' as TabId, label: 'Custom Analyze', ariaLabel: 'Custom analyze' },
    ];

    render(
      <TabsNavigation activeTab="explore" onTabChange={mockOnChange} tabs={customTabs} />
    );

    expect(screen.getByText('Custom Explore')).toBeInTheDocument();
    expect(screen.getByText('Custom Analyze')).toBeInTheDocument();
    expect(screen.queryByText('Design')).not.toBeInTheDocument();
  });

  it('deve permitir navegação por teclado (Ctrl+1)', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="analyze" onTabChange={mockOnChange} />);

    fireEvent.keyDown(window, { key: '1', ctrlKey: true });

    expect(mockOnChange).toHaveBeenCalledWith('explore');
  });

  it('deve permitir navegação por teclado (Ctrl+2)', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    fireEvent.keyDown(window, { key: '2', ctrlKey: true });

    expect(mockOnChange).toHaveBeenCalledWith('design');
  });

  it('não deve chamar onTabChange para teclas sem Ctrl', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    fireEvent.keyDown(window, { key: '1', ctrlKey: false });

    expect(mockOnChange).not.toHaveBeenCalled();
  });

  it('deve ter aria-controls apontando para o tabpanel correto', () => {
    const mockOnChange = vi.fn();
    render(<TabsNavigation activeTab="explore" onTabChange={mockOnChange} />);

    const exploreTab = screen.getByText('Explore');
    expect(exploreTab).toHaveAttribute('aria-controls', 'tabpanel-explore');

    const analyzeTab = screen.getByText('Analyze');
    expect(analyzeTab).toHaveAttribute('aria-controls', 'tabpanel-analyze');
  });
});
EOF

echo "[ok] Arquivos criados/atualizados com sucesso"
echo ""
echo "Arquivos afetados:"
echo "  ✓ packages/ui/src/components/TabsNavigation.tsx (novo)"
echo "  ✓ packages/ui/src/components/TabsNavigation.module.css (novo)"
echo "  ✓ packages/ui/src/components/tabs/ExploreTab.tsx (novo)"
echo "  ✓ packages/ui/src/components/tabs/DesignTab.tsx (novo)"
echo "  ✓ packages/ui/src/components/tabs/ExecuteTab.tsx (novo)"
echo "  ✓ packages/ui/src/components/tabs/AnalyzeTab.tsx (novo)"
echo "  ✓ packages/ui/src/App.tsx (atualizado)"
echo "  ✓ packages/ui/src/App.module.css (atualizado)"
echo "  ✓ packages/ui/src/components/TabsNavigation.spec.tsx (novo)"
echo ""
echo "Próximos passos:"
echo "  1. pnpm lint"
echo "  2. pnpm test"
echo "  3. pnpm typecheck"
echo "  4. pnpm build"
echo "  5. (opcional) REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
echo "[info] HU-UI-Tabs-004 implementada com sucesso!"
