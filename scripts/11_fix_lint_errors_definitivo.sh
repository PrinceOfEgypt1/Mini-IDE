#!/usr/bin/env bash
# ==============================================================================
# Script: 11_fix_lint_errors_definitivo.sh
# Descrição: Correção DEFINITIVA de todos os erros de lint
# ==============================================================================
# Objetivo:
#   Corrigir os 13 erros de lint restantes com abordagem mais assertiva
#
# Estratégia:
#   1. Usar /* eslint-disable no-undef */ em vez de /* eslint-env browser */
#   2. Remover imports useState e useEffect não usados em ExploreOverview.tsx
#   3. Adicionar comentário explicativo para revisores de código
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/
# ==============================================================================

set -euo pipefail

echo "[info] Iniciando correção DEFINITIVA de erros de lint..."

# ------------------------------------------------------------------------------
# 1. DiscoveryNotes.tsx - Usar eslint-disable no-undef
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/discovery/DiscoveryNotes.tsx << 'EOF'
/**
 * @file DiscoveryNotes.tsx
 * @description Discovery Notes evoluídas - Editor assistido com persistência local
 * @module @mini-ide/ui/components/discovery
 */

import { useState, useEffect, useCallback } from 'react';
import styles from './DiscoveryNotes.module.css';

/**
 * Estrutura das notas de descoberta
 */
export interface DiscoveryNotesData {
  intention: string;
  requirements: string;
  constraints: string;
  examples: string;
}

/**
 * Chave de persistência no localStorage
 */
const STORAGE_KEY = 'mini-ide:discovery-notes:v1';

/**
 * Valor padrão para notas vazias
 */
const DEFAULT_NOTES: DiscoveryNotesData = {
  intention: '',
  requirements: '',
  constraints: '',
  examples: '',
};

/**
 * Carrega notas do localStorage com tratamento de erros
 */
function loadNotesFromStorage(): DiscoveryNotesData {
  try {
    // eslint-disable-next-line no-undef
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return DEFAULT_NOTES;
    
    const parsed = JSON.parse(stored) as DiscoveryNotesData;
    return {
      intention: parsed.intention || '',
      requirements: parsed.requirements || '',
      constraints: parsed.constraints || '',
      examples: parsed.examples || '',
    };
  } catch (error) {
    console.warn('[DiscoveryNotes] Erro ao carregar do localStorage:', error);
    return DEFAULT_NOTES;
  }
}

/**
 * Salva notas no localStorage com tratamento de erros
 */
function saveNotesToStorage(notes: DiscoveryNotesData): void {
  try {
    // eslint-disable-next-line no-undef
    localStorage.setItem(STORAGE_KEY, JSON.stringify(notes));
  } catch (error) {
    console.error('[DiscoveryNotes] Erro ao salvar no localStorage:', error);
  }
}

/**
 * Componente DiscoveryNotes - Painel direito da UI Explore
 * 
 * Funcionalidades:
 * - Edição em tempo real de 4 campos (Intenção, Requisitos, Restrições, Exemplos)
 * - Persistência automática em localStorage
 * - Recuperação de notas ao recarregar página
 * - Tratamento de erros de storage
 * 
 * Layout:
 * - Permanece no painel direito (~360px) conforme wireframe
 * - Respeita estrutura de 3 colunas
 */
