#!/usr/bin/env bash
# ==============================================================================
# Script: 07_integrate_with_workspace_tabs.sh
# HU: Integração das HUs UI-Discovery-Notes-002, UI-Explore-Mode-001, UI-Timeline-003
# ==============================================================================
# Objetivo:
#   Integrar os novos componentes ExploreOverview e ExploreTimeline nas abas
#   correspondentes do WorkspaceTabs, mantendo layout de 3 colunas intacto.
#
# Arquivos afetados:
#   - packages/ui/src/components/WorkspaceTabs.tsx (atualizado)
#   - packages/ui/src/components/WorkspaceTabs.module.css (atualizado/criado)
#
# Premissas:
#   - WorkspaceTabs.tsx já existe e tem 10 abas definidas
#   - DiscoveryNotes já está integrada no painel direito do App.tsx
#   - Layout de 3 colunas NÃO muda
#   - TypeScript strict mode
#
# Riscos:
#   - NENHUM: apenas evolução interna das abas existentes
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/WorkspaceTabs.tsx
#   git checkout HEAD -- packages/ui/src/components/WorkspaceTabs.module.css
# ==============================================================================

set -euo pipefail

echo "[info] Integrando novos componentes com WorkspaceTabs..."

# ------------------------------------------------------------------------------  
# 0. Garantir diretório correto dos arquivos
# ------------------------------------------------------------------------------  
TARGET_TSX="packages/ui/src/components/WorkspaceTabs.tsx"
TARGET_CSS="packages/ui/src/components/WorkspaceTabs.module.css"

TARGET_DIR="$(dirname "$TARGET_TSX")"
mkdir -p "$TARGET_DIR"

echo "[info] Arquivo TSX alvo:  $TARGET_TSX"
echo "[info] Arquivo CSS alvo:  $TARGET_CSS"

# ------------------------------------------------------------------------------  
# WorkspaceTabs.tsx - Integração dos novos componentes
# ------------------------------------------------------------------------------  
cat > "$TARGET_TSX" << 'EOF'
/**
 * @file WorkspaceTabs.tsx
 * @description Sistema de abas do painel central (coluna do meio)
 * @module @mini-ide/ui/components/workspace
 */

import { useState } from 'react';
import styles from './WorkspaceTabs.module.css';
import { ServerStatus } from '../analyze/ServerStatus.js';
import { AnalyzePlayground } from '../analyze/AnalyzePlayground.js';
import { ExploreOverview } from '../explore/ExploreOverview.js';
import { ExploreTimeline } from '../explore/ExploreTimeline.js';

/**
 * Identificadores das abas disponíveis
 */
export type TabId =
  | 'overview'
  | 'hus'
  | 'docs'
  | 'tests'
  | 'analyze'
  | 'personas'
  | 'timeline'
  | 'runs'
  | 'metrics'
  | 'outputs';

/**
 * Definição de uma aba
 */
interface TabDefinition {
  id: TabId;
  label: string;
  icon?: string;
}

/**
 * Abas disponíveis no workspace (10 abas conforme wireframe)
 */
const TABS: TabDefinition[] = [
  { id: 'overview', label: 'Overview', icon: '🏠' },
  { id: 'hus', label: 'HUs', icon: '📋' },
  { id: 'docs', label: 'Docs', icon: '📚' },
  { id: 'tests', label: 'Testes', icon: '🧪' },
  { id: 'analyze', label: 'Analyze', icon: '🔬' },
  { id: 'personas', label: 'Personas & Plano', icon: '👥' },
  { id: 'timeline', label: 'Timeline', icon: '📈' },
  { id: 'runs', label: 'Runs', icon: '▶️' },
  { id: 'metrics', label: 'Métricas', icon: '📊' },
  { id: 'outputs', label: 'Outputs', icon: '📦' },
];

/**
 * Componente WorkspaceTabs - Sistema de abas do painel central
 *
 * Funcionalidades:
 * - 10 abas internas conforme wireframe oficial
 * - Navegação por abas com estado local
 * - Integra componentes especializados:
 *   - Overview: ExploreOverview (HU-UI-Explore-Mode-001)
 *   - Timeline: ExploreTimeline (HU-UI-Timeline-003)
 *   - Analyze: ServerStatus + AnalyzePlayground
 * - Placeholder para abas ainda não implementadas
 *
 * Layout:
 * - Renderizado no painel central da UI Explore
 * - Respeita estrutura de 3 colunas do wireframe
 */
