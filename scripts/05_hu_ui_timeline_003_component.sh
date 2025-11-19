#!/usr/bin/env bash
# ==============================================================================
# Script: 05_hu_ui_timeline_003_component.sh
# HU: HU-UI-Timeline-003 – Timeline de Exploração (esqueleto inicial)
# ==============================================================================
# Objetivo:
#   Criar esqueleto da aba Timeline com lista cronológica de eventos mockados
#   e filtro simples por tipo de evento.
#
# Arquivos afetados:
#   - packages/ui/src/components/explore/ExploreTimeline.tsx (criado)
#   - packages/ui/src/components/explore/ExploreTimeline.module.css (criado)
#
# Premissas:
#   - Aba Timeline já existe em WorkspaceTabs
#   - Layout de 3 colunas permanece intacto
#   - Dados mockados nesta primeira versão
#   - TypeScript strict mode
#
# Riscos:
#   - Nenhum risco de quebra (apenas evolução interna da aba Timeline)
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/explore/ExploreTimeline.*
# ==============================================================================

set -euo pipefail

echo "[info] Iniciando implementação da HU-UI-Timeline-003..."

# ------------------------------------------------------------------------------
# 1. Garantir que diretório explore existe
# ------------------------------------------------------------------------------
mkdir -p packages/ui/src/components/explore

echo "[ok] Diretório explore verificado"

# ------------------------------------------------------------------------------
# 2. ExploreTimeline.tsx - Componente da aba Timeline
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreTimeline.tsx << 'EOF'
/**
 * @file ExploreTimeline.tsx
 * @description Aba Timeline com histórico cronológico de eventos de exploração
 * @module @mini-ide/ui/components/explore
 */

import { useState, useMemo } from 'react';
import styles from './ExploreTimeline.module.css';

/**
 * Tipos de eventos disponíveis na timeline
 */
export type TimelineEventType = 
  | 'analysis'
  | 'discovery'
  | 'project'
  | 'execution'
  | 'system';

/**
 * Estrutura de um evento na timeline
 */
export interface TimelineEvent {
  id: string;
  type: TimelineEventType;
  timestamp: Date;
  title: string;
  description?: string;
  metadata?: Record<string, unknown>;
}

/**
 * Props do componente ExploreTimeline
 */
export interface ExploreTimelineProps {
  /** Lista de eventos (mockados se não fornecidos) */
  events?: TimelineEvent[];
}

/**
 * Eventos mockados para desenvolvimento
 */
const MOCK_EVENTS: TimelineEvent[] = [
  {
    id: '1',
    type: 'system',
    timestamp: new Date(Date.now() - 600000), // 10 min atrás
    title: 'Sessão iniciada',
    description: 'Nova sessão de exploração do Mini-IDE iniciada',
  },
  {
    id: '2',
    type: 'project',
    timestamp: new Date(Date.now() - 540000), // 9 min atrás
    title: 'Projeto selecionado',
    description: 'Projeto "Mini-IDE" carregado com sucesso',
    metadata: { projectName: 'Mini-IDE', branch: 'main' },
  },
  {
    id: '3',
    type: 'discovery',
    timestamp: new Date(Date.now() - 480000), // 8 min atrás
    title: 'Discovery Notes alteradas',
    description: 'Campo "Intenção" atualizado',
    metadata: { field: 'intention' },
  },
  {
    id: '4',
    type: 'analysis',
    timestamp: new Date(Date.now() - 360000), // 6 min atrás
    title: 'Análise executada',
    description: 'Análise de estrutura de componentes React concluída',
    metadata: { inputLength: 1523, outputLength: 245 },
  },
  {
    id: '5',
    type: 'discovery',
    timestamp: new Date(Date.now() - 300000), // 5 min atrás
    title: 'Discovery Notes alteradas',
    description: 'Campo "Requisitos" atualizado',
    metadata: { field: 'requirements' },
  },
  {
    id: '6',
    type: 'analysis',
    timestamp: new Date(Date.now() - 240000), // 4 min atrás
    title: 'Análise executada',
    description: 'Verificação de tipagem TypeScript em módulos',
    metadata: { inputLength: 982, outputLength: 156 },
  },
  {
    id: '7',
    type: 'execution',
    timestamp: new Date(Date.now() - 180000), // 3 min atrás
    title: 'Pipeline executado',
    description: 'Testes unitários executados com sucesso',
    metadata: { testsRun: 152, passed: 152 },
  },
  {
    id: '8',
    type: 'discovery',
    timestamp: new Date(Date.now() - 120000), // 2 min atrás
    title: 'Discovery Notes alteradas',
    description: 'Campo "Exemplos & Referências" atualizado',
    metadata: { field: 'examples' },
  },
];

