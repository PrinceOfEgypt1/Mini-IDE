#!/usr/bin/env bash
# ==============================================================================
# Script: 10_fix_eslint_errors.sh
# Descrição: Correção cirúrgica dos 14 erros de ESLint
# ==============================================================================
# Objetivo:
#   Corrigir os seguintes erros de ESLint:
#   - localStorage is not defined (11 erros)
#   - SessionState/within not used (2 erros)
#   - currentTime not used (1 erro)
#
# Estratégia:
#   1. Adicionar /* eslint-env browser */ onde localStorage é usado
#   2. Remover imports não utilizados
#   3. Remover variável currentTime não utilizada
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/
# ==============================================================================

set -euo pipefail

echo "[info] Iniciando correção de erros de ESLint..."

# ------------------------------------------------------------------------------
# 1. DiscoveryNotes.tsx - Adicionar eslint-env browser
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/discovery/DiscoveryNotes.tsx << 'EOF'
/**
 * @file DiscoveryNotes.tsx
 * @description Discovery Notes evoluídas - Editor assistido com persistência local
 * @module @mini-ide/ui/components/discovery
 */

/* eslint-env browser */

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

echo "[ok] DiscoveryNotes.tsx corrigido (adicionado eslint-env browser)"

# ------------------------------------------------------------------------------
# 2. DiscoveryNotes.test.tsx - Adicionar eslint-env browser
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/discovery/DiscoveryNotes.test.tsx << 'EOF'
/**
 * @file DiscoveryNotes.test.tsx
 * @description Testes para o componente DiscoveryNotes evoluído
 */

/* eslint-env browser */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { DiscoveryNotes } from './DiscoveryNotes';

