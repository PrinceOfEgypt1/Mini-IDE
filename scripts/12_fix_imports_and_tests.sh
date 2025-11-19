#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script: 12_fix_imports_and_tests.sh
# Objetivo: Corrigir imports em WorkspaceTabs.tsx e ajustar testes problemáticos
# HU: HU-UI-Fix-Align-Wireframe-Explore (continuação)
# Versão: 1.0.17
# ============================================================================

echo "[info] Iniciando correção de imports e testes..."

# Verificar estrutura
if [[ ! -d "packages/ui/src/components" ]]; then
  echo "[erro] Diretório packages/ui/src/components não encontrado"
  exit 1
fi

# 1. Corrigir WorkspaceTabs.tsx
WORKSPACE_TABS="packages/ui/src/components/WorkspaceTabs.tsx"
cp "$WORKSPACE_TABS" "${WORKSPACE_TABS}.bak"

cat > "$WORKSPACE_TABS" << 'EOF'
import React, { useState } from 'react';
import styles from './WorkspaceTabs.module.css';
import { ServerStatus } from './ServerStatus.js';
import { AnalyzePlayground } from './AnalyzePlayground.js';
import { ExploreOverview } from './explore/ExploreOverview.js';
import { ExploreTimeline } from './explore/ExploreTimeline.js';

export type TabId =
  | 'overview'
  | 'hus'
  | 'docs'
  | 'tests'
  | 'analyze'
  | 'plan'
  | 'timeline'
  | 'runs'
  | 'metrics'
  | 'outputs';

export interface WorkspaceTabsProps {
  activeTab?: TabId;
  onTabChange?: (tabId: TabId) => void;
}

