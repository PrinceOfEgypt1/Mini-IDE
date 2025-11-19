#!/usr/bin/env bash
################################################################################
# Script: 25_fix_explore_timeline_definitive.sh
# Objetivo: Correção DEFINITIVA do ExploreTimeline
#
# Problemas identificados:
# 1. Props 'events' undefined causando crash
# 2. 13 erros ESLint (any nos testes, vi não definido)
#
# Solução:
# 1. Adicionar defaultProps e validação defensiva
# 2. Corrigir tipos nos testes (remover 'as any')
# 3. Adicionar import do vi no teste
#
# Arquivos afetados:
# - packages/ui/src/components/explore/ExploreTimeline.tsx
# - packages/ui/src/components/explore/ExploreTimeline.test.tsx
# - packages/ui/src/components/WorkspaceTabs.test.tsx
#
# Como reverter:
# - git checkout HEAD -- packages/ui/src/components/explore/ExploreTimeline.{tsx,test.tsx}
# - git checkout HEAD -- packages/ui/src/components/WorkspaceTabs.test.tsx
################################################################################

set -euo pipefail

echo "[info] Iniciando correção DEFINITIVA do ExploreTimeline..."

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages/ui" ]]; then
  echo "[erro] Execute este script a partir da raiz do monorepo Mini-IDE"
  exit 1
fi

COMPONENT_FILE="packages/ui/src/components/explore/ExploreTimeline.tsx"
TEST_FILE="packages/ui/src/components/explore/ExploreTimeline.test.tsx"
WORKSPACE_TABS_TEST="packages/ui/src/components/WorkspaceTabs.test.tsx"

echo "[info] Corrigindo ExploreTimeline.tsx (com defaultProps e validação)..."

cat > "$COMPONENT_FILE" << 'EOF'
import { useMemo, useState } from 'react';
import styles from './ExploreTimeline.module.css';

/**
 * Tipo de evento na timeline
 */
export type TimelineEventType =
  | 'message'
  | 'response'
  | 'plan'
  | 'hu_generation'
  | 'export'
  | 'mode_change'
  | 'project_creation'
  | 'analysis'
  | 'discovery'
  | 'execution'
  | 'system';

/**
 * Categoria de evento para filtragem
 */
export type EventCategory = 'analysis' | 'discovery' | 'project' | 'execution' | 'system';

/**
 * Evento individual na timeline
 */
export interface TimelineEvent {
  /** Identificador único do evento */
  id: string;
  /** Tipo específico do evento */
  type: TimelineEventType;
  /** Categoria do evento para filtragem */
  category: EventCategory;
  /** Título do evento */
  title: string;
  /** Descrição opcional do evento */
  description?: string;
  /** Timestamp do evento */
  timestamp: Date;
  /** Dados adicionais específicos do tipo de evento */
  metadata?: Record<string, unknown>;
}

/**
 * Props do componente ExploreTimeline
 */
export interface ExploreTimelineProps {
  /** Lista de eventos a serem exibidos */
  events?: TimelineEvent[];
  /** Callback quando um evento é selecionado */
  onEventClick?: (event: TimelineEvent) => void;
}

/**
 * Mapa de ícones por categoria
 */
const CATEGORY_ICONS: Record<EventCategory, string> = {
  analysis: '🔬',
  discovery: '📝',
  project: '📁',
  execution: '⚡',
  system: '⚙️',
};

/**
 * Mapa de labels por categoria
 */
const CATEGORY_LABELS: Record<EventCategory, string> = {
  analysis: 'Análise',
  discovery: 'Discovery',
  project: 'Projeto',
  execution: 'Execução',
  system: 'Sistema',
};

/**
 * Componente ExploreTimeline
 *
 * Exibe uma timeline de eventos da exploração com:
 * - Filtragem por categoria
 * - Ordenação cronológica inversa
 * - Estados visuais para cada tipo de evento
 * - Acessibilidade completa
 *
 * Baseado no wireframe MiniIDE-Explore.html
 */