/**
 * Configuração de ícone e cor por tipo de evento
 */
const EVENT_TYPE_CONFIG: Record<TimelineEventType, { icon: string; color: string; label: string }> = {
  analysis: { icon: '🔬', color: 'var(--brand, #4ba3ff)', label: 'Análise' },
  discovery: { icon: '📝', color: 'var(--accent, #00c2a8)', label: 'Discovery' },
  project: { icon: '📁', color: 'var(--ok, #47e6a1)', label: 'Projeto' },
  execution: { icon: '⚡', color: 'var(--brand-2, #6ad3ff)', label: 'Execução' },
  system: { icon: '⚙️', color: 'var(--muted, #9fb0d3)', label: 'Sistema' },
};

/**
 * Formata timestamp em formato legível
 */
function formatTimestamp(date: Date): string {
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0');
  const seconds = date.getSeconds().toString().padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
}

/**
 * Formata timestamp relativo (ex: "5 min atrás")
 */
function formatRelativeTime(date: Date): string {
  const now = Date.now();
  const diff = now - date.getTime();
  const minutes = Math.floor(diff / 60000);

  if (minutes < 1) return 'agora mesmo';
  if (minutes === 1) return '1 minuto atrás';
  if (minutes < 60) return `${minutes} minutos atrás`;

  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hora atrás';
  if (hours < 24) return `${hours} horas atrás`;

  const days = Math.floor(hours / 24);
  return days === 1 ? '1 dia atrás' : `${days} dias atrás`;
}

/**
 * Componente ExploreTimeline - Aba Timeline do modo Explorar
 * 
 * Funcionalidades:
 * - Exibe lista cronológica de eventos
 * - Filtro por tipo de evento (múltipla seleção)
 * - Ícones e cores distintas por tipo
 * - Timestamps absolutos e relativos
 * - Suporta dados mockados para desenvolvimento
 * 
 * Layout:
 * - Renderizado dentro da aba Timeline do painel central
 * - Respeita estrutura de 3 colunas do wireframe
 */
