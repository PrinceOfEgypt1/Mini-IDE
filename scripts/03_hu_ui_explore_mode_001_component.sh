#!/usr/bin/env bash
# ==============================================================================
# Script: 03_hu_ui_explore_mode_001_component.sh
# HU: HU-UI-Explore-Mode-001 – Modo Explorar com Coleta Automática
# ==============================================================================
# Objetivo:
#   Evoluir a aba Overview do painel central para exibir estado da sessão
#   de exploração, projeto atual e últimas análises.
#
# Arquivos afetados:
#   - packages/ui/src/components/explore/ExploreOverview.tsx (criado)
#   - packages/ui/src/components/explore/ExploreOverview.module.css (criado)
#   - packages/ui/src/components/workspace/WorkspaceTabs.tsx (atualizado)
#
# Premissas:
#   - Aba Overview já existe em WorkspaceTabs
#   - Layout de 3 colunas permanece intacto
#   - Dados mockados nesta primeira versão
#   - TypeScript strict mode
#
# Riscos:
#   - Nenhum risco de quebra (apenas evolução interna da aba Overview)
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/explore/
#   git checkout HEAD -- packages/ui/src/components/workspace/WorkspaceTabs.tsx
# ==============================================================================

set -euo pipefail

echo "[info] Iniciando implementação da HU-UI-Explore-Mode-001..."

# ------------------------------------------------------------------------------
# 1. Criar diretório explore se não existir
# ------------------------------------------------------------------------------
mkdir -p packages/ui/src/components/explore

echo "[ok] Diretório explore criado/verificado"

# ------------------------------------------------------------------------------
# 2. ExploreOverview.tsx - Componente da aba Overview evoluída
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreOverview.tsx << 'EOF'
/**
 * @file ExploreOverview.tsx
 * @description Aba Overview evoluída com estado da sessão de exploração
 * @module @mini-ide/ui/components/explore
 */

import { useState, useEffect } from 'react';
import styles from './ExploreOverview.module.css';

/**
 * Estados possíveis da sessão de exploração
 */
export type SessionState = 
  | 'Discovery'
  | 'Execution'
  | 'Review'
  | 'Idle';

/**
 * Informações do projeto atual
 */
export interface ProjectInfo {
  name: string;
  repository?: string;
  branch: string;
  path?: string;
}

/**
 * Registro de análise realizada
 */
export interface AnalysisRecord {
  id: string;
  timestamp: Date;
  summary: string;
  inputLength: number;
  outputLength: number;
}

/**
 * Props do componente ExploreOverview
 */
export interface ExploreOverviewProps {
  /** Informações do projeto (mockadas se não fornecidas) */
  projectInfo?: ProjectInfo;
  /** Estado atual da sessão */
  sessionState?: SessionState;
  /** Últimas análises realizadas */
  recentAnalyses?: AnalysisRecord[];
}

/**
 * Valores padrão mockados para desenvolvimento
 */
const DEFAULT_PROJECT: ProjectInfo = {
  name: 'Mini-IDE',
  repository: 'PrinceOfEgypt1/Mini-IDE',
  branch: 'main',
  path: '~/workspace/Mini-IDE',
};

const DEFAULT_SESSION_STATE: SessionState = 'Discovery';

const MOCK_ANALYSES: AnalysisRecord[] = [
  {
    id: '1',
    timestamp: new Date(Date.now() - 300000), // 5 min atrás
    summary: 'Análise de estrutura de componentes React',
    inputLength: 1523,
    outputLength: 245,
  },
  {
    id: '2',
    timestamp: new Date(Date.now() - 600000), // 10 min atrás
    summary: 'Verificação de tipagem TypeScript em módulos',
    inputLength: 982,
    outputLength: 156,
  },
  {
    id: '3',
    timestamp: new Date(Date.now() - 900000), // 15 min atrás
    summary: 'Revisão de padrões de testes Vitest',
    inputLength: 754,
    outputLength: 123,
  },
];

/**
 * Retorna classe CSS baseada no estado da sessão
 */
function getSessionStateClass(state: SessionState): string {
  const stateMap: Record<SessionState, string> = {
    Discovery: styles.stateDiscovery,
    Execution: styles.stateExecution,
    Review: styles.stateReview,
    Idle: styles.stateIdle,
  };
  return stateMap[state] || styles.stateIdle;
}

/**
 * Retorna emoji baseado no estado da sessão
 */
function getSessionStateEmoji(state: SessionState): string {
  const emojiMap: Record<SessionState, string> = {
    Discovery: '🔍',
    Execution: '⚡',
    Review: '📋',
    Idle: '💤',
  };
  return emojiMap[state] || '💤';
}

/**
 * Formata timestamp relativo (ex: "5 min atrás")
 */
function formatRelativeTime(date: Date): string {
  const now = Date.now();
  const diff = now - date.getTime();
  const minutes = Math.floor(diff / 60000);

  if (minutes < 1) return 'agora';
  if (minutes === 1) return '1 min atrás';
  if (minutes < 60) return `${minutes} min atrás`;

  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hora atrás';
  if (hours < 24) return `${hours} horas atrás`;

  const days = Math.floor(hours / 24);
  return days === 1 ? '1 dia atrás' : `${days} dias atrás`;
}