export function ExploreTimeline({ events = [], onEventClick }: ExploreTimelineProps) {
  // Estado de filtros ativos (todas as categorias habilitadas por padrão)
  const [activeFilters, setActiveFilters] = useState<Set<EventCategory>>(
    new Set(['analysis', 'discovery', 'project', 'execution', 'system'])
  );

  /**
   * Alterna filtro de uma categoria
   */
  const toggleFilter = (category: EventCategory) => {
    setActiveFilters((prev) => {
      const next = new Set(prev);
      if (next.has(category)) {
        next.delete(category);
      } else {
        next.add(category);
      }
      return next;
    });
  };

  /**
   * Habilita todos os filtros
   */
  const enableAllFilters = () => {
    setActiveFilters(new Set(['analysis', 'discovery', 'project', 'execution', 'system']));
  };

  /**
   * Desabilita todos os filtros
   */
  const disableAllFilters = () => {
    setActiveFilters(new Set());
  };

  /**
   * Eventos filtrados e ordenados
   */
  const filteredEvents = useMemo(() => {
    return events
      .filter((event) => activeFilters.has(event.category))
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }, [events, activeFilters]);

  /**
   * Formata timestamp para exibição
   */
  const formatTimestamp = (date: Date): string => {
    return new Intl.DateTimeFormat('pt-BR', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    }).format(date);
  };

  /**
   * Formata data completa para datetime attribute
   */
  const formatDateTime = (date: Date): string => {
    return date.toISOString();
  };

  return (
    <div className={styles.exploreTimeline} aria-label="Timeline de exploração">
      {/* Header com título e controles */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>
          <h3 className={styles.title}>Timeline de Exploração</h3>
          <span className={styles.badge}>
            {filteredEvents.length} {filteredEvents.length === 1 ? 'evento' : 'eventos'}
          </span>
        </div>
        <div className={styles.filterControls}>
          <button
            type="button"
            className={styles.filterButton}
            onClick={enableAllFilters}
            aria-label="Habilitar todos os filtros"
          >
            Todos
          </button>
          <button
            type="button"
            className={styles.filterButton}
            onClick={disableAllFilters}
            aria-label="Desabilitar todos os filtros"
          >
            Nenhum
          </button>
        </div>
      </div>

      {/* Filtros por categoria */}
      <div className={styles.filters} role="group" aria-label="Filtros de categoria">
        {(Object.entries(CATEGORY_LABELS) as [EventCategory, string][]).map(([category, label]) => {
          const isActive = activeFilters.has(category);
          return (
            <button
              key={category}
              type="button"
              className={`${styles.filterChip} ${isActive ? styles.filterChipActive : ''}`}
              onClick={() => toggleFilter(category)}
              aria-pressed={isActive}
              aria-label={`Filtrar por ${label}`}
            >
              <span className={styles.filterIcon}>{CATEGORY_ICONS[category]}</span>
              <span className={styles.filterLabel}>{label}</span>
            </button>
          );
        })}
      </div>

      {/* Lista de eventos ou estado vazio */}
      {filteredEvents.length === 0 ? (
        <div className={styles.emptyState}>
          <span className={styles.emptyIcon}>📭</span>
          <p className={styles.emptyText}>
            Nenhum evento encontrado com os filtros atuais.
            <br />
            Ajuste os filtros acima para ver mais eventos.
          </p>
        </div>
      ) : (
        <div className={styles.eventList} role="feed" aria-label="Lista de eventos">
          {filteredEvents.map((event) => (
            <article
              key={event.id}
              className={styles.eventCard}
              onClick={() => onEventClick?.(event)}
              role="article"
              aria-label={`Evento: ${event.title}`}
            >
              <div className={styles.eventIcon}>{CATEGORY_ICONS[event.category]}</div>
              <div className={styles.eventContent}>
                <h4 className={styles.eventTitle}>{event.title}</h4>
                {event.description && <p className={styles.eventDescription}>{event.description}</p>}
                <time className={styles.eventTime} dateTime={formatDateTime(event.timestamp)}>
                  {formatTimestamp(event.timestamp)}
                </time>
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

echo "[ok] ExploreTimeline.tsx corrigido (defaultProps + validação)"

echo "[info] Corrigindo ExploreTimeline.test.tsx (removendo 'as any')..."

cat > "$TEST_FILE" << 'EOF'
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreTimeline, type TimelineEvent } from './ExploreTimeline';

describe('ExploreTimeline', () => {
  const mockEvents: TimelineEvent[] = [
    {
      id: '1',
      type: 'message',
      category: 'analysis',
      title: 'Mensagem do usuário',
      description: 'Usuário enviou mensagem',
      timestamp: new Date('2024-01-15T10:00:00'),
    },
    {
      id: '2',
      type: 'response',
      category: 'discovery',
      title: 'Resposta do agente',
      timestamp: new Date('2024-01-15T10:01:00'),
    },
  ];

  describe('Renderização básica', () => {
    it('deve renderizar sem erros quando vazio', () => {
      render(<ExploreTimeline events={[]} />);
      expect(screen.getByText(/Timeline de Exploração/i)).toBeInTheDocument();
    });

    it('deve renderizar eventos quando fornecidos', () => {
      render(<ExploreTimeline events={mockEvents} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();
      expect(screen.getByText('Resposta do agente')).toBeInTheDocument();
    });
  });

  describe('Formatação de timestamp', () => {
    it('deve formatar timestamps corretamente', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message',
          category: 'analysis',
          title: 'Evento com timestamp',
          timestamp: new Date('2024-01-15T14:30:45'),
        },
      ];
      render(<ExploreTimeline events={events} />);
      expect(screen.getByText(/14:30:45/)).toBeInTheDocument();
    });
  });

  describe('Tipos de eventos comuns', () => {
    it('deve renderizar evento do tipo "message"', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message',
          category: 'analysis',
          title: 'Mensagem de teste',
          timestamp: new Date(),
        },
      ];
      render(<ExploreTimeline events={events} />);
      expect(screen.getByText('Mensagem de teste')).toBeInTheDocument();
    });

    it('deve renderizar evento do tipo "response"', () => {
      const events: TimelineEvent[] = [
        {
          id: '2',
          type: 'response',
          category: 'discovery',
          title: 'Resposta de teste',
          timestamp: new Date(),
        },
      ];
      render(<ExploreTimeline events={events} />);
      expect(screen.getByText('Resposta de teste')).toBeInTheDocument();
    });

    it('deve renderizar evento do tipo "plan"', () => {
      const events: TimelineEvent[] = [
        {
          id: '3',
          type: 'plan',
          category: 'project',
          title: 'Plano de teste',
          timestamp: new Date(),
        },
      ];
      render(<ExploreTimeline events={events} />);
      expect(screen.getByText('Plano de teste')).toBeInTheDocument();
    });
  });

  describe('Ordenação de eventos', () => {
    it('deve exibir eventos em ordem cronológica inversa', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message',
          category: 'analysis',
          title: 'Evento antigo',
          timestamp: new Date('2024-01-15T10:00:00'),
        },
        {
          id: '2',
          type: 'response',
          category: 'discovery',
          title: 'Evento novo',
          timestamp: new Date('2024-01-15T11:00:00'),
        },
      ];
      render(<ExploreTimeline events={events} />);

      const titles = screen.getAllByRole('heading', { level: 4 });
      expect(titles[0]).toHaveTextContent('Evento novo');
      expect(titles[1]).toHaveTextContent('Evento antigo');
    });
  });

  describe('Performance com muitos eventos', () => {
    it('deve renderizar 100+ eventos sem problemas', () => {
      const manyEvents: TimelineEvent[] = Array.from({ length: 150 }, (_, i) => ({
        id: `event-${i}`,
        type: 'message' as const,
        category: 'analysis' as const,
        title: `Evento ${i}`,
        timestamp: new Date(Date.now() + i * 1000),
      }));
      render(<ExploreTimeline events={manyEvents} />);

      expect(screen.getByText('Evento 0')).toBeInTheDocument();
      expect(screen.getByText('Evento 149')).toBeInTheDocument();
    });
  });

  describe('Acessibilidade', () => {
    it('deve ter estrutura semântica adequada', () => {
      render(<ExploreTimeline events={mockEvents} />);

      const timeElements = screen.getAllByRole('time');
      expect(timeElements.length).toBeGreaterThan(0);
    });

    it('deve ter aria-label descritivo no container', () => {
      const { container } = render(<ExploreTimeline events={mockEvents} />);
      const timeline = container.firstChild as HTMLElement;
      expect(timeline).toHaveAttribute('aria-label', 'Timeline de exploração');
    });
  });

  describe('Estados edge-case', () => {
    it('deve lidar com array vazio de eventos', () => {
      render(<ExploreTimeline events={[]} />);
      expect(screen.getByText(/Nenhum evento encontrado/i)).toBeInTheDocument();
    });

    it('deve lidar com eventos sem título', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message',
          category: 'analysis',
          title: '',
          timestamp: new Date(),
        },
      ];
      render(<ExploreTimeline events={events} />);
      expect(screen.queryByText(/Nenhum evento/i)).not.toBeInTheDocument();
    });
  });

  describe('Atualização de eventos', () => {
    it('deve atualizar quando eventos mudam', () => {
      const { rerender } = render(<ExploreTimeline events={mockEvents} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();

      const newEvents: TimelineEvent[] = [
        {
          id: '3',
          type: 'plan',
          category: 'project',
          title: 'Novo evento',
          timestamp: new Date(),
        },
      ];

      rerender(<ExploreTimeline events={newEvents} />);
      expect(screen.queryByText('Mensagem do usuário')).not.toBeInTheDocument();
      expect(screen.getByText('Novo evento')).toBeInTheDocument();
    });
  });
});
EOF

