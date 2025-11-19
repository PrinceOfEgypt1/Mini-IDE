#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Script: 13_fix_typecheck_errors.sh
# Objetivo: Corrigir os 4 erros de typecheck identificados após o script 12
# 
# Erros a corrigir:
# 1. WorkspaceTabs.tsx: React importado mas não usado
# 2. ExploreTimeline.test.tsx: beforeEach importado mas não usado
# 3. ExploreTimeline.test.tsx: container declarado mas não usado
# 4. ExploreTimeline.test.tsx: Tipo incorreto em newEvents (evento duplicado inválido)
#
# Modo de uso:
#   bash scripts/13_fix_typecheck_errors.sh
#
# Efeitos colaterais:
#   - Modifica packages/ui/src/components/WorkspaceTabs.tsx
#   - Modifica packages/ui/src/components/explore/ExploreTimeline.test.tsx
# =============================================================================

UI_DIR="packages/ui/src"

echo "[info] Iniciando correção de erros de typecheck..."

# -----------------------------------------------------------------------------
# 1. Corrigir WorkspaceTabs.tsx - remover import de React não usado
# -----------------------------------------------------------------------------
cat > "${UI_DIR}/components/WorkspaceTabs.tsx" << 'EOF'
import { useState } from 'react';
import styles from './WorkspaceTabs.module.css';

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

export interface Tab {
  id: TabId;
  label: string;
}

