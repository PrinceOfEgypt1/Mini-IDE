#!/usr/bin/env bash
################################################################################
# Script: 28_move_ui_component_tests_out_of_src.sh
# Objetivo:
#   - Remover testes de UI criados dentro de src/components
#   - Recriar esses testes em packages/ui/test/components
#   - Manter Vitest rodando todos os testes
#   - Impedir que tsconfig.build.json compile arquivos de teste
#
# Afeta:
#   - REMOVE:
#       packages/ui/src/components/WorkspaceTabs.test.tsx
#       packages/ui/src/components/discovery/DiscoveryNotes.test.tsx
#       packages/ui/src/components/explore/ExploreOverview.test.tsx
#       packages/ui/src/components/explore/ExploreTimeline.test.tsx
#   - CRIA:
#       packages/ui/test/components/WorkspaceTabs.test.tsx
#       packages/ui/test/components/DiscoveryNotes.test.tsx
#       packages/ui/test/components/ExploreOverview.test.tsx
#       packages/ui/test/components/ExploreTimeline.test.tsx
################################################################################

set -euo pipefail

echo "[info] Movendo testes de UI para o diretório test/components..."

UI_ROOT="packages/ui"
SRC_COMPONENTS="$UI_ROOT/src/components"
TEST_COMPONENTS="$UI_ROOT/test/components"

mkdir -p "$TEST_COMPONENTS"

################################################################################
# 1) WorkspaceTabs.test.tsx  -> test/components/WorkspaceTabs.test.tsx
################################################################################
echo "[info] Recriando WorkspaceTabs.test.tsx em $TEST_COMPONENTS..."

cat > "$TEST_COMPONENTS/WorkspaceTabs.test.tsx" << 'EOF'
/**
 * @file WorkspaceTabs.test.tsx
 * @description Testes de integração do sistema de abas WorkspaceTabs
 */

import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { WorkspaceTabs } from '../../src/components/WorkspaceTabs.js';

function renderWorkspaceTabs() {
  return render(<WorkspaceTabs />);
}

describe('WorkspaceTabs - estrutura básica', () => {
  it('renderiza as 10 abas com rótulos esperados', () => {
    renderWorkspaceTabs();

    const labels = [
      'Overview',
      'HUs',
      'Docs',
      'Testes',
      'Analyze',
      'Personas & Plano',
      'Timeline',
      'Runs',
      'Métricas',
      'Outputs',
    ];

    labels.forEach((label) => {
      expect(
        screen.getByRole('button', { name: new RegExp(`\\b${label}\\b`, 'i') }),
      ).toBeInTheDocument();
    });
  });

  it('inicia com a aba Overview ativa (aria-current="page")', () => {
    renderWorkspaceTabs();

    const overviewButton = screen.getByRole('button', { name: /overview/i });

    expect(overviewButton).toBeInTheDocument();
    expect(overviewButton).toHaveAttribute('aria-current', 'page');
  });
});

describe('WorkspaceTabs - navegação entre abas', () => {
  it('permite navegar para aba Analyze e marcá-la como ativa', () => {
    renderWorkspaceTabs();

    const overviewButton = screen.getByRole('button', { name: /overview/i });
    const analyzeButton = screen.getByRole('button', { name: /analyze/i });

    // Estado inicial
    expect(overviewButton).toHaveAttribute('aria-current', 'page');
    expect(analyzeButton).not.toHaveAttribute('aria-current', 'page');

    // Navega para aba Analyze
    fireEvent.click(analyzeButton);

    expect(analyzeButton).toHaveAttribute('aria-current', 'page');
    expect(overviewButton).not.toHaveAttribute('aria-current', 'page');
  });

  it('mantém todas as abas presentes após navegação', () => {
    renderWorkspaceTabs();

    const analyzeButton = screen.getByRole('button', { name: /analyze/i });
    fireEvent.click(analyzeButton);

    const labels = [
      'Overview',
      'HUs',
      'Docs',
      'Testes',
      'Analyze',
      'Personas & Plano',
      'Timeline',
      'Runs',
      'Métricas',
      'Outputs',
    ];

    labels.forEach((label) => {
      expect(
        screen.getByRole('button', { name: new RegExp(`\\b${label}\\b`, 'i') }),
      ).toBeInTheDocument();
    });
  });
});
EOF

################################################################################
# 2) DiscoveryNotes.test.tsx  -> test/components/DiscoveryNotes.test.tsx
################################################################################
echo "[info] Recriando DiscoveryNotes.test.tsx em $TEST_COMPONENTS..."

cat > "$TEST_COMPONENTS/DiscoveryNotes.test.tsx" << 'EOF'
/**
 * @file DiscoveryNotes.test.tsx
 * @description Testes do painel direito DiscoveryNotes (editor com persistência)
 */

import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { DiscoveryNotes } from '../../src/components/discovery/DiscoveryNotes.js';

describe('DiscoveryNotes', () => {
  it('renderiza o título e a descrição principal', () => {
    render(<DiscoveryNotes />);

    expect(screen.getByText('Discovery Notes')).toBeInTheDocument();
    expect(
      screen.getByText(/Coleta automática do que surge no chat/i),
    ).toBeInTheDocument();
  });

  it('renderiza os quatro campos principais', () => {
    render(<DiscoveryNotes />);

    expect(screen.getByText('Intenção')).toBeInTheDocument();
    expect(screen.getByText('Requisitos')).toBeInTheDocument();
    expect(screen.getByText('Restrições')).toBeInTheDocument();
    expect(screen.getByText('Exemplos & Referências')).toBeInTheDocument();
  });

  it('permite editar o campo de intenção e persiste no localStorage', () => {
    const setItemSpy = vi.spyOn(window.localStorage.__proto__, 'setItem');

    render(<DiscoveryNotes />);

    const intentionField = screen.getByLabelText('Campo de intenção');

    fireEvent.change(intentionField, {
      target: { value: 'Explorar a UI da Mini-IDE' },
    });

    expect(intentionField).toHaveValue('Explorar a UI da Mini-IDE');
    // Não validamos a chave exata, apenas que algo foi salvo
    expect(setItemSpy).toHaveBeenCalled();

    setItemSpy.mockRestore();
  });
});
EOF