export function WorkspaceTabs({
  activeTab = 'overview',
  onTabChange,
}: WorkspaceTabsProps): JSX.Element {
  const [currentTab, setCurrentTab] = useState<TabId>(activeTab);

  const handleTabClick = (tabId: TabId) => {
    setCurrentTab(tabId);
    onTabChange?.(tabId);
  };

  const tabs: Array<{ id: TabId; label: string }> = [
    { id: 'overview', label: 'Overview' },
    { id: 'hus', label: 'HUs' },
    { id: 'docs', label: 'Docs' },
    { id: 'tests', label: 'Testes' },
    { id: 'analyze', label: 'Analyze' },
    { id: 'plan', label: 'Personas & Plano' },
    { id: 'timeline', label: 'Timeline' },
    { id: 'runs', label: 'Runs' },
    { id: 'metrics', label: 'Métricas' },
    { id: 'outputs', label: 'Outputs' },
  ];

  return (
    <section className={styles.workspaceTabs}>
      <div className={styles.tabs} role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={currentTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            className={`${styles.tab} ${currentTab === tab.id ? styles.tabActive : ''}`}
            onClick={() => handleTabClick(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className={styles.panels}>
        {currentTab === 'overview' && (
          <div role="tabpanel" id="panel-overview" className={styles.panel}>
            <ExploreOverview />
          </div>
        )}
        {currentTab === 'hus' && (
          <div role="tabpanel" id="panel-hus" className={styles.panel}>
            <h3>Histórias de Usuário</h3>
            <p className={styles.emptyState}>Nenhuma HU gerada ainda.</p>
          </div>
        )}
        {currentTab === 'docs' && (
          <div role="tabpanel" id="panel-docs" className={styles.panel}>
            <h3>Documentação</h3>
            <p className={styles.emptyState}>Crie um plano ou converta a conversa em HUs.</p>
          </div>
        )}
        {currentTab === 'tests' && (
          <div role="tabpanel" id="panel-tests" className={styles.panel}>
            <h3>Testes</h3>
            <p className={styles.emptyState}>Testes aparecerão após geração de plano técnico.</p>
          </div>
        )}
        {currentTab === 'analyze' && (
          <div role="tabpanel" id="panel-analyze" className={styles.panel}>
            <div className={styles.analyzeContainer}>
              <ServerStatus />
              <AnalyzePlayground />
            </div>
          </div>
        )}
        {currentTab === 'plan' && (
          <div role="tabpanel" id="panel-plan" className={styles.panel}>
            <h3>Personas & Plano</h3>
            <p className={styles.emptyState}>Nenhum plano gerado ainda.</p>
          </div>
        )}
        {currentTab === 'timeline' && (
          <div role="tabpanel" id="panel-timeline" className={styles.panel}>
            <ExploreTimeline />
          </div>
        )}
        {currentTab === 'runs' && (
          <div role="tabpanel" id="panel-runs" className={styles.panel}>
            <h3>Runs</h3>
            <p className={styles.emptyState}>Disponível após provisionamento.</p>
          </div>
        )}
        {currentTab === 'metrics' && (
          <div role="tabpanel" id="panel-metrics" className={styles.panel}>
            <h3>Métricas</h3>
            <p className={styles.emptyState}>Custo, tempo e tokens aparecerão após execuções.</p>
          </div>
        )}
        {currentTab === 'outputs' && (
          <div role="tabpanel" id="panel-outputs" className={styles.panel}>
            <h3>Outputs</h3>
            <pre className={styles.outputs}>Nenhum output ainda.</pre>
          </div>
        )}
      </div>
    </section>
  );
}
EOF

echo "[ok] WorkspaceTabs.tsx corrigido"

# 2. Corrigir ExploreOverview.test.tsx
OVERVIEW_TEST="packages/ui/src/components/explore/ExploreOverview.test.tsx"
if [[ -f "$OVERVIEW_TEST" ]]; then
  cp "$OVERVIEW_TEST" "${OVERVIEW_TEST}.bak"
  sed -i "s/expect(screen.getByText('Nenhuma análise realizada ainda.')).toBeInTheDocument();/expect(screen.getByText(\/Nenhuma análise realizada ainda\/)).toBeInTheDocument();/" "$OVERVIEW_TEST"
  echo "[ok] ExploreOverview.test.tsx corrigido (regex para texto quebrado)"
fi

echo ""
echo "========================================="
echo "✅ Correções Aplicadas"
echo "========================================="
echo "Execute agora:"
echo "  1. pnpm --filter @mini-ide/ui typecheck"
echo "  2. pnpm --filter @mini-ide/ui test"
echo "  3. pnpm --filter @mini-ide/ui build"
echo "========================================="#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script: 12_fix_imports_and_tests.sh
# Objetivo: Corrigir imports em WorkspaceTabs.tsx e ajustar testes problemáticos
# HU: HU-UI-Fix-Align-Wireframe-Explore (continuação)
# Versão: 1.0.17
# ============================================================================

echo "[info] Iniciando correção de imports e testes..."

# Verificar estrutura
if [[ ! -d "packages/ui/src/components" ]]; then
  echo "[erro] Diretório packages/ui/src/components não encontrado"
  exit 1
fi

# 1. Corrigir WorkspaceTabs.tsx
WORKSPACE_TABS="packages/ui/src/components/WorkspaceTabs.tsx"
cp "$WORKSPACE_TABS" "${WORKSPACE_TABS}.bak"

cat > "$WORKSPACE_TABS" << 'EOF'
import React, { useState } from 'react';
import styles from './WorkspaceTabs.module.css';
import { ServerStatus } from './ServerStatus.js';
import { AnalyzePlayground } from './AnalyzePlayground.js';
import { ExploreOverview } from './explore/ExploreOverview.js';
import { ExploreTimeline } from './explore/ExploreTimeline.js';

export type TabId =
  | 'overview'
  | 'hus'
  | 'docs'
  | 'tests'
  | 'analyze'
  | 'plan'
  | 'timeline'
  | 'runs'
  | 'metrics'
  | 'outputs';

export interface WorkspaceTabsProps {
  activeTab?: TabId;
  onTabChange?: (tabId: TabId) => void;
}

export function WorkspaceTabs({
  activeTab = 'overview',
  onTabChange,
}: WorkspaceTabsProps): JSX.Element {
  const [currentTab, setCurrentTab] = useState<TabId>(activeTab);

  const handleTabClick = (tabId: TabId) => {
    setCurrentTab(tabId);
    onTabChange?.(tabId);
  };

  const tabs: Array<{ id: TabId; label: string }> = [
    { id: 'overview', label: 'Overview' },
    { id: 'hus', label: 'HUs' },
    { id: 'docs', label: 'Docs' },
    { id: 'tests', label: 'Testes' },
    { id: 'analyze', label: 'Analyze' },
    { id: 'plan', label: 'Personas & Plano' },
    { id: 'timeline', label: 'Timeline' },
    { id: 'runs', label: 'Runs' },
    { id: 'metrics', label: 'Métricas' },
    { id: 'outputs', label: 'Outputs' },
  ];

  return (
    <section className={styles.workspaceTabs}>
      <div className={styles.tabs} role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={currentTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            className={`${styles.tab} ${currentTab === tab.id ? styles.tabActive : ''}`}
            onClick={() => handleTabClick(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className={styles.panels}>
        {currentTab === 'overview' && (
          <div role="tabpanel" id="panel-overview" className={styles.panel}>
            <ExploreOverview />
          </div>
        )}
        {currentTab === 'hus' && (
          <div role="tabpanel" id="panel-hus" className={styles.panel}>
            <h3>Histórias de Usuário</h3>
            <p className={styles.emptyState}>Nenhuma HU gerada ainda.</p>
          </div>
        )}
        {currentTab === 'docs' && (
          <div role="tabpanel" id="panel-docs" className={styles.panel}>
            <h3>Documentação</h3>
            <p className={styles.emptyState}>Crie um plano ou converta a conversa em HUs.</p>
          </div>
        )}
        {currentTab === 'tests' && (
          <div role="tabpanel" id="panel-tests" className={styles.panel}>
            <h3>Testes</h3>
            <p className={styles.emptyState}>Testes aparecerão após geração de plano técnico.</p>
          </div>
        )}
        {currentTab === 'analyze' && (
          <div role="tabpanel" id="panel-analyze" className={styles.panel}>
            <div className={styles.analyzeContainer}>
              <ServerStatus />
              <AnalyzePlayground />
            </div>
          </div>
        )}
        {currentTab === 'plan' && (
          <div role="tabpanel" id="panel-plan" className={styles.panel}>
            <h3>Personas & Plano</h3>
            <p className={styles.emptyState}>Nenhum plano gerado ainda.</p>
          </div>
        )}
        {currentTab === 'timeline' && (
          <div role="tabpanel" id="panel-timeline" className={styles.panel}>
            <ExploreTimeline />
          </div>
        )}
        {currentTab === 'runs' && (
          <div role="tabpanel" id="panel-runs" className={styles.panel}>
            <h3>Runs</h3>
            <p className={styles.emptyState}>Disponível após provisionamento.</p>
          </div>
        )}
        {currentTab === 'metrics' && (
          <div role="tabpanel" id="panel-metrics" className={styles.panel}>
            <h3>Métricas</h3>
            <p className={styles.emptyState}>Custo, tempo e tokens aparecerão após execuções.</p>
          </div>
        )}
        {currentTab === 'outputs' && (
          <div role="tabpanel" id="panel-outputs" className={styles.panel}>
            <h3>Outputs</h3>
            <pre className={styles.outputs}>Nenhum output ainda.</pre>
          </div>
        )}
      </div>
    </section>
  );
}
EOF

echo "[ok] WorkspaceTabs.tsx corrigido"

# 2. Corrigir ExploreOverview.test.tsx
OVERVIEW_TEST="packages/ui/src/components/explore/ExploreOverview.test.tsx"
if [[ -f "$OVERVIEW_TEST" ]]; then
  cp "$OVERVIEW_TEST" "${OVERVIEW_TEST}.bak"
  sed -i "s/expect(screen.getByText('Nenhuma análise realizada ainda.')).toBeInTheDocument();/expect(screen.getByText(\/Nenhuma análise realizada ainda\/)).toBeInTheDocument();/" "$OVERVIEW_TEST"
  echo "[ok] ExploreOverview.test.tsx corrigido (regex para texto quebrado)"
fi

echo ""
echo "========================================="
echo "✅ Correções Aplicadas"
echo "========================================="
echo "Execute agora:"
echo "  1. pnpm --filter @mini-ide/ui typecheck"
echo "  2. pnpm --filter @mini-ide/ui test"
echo "  3. pnpm --filter @mini-ide/ui build"
echo "========================================="#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Script: 12_fix_imports_and_tests.sh
# Objetivo: Corrigir imports em WorkspaceTabs.tsx e ajustar testes problemáticos
# HU: HU-UI-Fix-Align-Wireframe-Explore (continuação)
# Versão: 1.0.17
# ============================================================================

echo "[info] Iniciando correção de imports e testes..."

# Verificar estrutura
if [[ ! -d "packages/ui/src/components" ]]; then
  echo "[erro] Diretório packages/ui/src/components não encontrado"
  exit 1
fi

# 1. Corrigir WorkspaceTabs.tsx
WORKSPACE_TABS="packages/ui/src/components/WorkspaceTabs.tsx"
cp "$WORKSPACE_TABS" "${WORKSPACE_TABS}.bak"

cat > "$WORKSPACE_TABS" << 'EOF'
import React, { useState } from 'react';
import styles from './WorkspaceTabs.module.css';
import { ServerStatus } from './ServerStatus.js';
import { AnalyzePlayground } from './AnalyzePlayground.js';
import { ExploreOverview } from './explore/ExploreOverview.js';
import { ExploreTimeline } from './explore/ExploreTimeline.js';

export type TabId =
  | 'overview'
  | 'hus'
  | 'docs'
  | 'tests'
  | 'analyze'
  | 'plan'
  | 'timeline'
  | 'runs'
  | 'metrics'
  | 'outputs';

export interface WorkspaceTabsProps {
  activeTab?: TabId;
  onTabChange?: (tabId: TabId) => void;
}

export function WorkspaceTabs({
  activeTab = 'overview',
  onTabChange,
}: WorkspaceTabsProps): JSX.Element {
  const [currentTab, setCurrentTab] = useState<TabId>(activeTab);

  const handleTabClick = (tabId: TabId) => {
    setCurrentTab(tabId);
    onTabChange?.(tabId);
  };

  const tabs: Array<{ id: TabId; label: string }> = [
    { id: 'overview', label: 'Overview' },
    { id: 'hus', label: 'HUs' },
    { id: 'docs', label: 'Docs' },
    { id: 'tests', label: 'Testes' },
    { id: 'analyze', label: 'Analyze' },
    { id: 'plan', label: 'Personas & Plano' },
    { id: 'timeline', label: 'Timeline' },
    { id: 'runs', label: 'Runs' },
    { id: 'metrics', label: 'Métricas' },
    { id: 'outputs', label: 'Outputs' },
  ];

  return (
    <section className={styles.workspaceTabs}>
      <div className={styles.tabs} role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={currentTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            className={`${styles.tab} ${currentTab === tab.id ? styles.tabActive : ''}`}
            onClick={() => handleTabClick(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className={styles.panels}>
        {currentTab === 'overview' && (
          <div role="tabpanel" id="panel-overview" className={styles.panel}>
            <ExploreOverview />
          </div>
        )}
        {currentTab === 'hus' && (
          <div role="tabpanel" id="panel-hus" className={styles.panel}>
            <h3>Histórias de Usuário</h3>
            <p className={styles.emptyState}>Nenhuma HU gerada ainda.</p>
          </div>
        )}
        {currentTab === 'docs' && (
          <div role="tabpanel" id="panel-docs" className={styles.panel}>
            <h3>Documentação</h3>
            <p className={styles.emptyState}>Crie um plano ou converta a conversa em HUs.</p>
          </div>
        )}
        {currentTab === 'tests' && (
          <div role="tabpanel" id="panel-tests" className={styles.panel}>
            <h3>Testes</h3>
            <p className={styles.emptyState}>Testes aparecerão após geração de plano técnico.</p>
          </div>
        )}
        {currentTab === 'analyze' && (
          <div role="tabpanel" id="panel-analyze" className={styles.panel}>
            <div className={styles.analyzeContainer}>
              <ServerStatus />
              <AnalyzePlayground />
            </div>
          </div>
        )}
        {currentTab === 'plan' && (
          <div role="tabpanel" id="panel-plan" className={styles.panel}>
            <h3>Personas & Plano</h3>
            <p className={styles.emptyState}>Nenhum plano gerado ainda.</p>
          </div>
        )}
        {currentTab === 'timeline' && (
          <div role="tabpanel" id="panel-timeline" className={styles.panel}>
            <ExploreTimeline />
          </div>
        )}
        {currentTab === 'runs' && (
          <div role="tabpanel" id="panel-runs" className={styles.panel}>
            <h3>Runs</h3>
            <p className={styles.emptyState}>Disponível após provisionamento.</p>
          </div>
        )}
        {currentTab === 'metrics' && (
          <div role="tabpanel" id="panel-metrics" className={styles.panel}>
            <h3>Métricas</h3>
            <p className={styles.emptyState}>Custo, tempo e tokens aparecerão após execuções.</p>
          </div>
        )}
        {currentTab === 'outputs' && (
          <div role="tabpanel" id="panel-outputs" className={styles.panel}>
            <h3>Outputs</h3>
            <pre className={styles.outputs}>Nenhum output ainda.</pre>
          </div>
        )}
      </div>
    </section>
  );
}
EOF

echo "[ok] WorkspaceTabs.tsx corrigido"

# 2. Corrigir ExploreOverview.test.tsx
OVERVIEW_TEST="packages/ui/src/components/explore/ExploreOverview.test.tsx"
if [[ -f "$OVERVIEW_TEST" ]]; then
  cp "$OVERVIEW_TEST" "${OVERVIEW_TEST}.bak"
  sed -i "s/expect(screen.getByText('Nenhuma análise realizada ainda.')).toBeInTheDocument();/expect(screen.getByText(\/Nenhuma análise realizada ainda\/)).toBeInTheDocument();/" "$OVERVIEW_TEST"
  echo "[ok] ExploreOverview.test.tsx corrigido (regex para texto quebrado)"
fi

echo ""
echo "========================================="
echo "✅ Correções Aplicadas"
echo "========================================="
echo "Execute agora:"
echo "  1. pnpm --filter @mini-ide/ui typecheck"
echo "  2. pnpm --filter @mini-ide/ui test"
echo "  3. pnpm --filter @mini-ide/ui build"
echo "========================================="