const tabs: Tab[] = [
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

export interface WorkspaceTabsProps {
  activeTab: TabId;
  onTabChange: (tabId: TabId) => void;
}

export function WorkspaceTabs({ activeTab, onTabChange }: WorkspaceTabsProps) {
  return (
    <div className={styles.tabs}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
          onClick={() => onTabChange(tab.id)}
          aria-current={activeTab === tab.id ? 'page' : undefined}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
EOF

echo "[ok] WorkspaceTabs.tsx corrigido (React não usado removido)"

# -----------------------------------------------------------------------------
# 2. Corrigir ExploreTimeline.test.tsx - remover imports/vars não usados e corrigir tipo
# -----------------------------------------------------------------------------
cat > "${UI_DIR}/components/explore/ExploreTimeline.test.tsx" << 'EOF'
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreTimeline, TimelineEvent, TimelineEventType } from './ExploreTimeline';

describe('ExploreTimeline', () => {
  const mockEvents: TimelineEvent[] = [
    {
      id: '1',
      type: 'message' as TimelineEventType,
      title: 'Mensagem do usuário',
      timestamp: new Date('2024-01-15T10:00:00Z'),
    },
    {
      id: '2',
      type: 'response' as TimelineEventType,
      title: 'Resposta do agente',
      timestamp: new Date('2024-01-15T10:01:00Z'),
    },
  ];

  describe('Renderização básica', () => {
    it('deve renderizar sem erros quando vazio', () => {
      render(<ExploreTimeline />);
      expect(screen.getByText(/Nenhum evento registrado/i)).toBeInTheDocument();
    });

    it('deve renderizar eventos quando fornecidos', () => {
      render(<ExploreTimeline events={mockEvents} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();
      expect(screen.getByText('Resposta do agente')).toBeInTheDocument();
    });

    it('deve aplicar className customizada quando fornecida', () => {
      const { container } = render(
        <ExploreTimeline events={mockEvents} className="custom-class" />
      );
      const timeline = container.querySelector('.custom-class');
      expect(timeline).toBeInTheDocument();
    });
  });

  describe('Formatação de timestamp', () => {
    it('deve formatar timestamps corretamente', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message' as TimelineEventType,
          title: 'Teste',
          timestamp: new Date('2024-01-15T14:30:45Z'),
        },
      ];
      render(<ExploreTimeline events={events} />);

      // Verifica se o timestamp está presente (formato pode variar por locale)
      const timeElement = screen.getByText((content, element) => {
        return element?.tagName === 'TIME' && content.includes('14:30');
      });
      expect(timeElement).toBeInTheDocument();
    });
  });

  describe('Tipos de eventos', () => {
    const eventTypes: Array<{ type: TimelineEventType; label: string }> = [
      { type: 'message', label: 'Mensagem' },
      { type: 'response', label: 'Resposta' },
      { type: 'plan', label: 'Plano' },
      { type: 'hu', label: 'HU' },
      { type: 'export', label: 'Exportação' },
      { type: 'mode-change', label: 'Mudança de modo' },
    ];

    eventTypes.forEach(({ type, label }) => {
      it(`deve renderizar evento do tipo "${type}"`, () => {
        const events: TimelineEvent[] = [
          {
            id: `${type}-1`,
            type,
            title: `${label} de teste`,
            timestamp: new Date(),
          },
        ];
        render(<ExploreTimeline events={events} />);
        expect(screen.getByText(`${label} de teste`)).toBeInTheDocument();
      });
    });
  });

  describe('Ordenação de eventos', () => {
    it('deve exibir eventos em ordem cronológica inversa (mais recente primeiro)', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message' as TimelineEventType,
          title: 'Evento antigo',
          timestamp: new Date('2024-01-15T10:00:00Z'),
        },
        {
          id: '2',
          type: 'response' as TimelineEventType,
          title: 'Evento novo',
          timestamp: new Date('2024-01-15T12:00:00Z'),
        },
      ];

      render(<ExploreTimeline events={events} />);

      const titles = screen.getAllByRole('heading', { level: 4 });
      expect(titles[0]).toHaveTextContent('Evento novo');
      expect(titles[1]).toHaveTextContent('Evento antigo');
    });
  });

  describe('Filtros', () => {
    it('deve filtrar eventos por tipo quando filtro é aplicado', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message' as TimelineEventType,
          title: 'Mensagem 1',
          timestamp: new Date(),
        },
        {
          id: '2',
          type: 'response' as TimelineEventType,
          title: 'Resposta 1',
          timestamp: new Date(),
        },
        {
          id: '3',
          type: 'plan' as TimelineEventType,
          title: 'Plano 1',
          timestamp: new Date(),
        },
      ];

      render(<ExploreTimeline events={events} filterType="message" />);

      expect(screen.getByText('Mensagem 1')).toBeInTheDocument();
      expect(screen.queryByText('Resposta 1')).not.toBeInTheDocument();
      expect(screen.queryByText('Plano 1')).not.toBeInTheDocument();
    });

    it('deve exibir todos os eventos quando filtro é "all"', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message' as TimelineEventType,
          title: 'Mensagem 1',
          timestamp: new Date(),
        },
        {
          id: '2',
          type: 'response' as TimelineEventType,
          title: 'Resposta 1',
          timestamp: new Date(),
        },
      ];

      render(<ExploreTimeline events={events} filterType="all" />);

      expect(screen.getByText('Mensagem 1')).toBeInTheDocument();
      expect(screen.getByText('Resposta 1')).toBeInTheDocument();
    });
  });

  describe('Scroll automático', () => {
    it('deve renderizar corretamente com autoScroll habilitado', () => {
      render(<ExploreTimeline events={mockEvents} autoScroll={true} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();
    });

    it('deve renderizar corretamente com autoScroll desabilitado', () => {
      render(<ExploreTimeline events={mockEvents} autoScroll={false} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();
    });
  });

  describe('Performance com muitos eventos', () => {
    it('deve renderizar 100+ eventos sem problemas', () => {
      const manyEvents: TimelineEvent[] = Array.from({ length: 150 }, (_, i) => ({
        id: `event-${i}`,
        type: (i % 2 === 0 ? 'message' : 'response') as TimelineEventType,
        title: `Evento ${i}`,
        timestamp: new Date(Date.now() - i * 1000),
      }));

      render(<ExploreTimeline events={manyEvents} />);

      // Verifica que o primeiro e último evento estão presentes
      expect(screen.getByText('Evento 0')).toBeInTheDocument();
      expect(screen.getByText('Evento 149')).toBeInTheDocument();
    });
  });

  describe('Acessibilidade', () => {
    it('deve ter estrutura semântica adequada', () => {
      render(<ExploreTimeline events={mockEvents} />);

      // Verifica se há elementos time com datetime
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
      expect(screen.getByText(/Nenhum evento registrado/i)).toBeInTheDocument();
    });

    it('deve lidar com eventos sem título', () => {
      const events: TimelineEvent[] = [
        {
          id: '1',
          type: 'message' as TimelineEventType,
          title: '',
          timestamp: new Date(),
        },
      ];
      render(<ExploreTimeline events={events} />);
      // Deve renderizar sem quebrar, mesmo com título vazio
      expect(screen.queryByText(/Nenhum evento registrado/i)).not.toBeInTheDocument();
    });
  });

  describe('Atualização de eventos', () => {
    it('deve atualizar quando eventos mudam', () => {
      const { rerender } = render(<ExploreTimeline events={mockEvents} />);
      expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();

      // Adiciona novo evento com tipo válido
      const newEvents: TimelineEvent[] = [
        ...mockEvents,
        {
          id: '3',
          type: 'plan' as TimelineEventType,
          title: 'Novo evento',
          timestamp: new Date(),
        },
      ];

      rerender(<ExploreTimeline events={newEvents} />);
      expect(screen.getByText('Novo evento')).toBeInTheDocument();
    });
  });
});
EOF

echo "[ok] ExploreTimeline.test.tsx corrigido (imports não usados removidos e tipo corrigido)"

# -----------------------------------------------------------------------------
# Resumo
# -----------------------------------------------------------------------------
cat << 'EOF'

=========================================
✅ Correções Aplicadas com Sucesso
=========================================
1. WorkspaceTabs.tsx: Removido import de React não usado
2. ExploreTimeline.test.tsx: Removido beforeEach não usado
3. ExploreTimeline.test.tsx: Removida variável container não usada em teste específico
4. ExploreTimeline.test.tsx: Corrigido tipo do evento duplicado em newEvents

Execute agora:
  1. pnpm --filter @mini-ide/ui typecheck
  2. pnpm --filter @mini-ide/ui test
  3. pnpm --filter @mini-ide/ui build

=========================================
EOF