echo "[ok] ExploreTimeline.test.tsx corrigido (tipos explícitos)"

echo "[info] Corrigindo WorkspaceTabs.test.tsx (import vi)..."

cat > "$WORKSPACE_TABS_TEST" << 'EOF'
import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { WorkspaceTabs } from './WorkspaceTabs';

describe('WorkspaceTabs', () => {
  const mockTabs = [
    { id: 'overview', label: 'Overview', content: <div>Overview Content</div> },
    { id: 'hus', label: 'HUs', content: <div>HUs Content</div> },
    { id: 'docs', label: 'Docs', content: <div>Docs Content</div> },
  ];

  it('deve renderizar todas as abas', () => {
    render(<WorkspaceTabs tabs={mockTabs} defaultActiveTab="overview" />);

    expect(screen.getByRole('button', { name: /overview/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /hus/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /docs/i })).toBeInTheDocument();
  });

  it('deve renderizar conteúdo da aba ativa por padrão', () => {
    render(<WorkspaceTabs tabs={mockTabs} defaultActiveTab="overview" />);

    expect(screen.getByText('Overview Content')).toBeInTheDocument();
    expect(screen.queryByText('HUs Content')).not.toBeInTheDocument();
  });

  it('deve chamar onTabChange quando aba é clicada', () => {
    const handleTabChange = vi.fn();
    render(<WorkspaceTabs tabs={mockTabs} defaultActiveTab="overview" onTabChange={handleTabChange} />);

    const husButton = screen.getByRole('button', { name: /hus/i });
    husButton.click();

    expect(handleTabChange).toHaveBeenCalledWith('hus');
  });

  it('deve aplicar classe active na aba selecionada', () => {
    render(<WorkspaceTabs tabs={mockTabs} defaultActiveTab="overview" />);

    const overviewButton = screen.getByRole('button', { name: /overview/i });
    expect(overviewButton).toHaveClass('active');
  });
});
EOF