export function DiscoveryNotes() {
  const [notes, setNotes] = useState<DiscoveryNotesData>(DEFAULT_NOTES);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);

  // Carrega notas do localStorage na montagem
  useEffect(() => {
    const loaded = loadNotesFromStorage();
    setNotes(loaded);
  }, []);

  // Salva notas automaticamente quando mudam (debounce implícito via useEffect)
  useEffect(() => {
    if (lastSaved !== null) {
      saveNotesToStorage(notes);
    }
  }, [notes, lastSaved]);

  /**
   * Handler genérico para atualização de campo
   */
  const handleFieldChange = useCallback((field: keyof DiscoveryNotesData, value: string) => {
    setNotes((prev) => ({
      ...prev,
      [field]: value,
    }));
    setLastSaved(new Date());
  }, []);

  return (
    <div className={styles.discoveryNotes}>
      <div className={styles.header}>
        <h3 className={styles.title}>Discovery Notes</h3>
        <p className={styles.subtitle}>
          Coleta automática do que surge no chat (intenção, requisitos, restrições, exemplos).
        </p>
      </div>

      <div className={styles.notesContainer}>
        {/* Campo: Intenção */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Intenção</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.intention}
            onChange={(e) => handleFieldChange('intention', e.target.value)}
            placeholder="Descreva a intenção principal do que você está explorando..."
            rows={4}
            aria-label="Campo de intenção"
          />
        </div>

        {/* Campo: Requisitos */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Requisitos</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.requirements}
            onChange={(e) => handleFieldChange('requirements', e.target.value)}
            placeholder="Liste requisitos funcionais e não funcionais..."
            rows={4}
            aria-label="Campo de requisitos"
          />
        </div>

        {/* Campo: Restrições */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Restrições</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.constraints}
            onChange={(e) => handleFieldChange('constraints', e.target.value)}
            placeholder="Descreva limitações, bloqueios ou restrições técnicas..."
            rows={4}
            aria-label="Campo de restrições"
          />
        </div>

        {/* Campo: Exemplos & Referências */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Exemplos & Referências</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.examples}
            onChange={(e) => handleFieldChange('examples', e.target.value)}
            placeholder="Adicione links, exemplos de código, referências externas..."
            rows={4}
            aria-label="Campo de exemplos e referências"
          />
        </div>
      </div>

      {lastSaved && (
        <div className={styles.footer}>
          <span className={styles.savedIndicator}>
            ✓ Salvo automaticamente às {lastSaved.toLocaleTimeString()}
          </span>
        </div>
      )}
    </div>
  );
}
EOF

echo "[ok] DiscoveryNotes.tsx corrigido"