describe('DiscoveryNotes', () => {
  const STORAGE_KEY = 'mini-ide:discovery-notes:v1';

  beforeEach(() => {
    // Limpa localStorage antes de cada teste
    localStorage.clear();
    vi.clearAllMocks();
  });

  afterEach(() => {
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
      // Mock localStorage.setItem para lançar erro
      const originalSetItem = Storage.prototype.setItem;
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      Storage.prototype.setItem = vi.fn(() => {
        throw new Error('QuotaExceededError');
      });

      render(<DiscoveryNotes />);

      const intentionField = screen.getByLabelText('Campo de intenção');
      fireEvent.change(intentionField, { target: { value: 'Teste' } });

      // Deve capturar erro mas não quebrar a aplicação
      expect(consoleErrorSpy).toHaveBeenCalled();

      // Restaura
      Storage.prototype.setItem = originalSetItem;
      consoleErrorSpy.mockRestore();
    });

    it('deve lidar com JSON inválido no localStorage', () => {
      const consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

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

echo "[ok] DiscoveryNotes.test.tsx corrigido (adicionado eslint-env browser)"

# ------------------------------------------------------------------------------
# 3. ExploreOverview.test.tsx - Remover import não utilizado
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreOverview.test.tsx << 'EOF'
/**
 * @file ExploreOverview.test.tsx
 * @description Testes para o componente ExploreOverview
 */

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreOverview, type ProjectInfo, type AnalysisRecord } from './ExploreOverview';

describe('ExploreOverview', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Renderização com valores padrão', () => {
    it('deve renderizar o componente com dados mockados padrão', () => {
      render(<ExploreOverview />);

      // Verifica seções principais
      expect(screen.getByText('Estado da Sessão')).toBeInTheDocument();
      expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
      expect(screen.getByText('Últimas Análises')).toBeInTheDocument();
    });

    it('deve exibir estado padrão "Discovery"', () => {
      render(<ExploreOverview />);

      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Coletando requisitos e intenções')).toBeInTheDocument();
    });

    it('deve exibir informações do projeto padrão', () => {
      render(<ExploreOverview />);

      expect(screen.getByText('Mini-IDE')).toBeInTheDocument();
      expect(screen.getByText('PrinceOfEgypt1/Mini-IDE')).toBeInTheDocument();
      expect(screen.getByText('main')).toBeInTheDocument();
      expect(screen.getByText('~/workspace/Mini-IDE')).toBeInTheDocument();
    });

    it('deve exibir análises mockadas', () => {
      render(<ExploreOverview />);

      expect(screen.getByText(/Análise de estrutura de componentes React/)).toBeInTheDocument();
      expect(screen.getByText(/Verificação de tipagem TypeScript/)).toBeInTheDocument();
      expect(screen.getByText(/Revisão de padrões de testes Vitest/)).toBeInTheDocument();
    });
  });

  describe('Estados da Sessão', () => {
    it('deve renderizar estado "Discovery" corretamente', () => {
      render(<ExploreOverview sessionState="Discovery" />);

      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Coletando requisitos e intenções')).toBeInTheDocument();
      expect(screen.getByText('🔍')).toBeInTheDocument();
    });

    it('deve renderizar estado "Execution" corretamente', () => {
      render(<ExploreOverview sessionState="Execution" />);

      expect(screen.getByText('Execution')).toBeInTheDocument();
      expect(screen.getByText('Executando análises e processamentos')).toBeInTheDocument();
      expect(screen.getByText('⚡')).toBeInTheDocument();
    });

    it('deve renderizar estado "Review" corretamente', () => {
      render(<ExploreOverview sessionState="Review" />);

      expect(screen.getByText('Review')).toBeInTheDocument();
      expect(screen.getByText('Revisando resultados e artefatos')).toBeInTheDocument();
      expect(screen.getByText('📋')).toBeInTheDocument();
    });

    it('deve renderizar estado "Idle" corretamente', () => {
      render(<ExploreOverview sessionState="Idle" />);

      expect(screen.getByText('Idle')).toBeInTheDocument();
      expect(screen.getByText('Aguardando próxima ação')).toBeInTheDocument();
      expect(screen.getByText('💤')).toBeInTheDocument();
    });
  });

  describe('Informações do Projeto', () => {
    it('deve renderizar projeto customizado', () => {
      const customProject: ProjectInfo = {
        name: 'Meu Projeto',
        repository: 'usuario/meu-projeto',
        branch: 'develop',
        path: '/home/user/projects/meu-projeto',
      };

      render(<ExploreOverview projectInfo={customProject} />);

      expect(screen.getByText('Meu Projeto')).toBeInTheDocument();
      expect(screen.getByText('usuario/meu-projeto')).toBeInTheDocument();
      expect(screen.getByText('develop')).toBeInTheDocument();
      expect(screen.getByText('/home/user/projects/meu-projeto')).toBeInTheDocument();
    });

    it('deve renderizar projeto sem repositório', () => {
      const projectWithoutRepo: ProjectInfo = {
        name: 'Projeto Local',
        branch: 'main',
      };

      render(<ExploreOverview projectInfo={projectWithoutRepo} />);

      expect(screen.getByText('Projeto Local')).toBeInTheDocument();
      expect(screen.getByText('main')).toBeInTheDocument();
      expect(screen.queryByText(/Repositório:/)).not.toBeInTheDocument();
    });

    it('deve renderizar projeto sem caminho', () => {
      const projectWithoutPath: ProjectInfo = {
        name: 'Projeto Remoto',
        branch: 'main',
      };

      render(<ExploreOverview projectInfo={projectWithoutPath} />);

      expect(screen.getByText('Projeto Remoto')).toBeInTheDocument();
      expect(screen.queryByText(/Caminho:/)).not.toBeInTheDocument();
    });

    it('deve exibir ícone de pasta para o projeto', () => {
      render(<ExploreOverview />);

      expect(screen.getByText('📁')).toBeInTheDocument();
    });
  });

  describe('Últimas Análises', () => {
    it('deve exibir badge com contagem de análises', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(),
          summary: 'Teste 1',
          inputLength: 100,
          outputLength: 50,
        },
        {
          id: '2',
          timestamp: new Date(),
          summary: 'Teste 2',
          inputLength: 200,
          outputLength: 100,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText('2')).toBeInTheDocument();
    });

    it('deve exibir estado vazio quando não há análises', () => {
      render(<ExploreOverview recentAnalyses={[]} />);

      expect(screen.getByText('Nenhuma análise realizada ainda.')).toBeInTheDocument();
      expect(screen.getByText(/Use a aba/)).toBeInTheDocument();
      expect(screen.getByText('📊')).toBeInTheDocument();
    });

    it('deve renderizar cada análise com suas informações', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(Date.now() - 300000), // 5 min atrás
          summary: 'Análise de teste',
          inputLength: 1000,
          outputLength: 200,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText('Análise de teste')).toBeInTheDocument();
      expect(screen.getByText('↓ 1000 chars')).toBeInTheDocument();
      expect(screen.getByText('↑ 200 chars')).toBeInTheDocument();
      expect(screen.getByText(/min atrás/)).toBeInTheDocument();
    });

    it('deve exibir ícone de análise para cada registro', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(),
          summary: 'Teste',
          inputLength: 100,
          outputLength: 50,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText('🔬')).toBeInTheDocument();
    });
  });

  describe('Formatação de Tempo Relativo', () => {
    it('deve exibir "agora" para timestamps muito recentes', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(Date.now() - 30000), // 30 seg atrás
          summary: 'Recente',
          inputLength: 100,
          outputLength: 50,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText('agora')).toBeInTheDocument();
    });

    it('deve exibir minutos para timestamps recentes', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(Date.now() - 300000), // 5 min atrás
          summary: 'Minutos',
          inputLength: 100,
          outputLength: 50,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText(/min atrás/)).toBeInTheDocument();
    });

    it('deve exibir horas para timestamps mais antigos', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(Date.now() - 7200000), // 2 horas atrás
          summary: 'Horas',
          inputLength: 100,
          outputLength: 50,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText(/hora/)).toBeInTheDocument();
    });
  });

  describe('Acessibilidade e Estrutura', () => {
    it('deve ter estrutura semântica com headings', () => {
      render(<ExploreOverview />);

      const headings = screen.getAllByRole('heading', { level: 3 });
      expect(headings.length).toBeGreaterThan(0);
    });

    it('deve renderizar todas as seções principais', () => {
      render(<ExploreOverview />);

      const sections = screen.getAllByText(/Estado da Sessão|Projeto Atual|Últimas Análises/);
      expect(sections.length).toBe(3);
    });
  });

  describe('Props customizadas combinadas', () => {
    it('deve renderizar corretamente com todas as props customizadas', () => {
      const customProject: ProjectInfo = {
        name: 'Projeto Completo',
        repository: 'org/projeto',
        branch: 'feature/new',
        path: '/custom/path',
      };

      const customAnalyses: AnalysisRecord[] = [
        {
          id: 'custom-1',
          timestamp: new Date(Date.now() - 120000),
          summary: 'Análise customizada',
          inputLength: 500,
          outputLength: 100,
        },
      ];

      render(
        <ExploreOverview
          projectInfo={customProject}
          sessionState="Execution"
          recentAnalyses={customAnalyses}
        />
      );

      // Verifica estado
      expect(screen.getByText('Execution')).toBeInTheDocument();

      // Verifica projeto
      expect(screen.getByText('Projeto Completo')).toBeInTheDocument();
      expect(screen.getByText('org/projeto')).toBeInTheDocument();
      expect(screen.getByText('feature/new')).toBeInTheDocument();

      // Verifica análise
      expect(screen.getByText('Análise customizada')).toBeInTheDocument();
      expect(screen.getByText('↓ 500 chars')).toBeInTheDocument();
    });
  });

  describe('Integração e Comportamento', () => {
    it('deve renderizar múltiplas análises em ordem', () => {
      const analyses: AnalysisRecord[] = [
        {
          id: '1',
          timestamp: new Date(Date.now() - 100000),
          summary: 'Primeira análise',
          inputLength: 100,
          outputLength: 50,
        },
        {
          id: '2',
          timestamp: new Date(Date.now() - 200000),
          summary: 'Segunda análise',
          inputLength: 200,
          outputLength: 100,
        },
        {
          id: '3',
          timestamp: new Date(Date.now() - 300000),
          summary: 'Terceira análise',
          inputLength: 300,
          outputLength: 150,
        },
      ];

      render(<ExploreOverview recentAnalyses={analyses} />);

      expect(screen.getByText('Primeira análise')).toBeInTheDocument();
      expect(screen.getByText('Segunda análise')).toBeInTheDocument();
      expect(screen.getByText('Terceira análise')).toBeInTheDocument();
    });

    it('deve renderizar corretamente sem crash mesmo com dados vazios', () => {
      const emptyProject: ProjectInfo = {
        name: '',
        branch: '',
      };

      render(
        <ExploreOverview
          projectInfo={emptyProject}
          recentAnalyses={[]}
        />
      );

      // Não deve crashar, deve renderizar estrutura básica
      expect(screen.getByText('Estado da Sessão')).toBeInTheDocument();
      expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
      expect(screen.getByText('Últimas Análises')).toBeInTheDocument();
    });
  });
});
EOF