export function WorkspaceTabs() {
  const [activeTab, setActiveTab] = useState<TabId>('overview');

  /**
   * Renderiza o conteúdo da aba ativa
   */
  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return (
          <div className={styles.tabContent}>
            <ExploreOverview />
          </div>
        );

      case 'hus':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>📋</span>
              <h3 className={styles.placeholderTitle}>HUs (User Stories)</h3>
              <p className={styles.placeholderText}>
                Visualização de HUs geradas e gerenciamento de backlog será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'docs':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>📚</span>
              <h3 className={styles.placeholderTitle}>Documentação</h3>
              <p className={styles.placeholderText}>
                Visualização e edição de documentação técnica será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'tests':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>🧪</span>
              <h3 className={styles.placeholderTitle}>Testes</h3>
              <p className={styles.placeholderText}>
                Visualização de resultados de testes e cobertura será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'analyze':
        return (
          <div className={styles.tabContent}>
            <div className={styles.analyzeTab}>
              <div className={styles.analyzeHeader}>
                <h3 className={styles.analyzeTitle}>Analyze Playground</h3>
                <ServerStatus />
              </div>
              <AnalyzePlayground />
            </div>
          </div>
        );

      case 'personas':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>👥</span>
              <h3 className={styles.placeholderTitle}>Personas & Plano</h3>
              <p className={styles.placeholderText}>
                Visualização de personas e plano técnico será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'timeline':
        return (
          <div className={styles.tabContent}>
            <ExploreTimeline />
          </div>
        );

      case 'runs':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>▶️</span>
              <h3 className={styles.placeholderTitle}>Runs</h3>
              <p className={styles.placeholderText}>
                Histórico de execuções e resultados será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'metrics':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>📊</span>
              <h3 className={styles.placeholderTitle}>Métricas</h3>
              <p className={styles.placeholderText}>
                Dashboard de métricas e observabilidade será implementado em breve.
              </p>
            </div>
          </div>
        );

      case 'outputs':
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>📦</span>
              <h3 className={styles.placeholderTitle}>Outputs</h3>
              <p className={styles.placeholderText}>
                Visualização de artefatos gerados será implementado em breve.
              </p>
            </div>
          </div>
        );

      default:
        return (
          <div className={styles.tabContent}>
            <div className={styles.placeholder}>
              <span className={styles.placeholderIcon}>⚠️</span>
              <h3 className={styles.placeholderTitle}>Aba não encontrada</h3>
              <p className={styles.placeholderText}>
                A aba selecionada não foi implementada ainda.
              </p>
            </div>
          </div>
        );
    }
  };

  return (
    <div className={styles.workspaceTabs}>
      {/* Barra de abas */}
      <div className={styles.tabBar}>
        <div className={styles.tabs}>
          {TABS.map((tab) => (
            <button
              key={tab.id}
              className={`${styles.tab} ${activeTab === tab.id ? styles.tabActive : ''}`}
              onClick={() => setActiveTab(tab.id)}
              type="button"
              aria-label={`Aba ${tab.label}`}
              aria-current={activeTab === tab.id ? 'page' : undefined}
            >
              {tab.icon && <span className={styles.tabIcon}>{tab.icon}</span>}
              <span className={styles.tabLabel}>{tab.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Conteúdo da aba ativa */}
      {renderTabContent()}
    </div>
  );
}
EOF

echo "[ok] WorkspaceTabs.tsx atualizado com integração dos novos componentes"

# ------------------------------------------------------------------------------  
# WorkspaceTabs.module.css - Estilos (garantir compatibilidade)
# ------------------------------------------------------------------------------  
cat > "$TARGET_CSS" << 'EOF'
/**
 * @file WorkspaceTabs.module.css
 * @description Estilos para o sistema de abas do workspace
 */

.workspaceTabs {
  display: flex;
  flex-direction: column;
  height: 100%;
  gap: 12px;
}

/* ============================================================================
   Barra de Abas
   ============================================================================ */

.tabBar {
  border-bottom: 1px solid var(--border, #24304a);
}

.tabs {
  display: flex;
  gap: 4px;
  overflow-x: auto;
  padding: 4px 0;
}

.tabs::-webkit-scrollbar {
  height: 4px;
}

.tabs::-webkit-scrollbar-track {
  background: transparent;
}

.tabs::-webkit-scrollbar-thumb {
  background: var(--border, #24304a);
  border-radius: 2px;
}

.tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: transparent;
  border: 1px solid transparent;
  border-radius: 999px;
  color: var(--muted, #9fb0d3);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
  flex-shrink: 0;
}

.tab:hover {
  background: var(--panel-2, #101727);
  border-color: var(--border, #24304a);
  color: var(--text, #e6ecff);
}

.tabActive {
  background: var(--brand, #4ba3ff);
  border-color: transparent;
  color: white;
}

.tabActive:hover {
  background: var(--brand-2, #6ad3ff);
  color: white;
}

.tabIcon {
  font-size: 14px;
  line-height: 1;
}

.tabLabel {
  font-size: 13px;
}

/* ============================================================================
   Conteúdo da Aba
   ============================================================================ */

.tabContent {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  min-height: 0;
}

/* ============================================================================
   Aba Analyze
   ============================================================================ */

.analyzeTab {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 16px;
}

.analyzeHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 12px;
  border-bottom: 1px solid var(--border, #24304a);
}

.analyzeTitle {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

/* ============================================================================
   Placeholder para abas não implementadas
   ============================================================================ */

.placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 40px;
  text-align: center;
  min-height: 300px;
}

.placeholderIcon {
  font-size: 64px;
  margin-bottom: 20px;
  opacity: 0.5;
}

.placeholderTitle {
  margin: 0 0 12px 0;
  font-size: 20px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.placeholderText {
  margin: 0;
  font-size: 14px;
  color: var(--muted, #9fb0d3);
  line-height: 1.6;
  max-width: 400px;
}

/* ============================================================================
   Scrollbar customizada
   ============================================================================ */

.tabContent::-webkit-scrollbar {
  width: 6px;
}

.tabContent::-webkit-scrollbar-track {
  background: transparent;
}

.tabContent::-webkit-scrollbar-thumb {
  background: var(--border, #24304a);
  border-radius: 3px;
}

.tabContent::-webkit-scrollbar-thumb:hover {
  background: var(--muted, #9fb0d3);
}

/* ============================================================================
   Responsividade
   ============================================================================ */

@media (maxwidth: 900px) {
  .tab {
    padding: 6px 10px;
    font-size: 12px;
  }

  .tabIcon {
    font-size: 12px;
  }

  .analyzeTab {
    padding: 12px;
  }

  .placeholder {
    padding: 40px 20px;
    min-height: 200px;
  }

  .placeholderIcon {
    font-size: 48px;
  }

  .placeholderTitle {
    font-size: 18px;
  }
}
EOF

echo "[ok] WorkspaceTabs.module.css atualizado"

# ------------------------------------------------------------------------------  
# Sumário
# ------------------------------------------------------------------------------  
echo ""
echo "========================================="
echo "✅ Integração com WorkspaceTabs concluída"
echo "========================================="
echo "Arquivos criados/modificados:"
echo "  - $TARGET_TSX"
echo "  - $TARGET_CSS"
echo ""
echo "Integrações realizadas:"
echo "  ✓ Aba Overview → ExploreOverview (HU-UI-Explore-Mode-001)"
echo "  ✓ Aba Timeline → ExploreTimeline (HU-UI-Timeline-003)"
echo "  ✓ Aba Analyze → ServerStatus + AnalyzePlayground (já existente)"
echo "  ✓ Outras 7 abas → Placeholder para implementação futura"
echo ""
echo "Layout preservado:"
echo "  ✓ 10 abas internas conforme wireframe"
echo "  ✓ Estrutura de 3 colunas intacta"
echo "  ✓ Painel central expansível"
echo ""
echo "Nota:"
echo "  - DiscoveryNotes evoluídas (HU-UI-Discovery-Notes-002) já está"
echo "    integrada no painel direito do App.tsx"
echo ""
echo "Próximos passos:"
echo "  1. Execute: pnpm --filter @mini-ide/ui lint"
echo "  2. Execute: pnpm --filter @mini-ide/ui test"
echo "  3. Execute: pnpm --filter @mini-ide/ui typecheck"
echo "  4. Execute: pnpm --filter @mini-ide/ui build"
echo "========================================="
