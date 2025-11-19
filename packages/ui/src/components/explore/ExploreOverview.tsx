/**
 * @file ExploreOverview.tsx
 * @description Aba Overview evoluída com estado da sessão de exploração
 * @module @mini-ide/ui/components/explore
 */

import styles from './ExploreOverview.module.css';

/**
 * Estados possíveis da sessão de exploração
 */
export type SessionState = 'Discovery' | 'Execution' | 'Review' | 'Idle';

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
                  <span className={styles.metric}>↓ {analysis.inputLength} chars</span>
                  <span className={styles.metric}>↑ {analysis.outputLength} chars</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