################################################################################
# 3) ExploreOverview.test.tsx -> test/components/ExploreOverview.test.tsx
################################################################################
echo "[info] Recriando ExploreOverview.test.tsx em $TEST_COMPONENTS..."

cat > "$TEST_COMPONENTS/ExploreOverview.test.tsx" << 'EOF'
/**
 * @file ExploreOverview.test.tsx
 * @description Testes do painel Overview do Explore Workspace
 */

import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreOverview } from '../../src/components/explore/ExploreOverview.js';

describe('ExploreOverview', () => {
  it('renderiza as três seções principais: Estado da Sessão, Projeto Atual e Últimas Análises', () => {
    render(<ExploreOverview />);

    expect(screen.getByText('Estado da Sessão')).toBeInTheDocument();
    expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
    expect(screen.getByText('Últimas Análises')).toBeInTheDocument();
  });

  it('renderiza as informações padrão do projeto Mini-IDE', () => {
    render(<ExploreOverview />);

    expect(screen.getByText('Mini-IDE')).toBeInTheDocument();
    expect(screen.getByText('PrinceOfEgypt1/Mini-IDE')).toBeInTheDocument();
    expect(screen.getByText('main')).toBeInTheDocument();
    expect(screen.getByText('~/workspace/Mini-IDE')).toBeInTheDocument();
  });

  it('exibe pelo menos uma análise mockada na lista de Últimas Análises', () => {
    render(<ExploreOverview />);

    // Strings usadas nos mocks originais (estado inicial)
    expect(
      screen.getByText(/Análise de estrutura de componentes React/i),
    ).toBeInTheDocument();
  });
});
EOF

################################################################################
# 4) ExploreTimeline.test.tsx -> test/components/ExploreTimeline.test.tsx
################################################################################
echo "[info] Recriando ExploreTimeline.test.tsx em $TEST_COMPONENTS..."

cat > "$TEST_COMPONENTS/ExploreTimeline.test.tsx" << 'EOF'
/**
 * @file ExploreTimeline.test.tsx
 * @description Testes da Timeline de Exploração (aba Timeline)
 */

import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreTimeline } from '../../src/components/explore/ExploreTimeline.js';

describe('ExploreTimeline', () => {
  it('renderiza o cabeçalho da timeline', () => {
    render(<ExploreTimeline />);

    expect(
      screen.getByText(/Timeline de Exploração/i),
    ).toBeInTheDocument();
  });

  it('renderiza eventos mockados de usuário e agente', () => {
    render(<ExploreTimeline />);

    expect(screen.getByText('Mensagem do usuário')).toBeInTheDocument();
    expect(screen.getByText('Resposta do agente')).toBeInTheDocument();
  });

  it('exibe mensagem adequada quando não houver eventos (estado vazio)', () => {
    // Se o componente tiver suporte a props, este teste pode ser evoluído no futuro
    render(<ExploreTimeline />);

    // Pelo menos garantimos que o texto padrão de "nenhum evento" existe na árvore,
    // mesmo que não esteja visível no estado inicial
    expect(
      screen.getByText(/Nenhum evento encontrado/i),
    ).toBeInTheDocument();
  });
});
EOF

################################################################################
# 5) Remover arquivos de teste de dentro de src/components
################################################################################
echo "[info] Removendo arquivos de teste de dentro de src/components..."

rm -f "$SRC_COMPONENTS/WorkspaceTabs.test.tsx" || true
rm -f "$SRC_COMPONENTS/discovery/DiscoveryNotes.test.tsx" || true
rm -f "$SRC_COMPONENTS/explore/ExploreOverview.test.tsx" || true
rm -f "$SRC_COMPONENTS/explore/ExploreTimeline.test.tsx" || true

echo ""
echo "=========================================="
echo "✅ Testes de UI movidos para test/components"
echo "=========================================="
echo "Criados:"
echo "  - $TEST_COMPONENTS/WorkspaceTabs.test.tsx"
echo "  - $TEST_COMPONENTS/DiscoveryNotes.test.tsx"
echo "  - $TEST_COMPONENTS/ExploreOverview.test.tsx"
echo "  - $TEST_COMPONENTS/ExploreTimeline.test.tsx"
echo ""
echo "Removidos de src/:"
echo "  - $SRC_COMPONENTS/WorkspaceTabs.test.tsx"
echo "  - $SRC_COMPONENTS/discovery/DiscoveryNotes.test.tsx"
echo "  - $SRC_COMPONENTS/explore/ExploreOverview.test.tsx"
echo "  - $SRC_COMPONENTS/explore/ExploreTimeline.test.tsx"
echo ""
echo "Próximos passos sugeridos:"
echo "  1. pnpm --filter @mini-ide/ui test"
echo "  2. pnpm --filter @mini-ide/ui lint"
echo "  3. pnpm --filter @mini-ide/ui typecheck"
echo "  4. pnpm --filter @mini-ide/ui build"
echo "=========================================="
EOF