/**
 * Componente ExploreOverview - Aba Overview do modo Explorar
 * 
 * Funcionalidades:
 * - Exibe informações do projeto atual
 * - Mostra estado da sessão de exploração
 * - Lista últimas análises realizadas
 * - Suporta dados mockados para desenvolvimento
 * 
 * Layout:
 * - Renderizado dentro da aba Overview do painel central
 * - Respeita estrutura de 3 colunas do wireframe
 */
export function ExploreOverview({
  projectInfo = DEFAULT_PROJECT,
  sessionState = DEFAULT_SESSION_STATE,
  recentAnalyses = MOCK_ANALYSES,
}: ExploreOverviewProps) {
  const [currentTime, setCurrentTime] = useState(new Date());

  // Atualiza tempo a cada minuto para refresh de timestamps relativos
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(new Date());
    }, 60000); // 1 minuto

    return () => clearInterval(interval);
  }, []);

  return (
    <div className={styles.exploreOverview}>
      {/* Seção: Estado da Sessão */}
      <div className={styles.section}>
        <div className={styles.sectionHeader}>
          <h3 className={styles.sectionTitle}>Estado da Sessão</h3>
        </div>
        <div className={`${styles.sessionState} ${getSessionStateClass(sessionState)}`}>
          <span className={styles.sessionEmoji}>{getSessionStateEmoji(sessionState)}</span>
          <div className={styles.sessionInfo}>
            <div className={styles.sessionLabel}>{sessionState}</div>
            <div className={styles.sessionDescription}>
              {sessionState === 'Discovery' && 'Coletando requisitos e intenções'}
              {sessionState === 'Execution' && 'Executando análises e processamentos'}
              {sessionState === 'Review' && 'Revisando resultados e artefatos'}
              {sessionState === 'Idle' && 'Aguardando próxima ação'}
            </div>
          </div>
        </div>
      </div>

      {/* Seção: Projeto Atual */}
      <div className={styles.section}>
        <div className={styles.sectionHeader}>
          <h3 className={styles.sectionTitle}>Projeto Atual</h3>
        </div>
        <div className={styles.projectCard}>
          <div className={styles.projectName}>
            <span className={styles.projectIcon}>📁</span>
            {projectInfo.name}
          </div>
          {projectInfo.repository && (
            <div className={styles.projectDetail}>
              <span className={styles.detailLabel}>Repositório:</span>
              <span className={styles.detailValue}>{projectInfo.repository}</span>
            </div>
          )}
          <div className={styles.projectDetail}>
            <span className={styles.detailLabel}>Branch:</span>
            <span className={styles.branchBadge}>{projectInfo.branch}</span>
          </div>
          {projectInfo.path && (
            <div className={styles.projectDetail}>
              <span className={styles.detailLabel}>Caminho:</span>
              <span className={styles.detailValue}>{projectInfo.path}</span>
            </div>
          )}
        </div>
      </div>

      {/* Seção: Últimas Análises */}
      <div className={styles.section}>
        <div className={styles.sectionHeader}>
          <h3 className={styles.sectionTitle}>Últimas Análises</h3>
          <span className={styles.badge}>{recentAnalyses.length}</span>
        </div>
        {recentAnalyses.length === 0 ? (
          <div className={styles.emptyState}>
            <span className={styles.emptyIcon}>📊</span>
            <p className={styles.emptyText}>
              Nenhuma análise realizada ainda.
              <br />
              Use a aba <strong>Analyze</strong> para começar.
            </p>
          </div>
        ) : (
          <div className={styles.analysisList}>
            {recentAnalyses.map((analysis) => (
              <div key={analysis.id} className={styles.analysisCard}>
                <div className={styles.analysisHeader}>
                  <span className={styles.analysisIcon}>🔬</span>
                  <span className={styles.analysisTime}>
                    {formatRelativeTime(analysis.timestamp)}
                  </span>
                </div>
                <div className={styles.analysisSummary}>{analysis.summary}</div>
                <div className={styles.analysisMetrics}>
                  <span className={styles.metric}>
                    ↓ {analysis.inputLength} chars
                  </span>
                  <span className={styles.metric}>
                    ↑ {analysis.outputLength} chars
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
EOF

echo "[ok] ExploreOverview.tsx criado com sucesso"

# ------------------------------------------------------------------------------
# 3. ExploreOverview.module.css - Estilos do componente
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreOverview.module.css << 'EOF'
/**
 * @file ExploreOverview.module.css
 * @description Estilos para o componente ExploreOverview (aba Overview)
 */

.exploreOverview {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 4px;
}

/* ============================================================================
   Seções Gerais
   ============================================================================ */

.section {
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 12px;
  padding: 16px;
}

.sectionHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}

.sectionTitle {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.badge {
  background: var(--chip, #222b40);
  border: 1px solid var(--border, #24304a);
  border-radius: 999px;
  padding: 2px 8px;
  font-size: 12px;
  font-weight: 600;
  color: var(--muted, #9fb0d3);
}

/* ============================================================================
   Estado da Sessão
   ============================================================================ */

.sessionState {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px;
  background: var(--panel-3, #0c1323);
  border: 2px solid var(--border, #24304a);
  border-radius: 10px;
  transition: border-color 0.3s ease;
}

.sessionEmoji {
  font-size: 32px;
  line-height: 1;
}

.sessionInfo {
  flex: 1;
}

.sessionLabel {
  font-size: 16px;
  font-weight: 600;
  color: var(--text, #e6ecff);
  margin-bottom: 4px;
}

.sessionDescription {
  font-size: 13px;
  color: var(--muted, #9fb0d3);
}

/* Estados específicos */
.stateDiscovery {
  border-color: var(--brand, #4ba3ff);
  background: linear-gradient(135deg, rgba(75, 163, 255, 0.05), var(--panel-3, #0c1323));
}

.stateExecution {
  border-color: var(--accent, #00c2a8);
  background: linear-gradient(135deg, rgba(0, 194, 168, 0.05), var(--panel-3, #0c1323));
}

.stateReview {
  border-color: var(--ok, #47e6a1);
  background: linear-gradient(135deg, rgba(71, 230, 161, 0.05), var(--panel-3, #0c1323));
}

.stateIdle {
  border-color: var(--border, #24304a);
}

/* ============================================================================
   Projeto Atual
   ============================================================================ */

.projectCard {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px;
  background: var(--panel-3, #0c1323);
  border-radius: 8px;
}

.projectName {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.projectIcon {
  font-size: 18px;
}

.projectDetail {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.detailLabel {
  color: var(--muted, #9fb0d3);
  font-weight: 500;
  min-width: 90px;
}

.detailValue {
  color: var(--text, #e6ecff);
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  font-size: 12px;
}

.branchBadge {
  background: var(--chip, #222b40);
  border: 1px solid var(--border, #24304a);
  border-radius: 6px;
  padding: 2px 8px;
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  font-size: 12px;
  color: var(--ok, #47e6a1);
}

/* ============================================================================
   Últimas Análises
   ============================================================================ */

.analysisList {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.analysisCard {
  padding: 12px;
  background: var(--panel-3, #0c1323);
  border: 1px solid var(--border, #24304a);
  border-radius: 8px;
  transition: border-color 0.2s ease, transform 0.2s ease;
}

.analysisCard:hover {
  border-color: var(--brand, #4ba3ff);
  transform: translateX(2px);
}

.analysisHeader {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.analysisIcon {
  font-size: 16px;
}

.analysisTime {
  font-size: 12px;
  color: var(--muted, #9fb0d3);
}

.analysisSummary {
  font-size: 14px;
  color: var(--text, #e6ecff);
  margin-bottom: 8px;
  line-height: 1.5;
}

.analysisMetrics {
  display: flex;
  gap: 12px;
}

.metric {
  font-size: 12px;
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  color: var(--muted, #9fb0d3);
  background: var(--panel-2, #101727);
  padding: 2px 6px;
  border-radius: 4px;
}

/* ============================================================================
   Estado Vazio
   ============================================================================ */

.emptyState {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
}

.emptyIcon {
  font-size: 48px;
  margin-bottom: 12px;
  opacity: 0.5;
}

.emptyText {
  margin: 0;
  font-size: 14px;
  color: var(--muted, #9fb0d3);
  line-height: 1.6;
}

.emptyText strong {
  color: var(--brand, #4ba3ff);
  font-weight: 600;
}

/* ============================================================================
   Responsividade
   ============================================================================ */

@media (max-width: 900px) {
  .sessionState {
    flex-direction: column;
    text-align: center;
  }

  .sessionEmoji {
    font-size: 28px;
  }

  .projectDetail {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }

  .detailLabel {
    min-width: auto;
  }
}
EOF

echo "[ok] ExploreOverview.module.css criado com sucesso"

# ------------------------------------------------------------------------------
# Sumário
# ------------------------------------------------------------------------------
echo ""
echo "========================================="
echo "✅ HU-UI-Explore-Mode-001 implementada"
echo "========================================="
echo "Arquivos criados/modificados:"
echo "  - packages/ui/src/components/explore/ExploreOverview.tsx"
echo "  - packages/ui/src/components/explore/ExploreOverview.module.css"
echo ""
echo "Funcionalidades:"
echo "  ✓ Exibição de estado da sessão (Discovery/Execution/Review/Idle)"
echo "  ✓ Informações do projeto atual (nome, repo, branch, path)"
echo "  ✓ Lista de últimas análises com timestamps relativos"
echo "  ✓ Dados mockados para desenvolvimento"
echo "  ✓ Layout preservado (aba Overview no painel central)"
echo ""
echo "Próximos passos:"
echo "  1. Execute o script de testes: 04_hu_ui_explore_mode_001_test.sh"
echo "  2. Integre com WorkspaceTabs (ver próximo script)"
echo "========================================="