export function ExploreTimeline({
  events = MOCK_EVENTS,
}: ExploreTimelineProps) {
  const [selectedTypes, setSelectedTypes] = useState<Set<TimelineEventType>>(
    new Set(['analysis', 'discovery', 'project', 'execution', 'system'])
  );

  /**
   * Eventos filtrados baseados nos tipos selecionados
   */
  const filteredEvents = useMemo(() => {
    return events
      .filter((event) => selectedTypes.has(event.type))
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
  }, [events, selectedTypes]);

  /**
   * Toggle de tipo de evento no filtro
   */
  const toggleEventType = (type: TimelineEventType) => {
    setSelectedTypes((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(type)) {
        newSet.delete(type);
      } else {
        newSet.add(type);
      }
      return newSet;
    });
  };

  /**
   * Seleciona todos os tipos
   */
  const selectAllTypes = () => {
    setSelectedTypes(new Set(['analysis', 'discovery', 'project', 'execution', 'system']));
  };

  /**
   * Desmarca todos os tipos
   */
  const clearAllTypes = () => {
    setSelectedTypes(new Set());
  };

  return (
    <div className={styles.exploreTimeline}>
      {/* Header com controles de filtro */}
      <div className={styles.header}>
        <div className={styles.headerTitle}>
          <h3 className={styles.title}>Timeline de Exploração</h3>
          <span className={styles.badge}>
            {filteredEvents.length} {filteredEvents.length === 1 ? 'evento' : 'eventos'}
          </span>
        </div>

        <div className={styles.filterControls}>
          <button
            className={styles.filterButton}
            onClick={selectAllTypes}
            type="button"
          >
            Todos
          </button>
          <button
            className={styles.filterButton}
            onClick={clearAllTypes}
            type="button"
          >
            Nenhum
          </button>
        </div>
      </div>

      {/* Filtros por tipo */}
      <div className={styles.filters}>
        {(Object.keys(EVENT_TYPE_CONFIG) as TimelineEventType[]).map((type) => {
          const config = EVENT_TYPE_CONFIG[type];
          const isSelected = selectedTypes.has(type);

          return (
            <button
              key={type}
              className={`${styles.filterChip} ${isSelected ? styles.filterChipActive : ''}`}
              onClick={() => toggleEventType(type)}
              type="button"
              aria-pressed={isSelected}
            >
              <span className={styles.filterIcon}>{config.icon}</span>
              <span className={styles.filterLabel}>{config.label}</span>
            </button>
          );
        })}
      </div>

      {/* Lista de eventos */}
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
        <div className={styles.timeline}>
          {filteredEvents.map((event) => {
            const config = EVENT_TYPE_CONFIG[event.type];

            return (
              <div key={event.id} className={styles.timelineItem}>
                <div
                  className={styles.timelineDot}
                  style={{ backgroundColor: config.color }}
                />
                <div className={styles.timelineContent}>
                  <div className={styles.timelineHeader}>
                    <div className={styles.timelineIcon}>{config.icon}</div>
                    <div className={styles.timelineTime}>
                      <span className={styles.timeAbsolute}>
                        {formatTimestamp(event.timestamp)}
                      </span>
                      <span className={styles.timeRelative}>
                        {formatRelativeTime(event.timestamp)}
                      </span>
                    </div>
                  </div>
                  <div className={styles.timelineBody}>
                    <h4 className={styles.timelineTitle}>{event.title}</h4>
                    {event.description && (
                      <p className={styles.timelineDescription}>
                        {event.description}
                      </p>
                    )}
                    {event.metadata && Object.keys(event.metadata).length > 0 && (
                      <div className={styles.timelineMetadata}>
                        {Object.entries(event.metadata).map(([key, value]) => (
                          <span key={key} className={styles.metadataItem}>
                            {key}: {String(value)}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
EOF

echo "[ok] ExploreTimeline.tsx criado com sucesso"

# ------------------------------------------------------------------------------
# 3. ExploreTimeline.module.css - Estilos do componente
# ------------------------------------------------------------------------------
cat > packages/ui/src/components/explore/ExploreTimeline.module.css << 'EOF'
/**
 * @file ExploreTimeline.module.css
 * @description Estilos para o componente ExploreTimeline (aba Timeline)
 */

.exploreTimeline {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 4px;
  height: 100%;
}

/* ============================================================================
   Header e Controles
   ============================================================================ */

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px;
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 12px;
}

.headerTitle {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.badge {
  background: var(--chip, #222b40);
  border: 1px solid var(--border, #24304a);
  border-radius: 999px;
  padding: 3px 10px;
  font-size: 12px;
  font-weight: 600;
  color: var(--muted, #9fb0d3);
}

.filterControls {
  display: flex;
  gap: 8px;
}

.filterButton {
  padding: 6px 12px;
  background: var(--panel-3, #0c1323);
  border: 1px solid var(--border, #24304a);
  border-radius: 8px;
  color: var(--text, #e6ecff);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.filterButton:hover {
  background: var(--panel-2, #101727);
  border-color: var(--brand, #4ba3ff);
}

/* ============================================================================
   Filtros por Tipo
   ============================================================================ */

.filters {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  padding: 12px;
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 12px;
}

.filterChip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background: var(--panel-3, #0c1323);
  border: 1px solid var(--border, #24304a);
  border-radius: 999px;
  color: var(--muted, #9fb0d3);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.filterChip:hover {
  border-color: var(--brand, #4ba3ff);
  transform: scale(1.02);
}

.filterChipActive {
  background: var(--brand, #4ba3ff);
  border-color: var(--brand, #4ba3ff);
  color: white;
}

.filterIcon {
  font-size: 14px;
  line-height: 1;
}

.filterLabel {
  font-size: 13px;
}

/* ============================================================================
   Timeline
   ============================================================================ */

.timeline {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0;
  overflow-y: auto;
  padding-right: 4px;
}

.timelineItem {
  display: flex;
  gap: 16px;
  padding: 16px;
  position: relative;
  transition: background-color 0.2s ease;
}

.timelineItem:hover {
  background: var(--panel-2, #101727);
  border-radius: 8px;
}

.timelineItem:not(:last-child)::after {
  content: '';
  position: absolute;
  left: 27px;
  top: 48px;
  bottom: -16px;
  width: 2px;
  background: var(--border, #24304a);
}

.timelineDot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-top: 6px;
  flex-shrink: 0;
  box-shadow: 0 0 0 4px var(--panel-3, #0c1323);
  z-index: 1;
}

.timelineContent {
  flex: 1;
  min-width: 0;
}

.timelineHeader {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}

.timelineIcon {
  font-size: 18px;
  line-height: 1;
}

.timelineTime {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  margin-left: auto;
}

.timeAbsolute {
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  color: var(--text, #e6ecff);
  font-weight: 600;
}

.timeRelative {
  color: var(--muted, #9fb0d3);
}

.timelineBody {
  padding-left: 28px;
}

.timelineTitle {
  margin: 0 0 4px 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.timelineDescription {
  margin: 0 0 8px 0;
  font-size: 13px;
  color: var(--muted, #9fb0d3);
  line-height: 1.5;
}

.timelineMetadata {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.metadataItem {
  font-size: 11px;
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 6px;
  padding: 2px 6px;
  color: var(--muted, #9fb0d3);
}

/* ============================================================================
   Estado Vazio
   ============================================================================ */

.emptyState {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.emptyIcon {
  font-size: 64px;
  margin-bottom: 16px;
  opacity: 0.4;
}

.emptyText {
  margin: 0;
  font-size: 14px;
  color: var(--muted, #9fb0d3);
  line-height: 1.6;
}

/* ============================================================================
   Scrollbar customizada
   ============================================================================ */

.timeline::-webkit-scrollbar {
  width: 6px;
}

.timeline::-webkit-scrollbar-track {
  background: transparent;
}

.timeline::-webkit-scrollbar-thumb {
  background: var(--border, #24304a);
  border-radius: 3px;
}

.timeline::-webkit-scrollbar-thumb:hover {
  background: var(--muted, #9fb0d3);
}

/* ============================================================================
   Responsividade
   ============================================================================ */

@media (max-width: 900px) {
  .header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .filterControls {
    width: 100%;
    justify-content: flex-end;
  }

  .timelineHeader {
    flex-wrap: wrap;
  }

  .timelineTime {
    width: 100%;
    justify-content: flex-start;
    margin-left: 0;
  }
}
EOF

echo "[ok] ExploreTimeline.module.css criado com sucesso"

# ------------------------------------------------------------------------------
# Sumário
# ------------------------------------------------------------------------------
echo ""
echo "========================================="
echo "✅ HU-UI-Timeline-003 implementada"
echo "========================================="
echo "Arquivos criados/modificados:"
echo "  - packages/ui/src/components/explore/ExploreTimeline.tsx"
echo "  - packages/ui/src/components/explore/ExploreTimeline.module.css"
echo ""
echo "Funcionalidades:"
echo "  ✓ Lista cronológica de eventos (mais recente primeiro)"
echo "  ✓ Filtro por tipo de evento (múltipla seleção)"
echo "  ✓ 5 tipos de eventos: analysis, discovery, project, execution, system"
echo "  ✓ Ícones e cores distintas por tipo"
echo "  ✓ Timestamps absolutos (HH:MM:SS) e relativos (X min atrás)"
echo "  ✓ Metadados opcionais por evento"
echo "  ✓ Estado vazio quando não há eventos"
echo "  ✓ Dados mockados para desenvolvimento"
echo "  ✓ Layout preservado (aba Timeline no painel central)"
echo ""
echo "Próximos passos:"
echo "  1. Execute o script de testes: 06_hu_ui_timeline_003_test.sh"
echo "  2. Integre com WorkspaceTabs (ver script de integração)"
echo "========================================="