echo "[ok] WorkspaceTabs.test.tsx corrigido (import vi)"

echo ""
echo "[info] Executando testes do ExploreTimeline..."
pnpm --filter @mini-ide/ui test -- ExploreTimeline.test.tsx

echo ""
echo "[info] Executando lint da UI..."
pnpm --filter @mini-ide/ui lint

echo ""
echo "[info] Executando typecheck da UI..."
pnpm --filter @mini-ide/ui typecheck

echo ""
echo "[info] Executando build da UI..."
pnpm --filter @mini-ide/ui build

echo ""
echo "[info] Executando TODOS os testes da UI..."
pnpm --filter @mini-ide/ui test

echo ""
echo "=========================================="
echo "CORREÇÃO DEFINITIVA CONCLUÍDA"
echo "=========================================="
echo ""
echo "Arquivos corrigidos:"
echo "  ✓ ExploreTimeline.tsx (defaultProps + validação)"
echo "  ✓ ExploreTimeline.test.tsx (tipos explícitos)"
echo "  ✓ WorkspaceTabs.test.tsx (import vi)"
echo ""
echo "Correções aplicadas:"
echo "  ✓ Props 'events' com default [] para evitar undefined"
echo "  ✓ Todos os 'as any' removidos dos testes"
echo "  ✓ Import 'vi' adicionado no WorkspaceTabs.test"
echo "  ✓ Tipos TimelineEvent explícitos em todos os testes"
echo ""
echo "Se todos os testes passaram:"
echo "  git add packages/ui/src/components/"
echo "  git commit -m 'fix(ui): correção definitiva ExploreTimeline + testes'"
echo ""
echo "[ok] Script concluído!"