# ------------------------------------------------------------------------------
# 2. DiscoveryNotes.test.tsx - Adicionar eslint-disable inline
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/discovery/DiscoveryNotes.test.tsx << 'EOF'
/**
 * @file DiscoveryNotes.test.tsx
 * @description Testes para o componente DiscoveryNotes evoluído
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { DiscoveryNotes } from './DiscoveryNotes';

describe('DiscoveryNotes', () => {
  const STORAGE_KEY = 'mini-ide:discovery-notes:v1';

  beforeEach(() => {
    // eslint-disable-next-line no-undef
    localStorage.clear();
    vi.clearAllMocks();
  });

  afterEach(() => {
    // eslint-disable-next-line no-undef
    localStorage.clear();
  });

  describe('Renderização inicial', () => {
    it('deve renderizar o componente com estrutura correta', () => {
      render(<DiscoveryNotes />);

      expect(screen.getByText('Discovery Notes')).toBeInTheDocument();
      expect(screen.getByText(/Coleta automática do que surge no chat/)).toBeInTheDocument();
    });

    it('deve renderizar os 4 campos de notas', () => {
      render(<DiscoveryNotes />);

      expect(screen.getByText('Intenção')).toBeInTheDocument();
      expect(screen.getByText('Requisitos')).toBeInTheDocument();
      expect(screen.getByText('Restrições')).toBeInTheDocument();
      expect(screen.getByText('Exemplos & Referências')).toBeInTheDocument();
    });

    it('deve renderizar textareas editáveis para cada campo', () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      const requirementsField = screen.getByLabelText('Campo de requisitos');
      const constraintsField = screen.getByLabelText('Campo de restrições');
      const examplesField = screen.getByLabelText('Campo de exemplos e referências');

      expect(intentionField).toBeInTheDocument();
      expect(requirementsField).toBeInTheDocument();
      expect(constraintsField).toBeInTheDocument();
      expect(examplesField).toBeInTheDocument();

      // Verifica que são textareas
      expect(intentionField.tagName).toBe('TEXTAREA');
      expect(requirementsField.tagName).toBe('TEXTAREA');
      expect(constraintsField.tagName).toBe('TEXTAREA');
      expect(examplesField.tagName).toBe('TEXTAREA');
    });

    it('deve iniciar com campos vazios quando não há dados no localStorage', () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção') as HTMLTextAreaElement;
      const requirementsField = screen.getByLabelText('Campo de requisitos') as HTMLTextAreaElement;
      const constraintsField = screen.getByLabelText('Campo de restrições') as HTMLTextAreaElement;
      const examplesField = screen.getByLabelText('Campo de exemplos e referências') as HTMLTextAreaElement;

      expect(intentionField.value).toBe('');
      expect(requirementsField.value).toBe('');
      expect(constraintsField.value).toBe('');
      expect(examplesField.value).toBe('');
    });
  });

  describe('Edição de campos', () => {
    it('deve permitir edição do campo Intenção', async () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção') as HTMLTextAreaElement;
      const testText = 'Criar um sistema de análise de código';

      fireEvent.change(intentionField, { target: { value: testText } });

      await waitFor(() => {
        expect(intentionField.value).toBe(testText);
      });
    });

    it('deve permitir edição do campo Requisitos', async () => {
      render(<DiscoveryNotes />);

      const requirementsField = screen.getByLabelText('Campo de requisitos') as HTMLTextAreaElement;
      const testText = 'Deve suportar TypeScript\nDeve ter cobertura > 80%';

      fireEvent.change(requirementsField, { target: { value: testText } });

      await waitFor(() => {
        expect(requirementsField.value).toBe(testText);
      });
    });

    it('deve permitir edição do campo Restrições', async () => {
      render(<DiscoveryNotes />);

      const constraintsField = screen.getByLabelText('Campo de restrições') as HTMLTextAreaElement;
      const testText = 'Não pode quebrar o layout de 3 colunas';

      fireEvent.change(constraintsField, { target: { value: testText } });

      await waitFor(() => {
        expect(constraintsField.value).toBe(testText);
      });
    });

    it('deve permitir edição do campo Exemplos & Referências', async () => {
      render(<DiscoveryNotes />);

      const examplesField = screen.getByLabelText('Campo de exemplos e referências') as HTMLTextAreaElement;
      const testText = 'https://exemplo.com/referencia';

      fireEvent.change(examplesField, { target: { value: testText } });

      await waitFor(() => {
        expect(examplesField.value).toBe(testText);
      });
    });

    it('deve atualizar o indicador de salvamento após edição', async () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      fireEvent.change(intentionField, { target: { value: 'Teste' } });

      await waitFor(() => {
        expect(screen.getByText(/Salvo automaticamente às/)).toBeInTheDocument();
      });
    });
  });

  describe('Persistência em localStorage', () => {
    it('deve salvar dados no localStorage após edição', async () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      const testText = 'Intenção de teste';

      fireEvent.change(intentionField, { target: { value: testText } });

      await waitFor(() => {
        // eslint-disable-next-line no-undef
        const stored = localStorage.getItem(STORAGE_KEY);
        expect(stored).not.toBeNull();

        if (stored) {
          const parsed = JSON.parse(stored);
          expect(parsed.intention).toBe(testText);
        }
      });
    });

    it('deve recuperar dados do localStorage ao montar o componente', () => {
      const testData = {
        intention: 'Intenção salva',
        requirements: 'Requisitos salvos',
        constraints: 'Restrições salvas',
        examples: 'Exemplos salvos',
      };

      // eslint-disable-next-line no-undef
      localStorage.setItem(STORAGE_KEY, JSON.stringify(testData));

      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção') as HTMLTextAreaElement;
      const requirementsField = screen.getByLabelText('Campo de requisitos') as HTMLTextAreaElement;
      const constraintsField = screen.getByLabelText('Campo de restrições') as HTMLTextAreaElement;
      const examplesField = screen.getByLabelText('Campo de exemplos e referências') as HTMLTextAreaElement;

      expect(intentionField.value).toBe(testData.intention);
      expect(requirementsField.value).toBe(testData.requirements);
      expect(constraintsField.value).toBe(testData.constraints);
      expect(examplesField.value).toBe(testData.examples);
    });

    it('deve manter dados após refresh (simulado)', () => {
      const { unmount } = render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      fireEvent.change(intentionField, { target: { value: 'Teste persistência' } });

      // Simula unmount (refresh)
      unmount();

      // Simula novo mount
      render(<DiscoveryNotes />);

      const newIntentionField = screen.getByLabelText('Campo de intenção') as HTMLTextAreaElement;
      expect(newIntentionField.value).toBe('Teste persistência');
    });

    it('deve lidar com localStorage indisponível graciosamente', () => {
      // eslint-disable-next-line no-undef
      const originalSetItem = Storage.prototype.setItem;
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      // eslint-disable-next-line no-undef
      Storage.prototype.setItem = vi.fn(() => {
        throw new Error('QuotaExceededError');
      });

      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      fireEvent.change(intentionField, { target: { value: 'Teste' } });

      // Deve capturar erro mas não quebrar a aplicação
      expect(consoleErrorSpy).toHaveBeenCalled();

      // Restaura
      // eslint-disable-next-line no-undef
      Storage.prototype.setItem = originalSetItem;
      consoleErrorSpy.mockRestore();
    });

    it('deve lidar com JSON inválido no localStorage', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

      // eslint-disable-next-line no-undef
      localStorage.setItem(STORAGE_KEY, 'JSON inválido{{{');

      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção') as HTMLTextAreaElement;

      // Deve usar valores padrão
      expect(intentionField.value).toBe('');
      expect(consoleWarnSpy).toHaveBeenCalled();

      consoleWarnSpy.mockRestore();
    });
  });

  describe('Acessibilidade', () => {
    it('deve ter aria-labels apropriados em todos os campos', () => {
      render(<DiscoveryNotes />);

      expect(screen.getByLabelText('Campo de intenção')).toBeInTheDocument();
      expect(screen.getByLabelText('Campo de requisitos')).toBeInTheDocument();
      expect(screen.getByLabelText('Campo de restrições')).toBeInTheDocument();
      expect(screen.getByLabelText('Campo de exemplos e referências')).toBeInTheDocument();
    });

    it('deve ter placeholders informativos', () => {
      render(<DiscoveryNotes />);

      expect(screen.getByPlaceholderText(/Descreva a intenção principal/)).toBeInTheDocument();
      expect(screen.getByPlaceholderText(/Liste requisitos funcionais/)).toBeInTheDocument();
      expect(screen.getByPlaceholderText(/Descreva limitações/)).toBeInTheDocument();
      expect(screen.getByPlaceholderText(/Adicione links/)).toBeInTheDocument();
    });
  });

  describe('Integração', () => {
    it('deve permitir edição sequencial de múltiplos campos', async () => {
      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      const requirementsField = screen.getByLabelText('Campo de requisitos');
      const constraintsField = screen.getByLabelText('Campo de restrições');

      fireEvent.change(intentionField, { target: { value: 'Intenção 1' } });
      fireEvent.change(requirementsField, { target: { value: 'Requisito 1' } });
      fireEvent.change(constraintsField, { target: { value: 'Restrição 1' } });

      await waitFor(() => {
        // eslint-disable-next-line no-undef
        const stored = localStorage.getItem(STORAGE_KEY);
        expect(stored).not.toBeNull();

        if (stored) {
          const parsed = JSON.parse(stored);
          expect(parsed.intention).toBe('Intenção 1');
          expect(parsed.requirements).toBe('Requisito 1');
          expect(parsed.constraints).toBe('Restrição 1');
        }
      });
    });
  });
});
EOF

echo "[ok] DiscoveryNotes.test.tsx corrigido"

# ------------------------------------------------------------------------------
# 3. ExploreOverview.tsx - Remover imports não usados
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreOverview.tsx << 'EOF'
/**
 * @file ExploreOverview.tsx
 * @description Aba Overview evoluída com estado da sessão de exploração
 * @module @mini-ide/ui/components/explore
 */

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

echo "[ok] ExploreOverview.tsx corrigido (imports removidos)"

# ------------------------------------------------------------------------------
# Sumário
# ------------------------------------------------------------------------------
echo ""
echo "========================================="
echo "✅ Correção DEFINITIVA de lint concluída"
echo "========================================="
echo "Arquivos corrigidos:"
echo "  ✓ DiscoveryNotes.tsx (eslint-disable inline em localStorage)"
echo "  ✓ DiscoveryNotes.test.tsx (eslint-disable inline em localStorage)"
echo "  ✓ ExploreOverview.tsx (removido useState e useEffect não usados)"
echo ""
echo "Erros corrigidos: 13"
echo "  ✓ 11 erros de localStorage"
echo "  ✓ 2 erros de imports não usados (useState, useEffect)"
echo ""
echo "Próximos passos:"
echo "  1. Execute: pnpm --filter @mini-ide/ui lint"
echo "  2. Resultado esperado: ✨ 0 errors, 0 warnings"
echo "  3. Execute: pnpm --filter @mini-ide/ui test"
echo "  4. Execute: pnpm --filter @mini-ide/ui typecheck"
echo "  5. Execute: pnpm --filter @mini-ide/ui build"
echo "========================================="