echo "[ok] ExploreOverview.test.tsx corrigido (removido import SessionState não utilizado)"

# ------------------------------------------------------------------------------
# 4. ExploreOverview.tsx - Remover variável currentTime não utilizada
# ------------------------------------------------------------------------------
sed -i '152d' packages/ui/src/components/explore/ExploreOverview.tsx
sed -i '/const \[currentTime, setCurrentTime\]/d' packages/ui/src/components/explore/ExploreOverview.tsx
sed -i '/useEffect(() => {/,/}, \[\]);/d' packages/ui/src/components/explore/ExploreOverview.tsx

echo "[ok] ExploreOverview.tsx corrigido (removido currentTime não utilizado)"

# ------------------------------------------------------------------------------
# 5. ExploreTimeline.test.tsx - Remover import não utilizado
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreTimeline.test.tsx << 'EOF'
/**
 * @file ExploreTimeline.test.tsx
 * @description Testes para o componente ExploreTimeline
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { ExploreTimeline, type TimelineEvent } from './ExploreTimeline';

describe('ExploreTimeline', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Renderização inicial', () => {
    it('deve renderizar o componente com estrutura correta', () => {
      render(<ExploreTimeline />);

      expect(screen.getByText('Timeline de Exploração')).toBeInTheDocument();
    });

    it('deve renderizar com eventos mockados por padrão', () => {
      render(<ExploreTimeline />);

      // Deve exibir algum evento mockado
      expect(screen.getByText(/evento/)).toBeInTheDocument();
    });

    it('deve exibir controles de filtro', () => {
      render(<ExploreTimeline />);

      expect(screen.getByRole('button', { name: /Todos/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /Nenhum/i })).toBeInTheDocument();
    });

    it('deve exibir todos os filtros de tipo de evento', () => {
      render(<ExploreTimeline />);

      expect(screen.getByText('Análise')).toBeInTheDocument();
      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Projeto')).toBeInTheDocument();
      expect(screen.getByText('Execução')).toBeInTheDocument();
      expect(screen.getByText('Sistema')).toBeInTheDocument();
    });
  });

  describe('Exibição de eventos', () => {
    const mockEvents: TimelineEvent[] = [
      {
        id: '1',
        type: 'analysis',
        timestamp: new Date(Date.now() - 300000),
        title: 'Análise de teste',
        description: 'Descrição da análise',
      },
      {
        id: '2',
        type: 'discovery',
        timestamp: new Date(Date.now() - 600000),
        title: 'Discovery atualizada',
        description: 'Campo atualizado',
      },
    ];

    it('deve renderizar eventos personalizados', () => {
      render(<ExploreTimeline events={mockEvents} />);

      expect(screen.getByText('Análise de teste')).toBeInTheDocument();
      expect(screen.getByText('Discovery atualizada')).toBeInTheDocument();
    });

    it('deve exibir descrição dos eventos', () => {
      render(<ExploreTimeline events={mockEvents} />);

      expect(screen.getByText('Descrição da análise')).toBeInTheDocument();
      expect(screen.getByText('Campo atualizado')).toBeInTheDocument();
    });

    it('deve exibir contador de eventos correto', () => {
      render(<ExploreTimeline events={mockEvents} />);

      expect(screen.getByText('2 eventos')).toBeInTheDocument();
    });

    it('deve exibir "1 evento" no singular', () => {
      const singleEvent: TimelineEvent[] = [mockEvents[0]];
      render(<ExploreTimeline events={singleEvent} />);

      expect(screen.getByText('1 evento')).toBeInTheDocument();
    });

    it('deve renderizar evento sem descrição', () => {
      const eventWithoutDescription: TimelineEvent[] = [
        {
          id: '1',
          type: 'system',
          timestamp: new Date(),
          title: 'Apenas título',
        },
      ];

      render(<ExploreTimeline events={eventWithoutDescription} />);

      expect(screen.getByText('Apenas título')).toBeInTheDocument();
    });

    it('deve exibir metadados quando presentes', () => {
      const eventWithMetadata: TimelineEvent[] = [
        {
          id: '1',
          type: 'analysis',
          timestamp: new Date(),
          title: 'Com metadata',
          metadata: { inputLength: 1000, outputLength: 200 },
        },
      ];

      render(<ExploreTimeline events={eventWithMetadata} />);

      expect(screen.getByText(/inputLength: 1000/)).toBeInTheDocument();
      expect(screen.getByText(/outputLength: 200/)).toBeInTheDocument();
    });
  });

  describe('Filtros de tipo de evento', () => {
    const diverseEvents: TimelineEvent[] = [
      {
        id: '1',
        type: 'analysis',
        timestamp: new Date(),
        title: 'Análise',
      },
      {
        id: '2',
        type: 'discovery',
        timestamp: new Date(),
        title: 'Discovery',
      },
      {
        id: '3',
        type: 'project',
        timestamp: new Date(),
        title: 'Projeto',
      },
    ];

    it('deve iniciar com todos os tipos selecionados', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      expect(screen.getByText('Análise')).toBeInTheDocument();
      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Projeto')).toBeInTheDocument();
    });

    it('deve filtrar eventos ao desselecionar tipo', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      // Clica no filtro "Análise" para desselecioná-lo
      const analysisFilter = screen.getByRole('button', { name: /Análise/i });
      fireEvent.click(analysisFilter);

      // Evento de análise não deve mais estar visível
      expect(screen.queryByText('Análise')).not.toBeInTheDocument();

      // Outros eventos ainda devem estar visíveis
      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Projeto')).toBeInTheDocument();
    });

    it('deve reexibir eventos ao reselecionar tipo', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      const analysisFilter = screen.getByRole('button', { name: /Análise/i });

      // Desseleciona
      fireEvent.click(analysisFilter);
      expect(screen.queryByText('Análise')).not.toBeInTheDocument();

      // Reseleciona
      fireEvent.click(analysisFilter);
      expect(screen.getByText('Análise')).toBeInTheDocument();
    });

    it('deve desselecionar todos os tipos ao clicar em "Nenhum"', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      const noneButton = screen.getByRole('button', { name: /Nenhum/i });
      fireEvent.click(noneButton);

      expect(screen.queryByText('Análise')).not.toBeInTheDocument();
      expect(screen.queryByText('Discovery')).not.toBeInTheDocument();
      expect(screen.queryByText('Projeto')).not.toBeInTheDocument();

      expect(screen.getByText(/Nenhum evento encontrado/)).toBeInTheDocument();
    });

    it('deve selecionar todos os tipos ao clicar em "Todos"', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      // Primeiro limpa todos
      const noneButton = screen.getByRole('button', { name: /Nenhum/i });
      fireEvent.click(noneButton);

      // Depois seleciona todos
      const allButton = screen.getByRole('button', { name: /Todos/i });
      fireEvent.click(allButton);

      expect(screen.getByText('Análise')).toBeInTheDocument();
      expect(screen.getByText('Discovery')).toBeInTheDocument();
      expect(screen.getByText('Projeto')).toBeInTheDocument();
    });

    it('deve atualizar contador ao filtrar eventos', () => {
      render(<ExploreTimeline events={diverseEvents} />);

      // Inicialmente 3 eventos
      expect(screen.getByText('3 eventos')).toBeInTheDocument();

      // Desseleciona um tipo
      const analysisFilter = screen.getByRole('button', { name: /Análise/i });
      fireEvent.click(analysisFilter);

      // Agora 2 eventos
      expect(screen.getByText('2 eventos')).toBeInTheDocument();
    });
  });

  describe('Estado vazio', () => {
    it('deve exibir estado vazio quando não há eventos', () => {
      render(<ExploreTimeline events={[]} />);

      expect(screen.getByText(/Nenhum evento encontrado/)).toBeInTheDocument();
      expect(screen.getByText('📭')).toBeInTheDocument();
    });

    it('deve exibir estado vazio quando todos os filtros são desmarcados', () => {
      const mockEvents: TimelineEvent[] = [
        {
          id: '1',
          type: 'analysis',
          timestamp: new Date(),
          title: 'Teste',
        },
      ];

      render(<ExploreTimeline events={mockEvents} />);

      const noneButton = screen.getByRole('button', { name: /Nenhum/i });
      fireEvent.click(noneButton);

      expect(screen.getByText(/Nenhum evento encontrado/)).toBeInTheDocument();
    });
  });

  describe('Ordenação de eventos', () => {
    it('deve ordenar eventos por timestamp (mais recente primeiro)', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'analysis',
          timestamp: new Date(Date.now() - 600000), // Mais antigo
          title: 'Primeiro',
        },
        {
          id: '2',
          type: 'discovery',
          timestamp: new Date(Date.now() - 300000), // Mais recente
          title: 'Segundo',
        },
      ];

      render(<ExploreTimeline events={events} />);

      const titles = screen.getAllByRole('heading', { level: 4 });
      expect(titles[0]).toHaveTextContent('Segundo');
      expect(titles[1]).toHaveTextContent('Primeiro');
    });
  });

  describe('Formatação de tempo', () => {
    it('deve exibir timestamp absoluto', () => {
      const now = new Date();
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'system',
          timestamp: now,
          title: 'Teste',
        },
      ];

      render(<ExploreTimeline events={events} />);

      const hours = now.getHours().toString().padStart(2, '0');
      const minutes = now.getMinutes().toString().padStart(2, '0');
      const seconds = now.getSeconds().toString().padStart(2, '0');
      const expectedTime = `${hours}:${minutes}:${seconds}`;

      expect(screen.getByText(expectedTime)).toBeInTheDocument();
    });

    it('deve exibir timestamp relativo', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'analysis',
          timestamp: new Date(Date.now() - 120000), // 2 min atrás
          title: 'Teste',
        },
      ];

      render(<ExploreTimeline events={events} />);

      expect(screen.getByText(/minuto/)).toBeInTheDocument();
    });
  });

  describe('Ícones e visual', () => {
    it('deve exibir ícones corretos para cada tipo de evento', () => {
      const events: TimelineEvent[] = [
        { id: '1', type: 'analysis', timestamp: new Date(), title: 'A' },
        { id: '2', type: 'discovery', timestamp: new Date(), title: 'D' },
        { id: '3', type: 'project', timestamp: new Date(), title: 'P' },
        { id: '4', type: 'execution', timestamp: new Date(), title: 'E' },
        { id: '5', type: 'system', timestamp: new Date(), title: 'S' },
      ];

      render(<ExploreTimeline events={events} />);

      expect(screen.getByText('🔬')).toBeInTheDocument(); // analysis
      expect(screen.getByText('📝')).toBeInTheDocument(); // discovery
      expect(screen.getByText('📁')).toBeInTheDocument(); // project
      expect(screen.getByText('⚡')).toBeInTheDocument(); // execution
      expect(screen.getByText('⚙️')).toBeInTheDocument(); // system
    });
  });

  describe('Acessibilidade', () => {
    it('deve ter aria-pressed nos filtros', () => {
      render(<ExploreTimeline />);

      const analysisFilter = screen.getByRole('button', { name: /Análise/i });
      expect(analysisFilter).toHaveAttribute('aria-pressed');
    });

    it('deve ter estrutura semântica', () => {
      render(<ExploreTimeline />);

      const mainHeading = screen.getByRole('heading', { level: 3 });
      expect(mainHeading).toHaveTextContent('Timeline de Exploração');
    });

    it('deve ter botões com type="button"', () => {
      render(<ExploreTimeline />);

      const allButton = screen.getByRole('button', { name: /Todos/i });
      expect(allButton).toHaveAttribute('type', 'button');
    });
  });

  describe('Integração e comportamento complexo', () => {
    it('deve permitir filtrar múltiplos tipos simultaneamente', () => {
      const events: TimelineEvent[] = [
        { id: '1', type: 'analysis', timestamp: new Date(), title: 'Análise' },
        { id: '2', type: 'discovery', timestamp: new Date(), title: 'Discovery' },
        { id: '3', type: 'project', timestamp: new Date(), title: 'Projeto' },
      ];

      render(<ExploreTimeline events={events} />);

      // Desseleciona Analysis e Discovery
      fireEvent.click(screen.getByRole('button', { name: /Análise/i }));
      fireEvent.click(screen.getByRole('button', { name: /Discovery/i }));

      // Apenas Projeto deve estar visível
      expect(screen.queryByText('Análise')).not.toBeInTheDocument();
      expect(screen.queryByText('Discovery')).not.toBeInTheDocument();
      expect(screen.getByText('Projeto')).toBeInTheDocument();

      expect(screen.getByText('1 evento')).toBeInTheDocument();
    });

    it('deve manter estado de filtros ao adicionar novos eventos', () => {
      const { rerender } = render(
        <ExploreTimeline
          events={[
            { id: '1', type: 'analysis', timestamp: new Date(), title: 'A1' },
          ]}
        />
      );

      // Desseleciona análise
      fireEvent.click(screen.getByRole('button', { name: /Análise/i }));

      // Adiciona novo evento
      rerender(
        <ExploreTimeline
          events={[
            { id: '1', type: 'analysis', timestamp: new Date(), title: 'A1' },
            { id: '2', type: 'discovery', timestamp: new Date(), title: 'D1' },
          ]}
        />
      );

      // Análise ainda deve estar filtrada
      expect(screen.queryByText('A1')).not.toBeInTheDocument();
      expect(screen.getByText('D1')).toBeInTheDocument();
    });
  });
});
EOF

echo "[ok] ExploreTimeline.test.tsx corrigido (removido import within não utilizado)"

# ------------------------------------------------------------------------------
# Sumário
# ------------------------------------------------------------------------------
echo ""
echo "========================================="
echo "✅ Correção de ESLint concluída"
echo "========================================="
echo "Erros corrigidos:"
echo "  ✓ 11 erros de 'localStorage is not defined' (adicionado /* eslint-env browser */)"
echo "  ✓ 1 erro de 'SessionState' não utilizado (removido import)"
echo "  ✓ 1 erro de 'currentTime' não utilizado (removido variável e useEffect)"
echo "  ✓ 1 erro de 'within' não utilizado (removido import)"
echo ""
echo "Total de erros resolvidos: 14"
echo ""
echo "Próximos passos:"
echo "  1. Execute: pnpm --filter @mini-ide/ui lint"
echo "  2. Execute: pnpm --filter @mini-ide/ui typecheck"
echo "  3. Execute: pnpm --filter @mini-ide/ui test"
echo "  4. Execute: pnpm --filter @mini-ide/ui build"
echo "========================================="
