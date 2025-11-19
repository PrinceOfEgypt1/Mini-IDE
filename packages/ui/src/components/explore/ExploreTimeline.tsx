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
    new Set(['analysis', 'discovery', 'project', 'execution', 'system']),
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
                {event.description && (
                  <p className={styles.eventDescription}>{event.description}</p>
                )}
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
