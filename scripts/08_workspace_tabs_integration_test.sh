#!/usr/bin/env bash
# ==============================================================================
# Script: 08_workspace_tabs_integration_test.sh
# HU: Testes de integração do WorkspaceTabs com os novos componentes
# ==============================================================================
# Objetivo:
#   Criar testes de integração para o componente WorkspaceTabs, garantindo que:
#   - A aba padrão seja Overview
#   - A navegação entre abas funcione
#   - As integrações principais (Overview, Analyze, Timeline) estejam visíveis
#
# Arquivos afetados:
#   - packages/ui/src/components/WorkspaceTabs.test.tsx (criado/reescrito)
#
# Premissas:
#   - WorkspaceTabs.tsx existe em packages/ui/src/components/WorkspaceTabs.tsx
#   - ExploreOverview, ExploreTimeline, ServerStatus e AnalyzePlayground existem
#   - Testes da UI usam Vitest + React Testing Library
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/WorkspaceTabs.test.tsx
# ==============================================================================

set -euo pipefail

echo "[info] Criando testes de integração do WorkspaceTabs..."

TARGET_FILE="packages/ui/src/components/WorkspaceTabs.test.tsx"
TARGET_DIR="$(dirname "$TARGET_FILE")"
mkdir -p "$TARGET_DIR"

cat > "$TARGET_FILE" << 'EOF'
/**
 * @file WorkspaceTabs.test.tsx
 * @description Testes de integração do sistema de abas WorkspaceTabs
 */

import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { WorkspaceTabs } from './WorkspaceTabs.js';

function renderWorkspaceTabs() {
  return render(<WorkspaceTabs />);
}

describe('WorkspaceTabs - integração básica', () => {
  it('renderiza todas as 10 abas com os rótulos esperados', () => {
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

  it('abre a aba Overview por padrão', () => {
    renderWorkspaceTabs();

    const overviewTab = screen.getByRole('button', { name: /overview/i });
    expect(overviewTab).toHaveAttribute('aria-current', 'page');
  });

  it('permite navegar para a aba Analyze e exibir o título do playground', () => {
    renderWorkspaceTabs();

    const analyzeTab = screen.getByRole('button', { name: /analyze/i });
    fireEvent.click(analyzeTab);

    expect(analyzeTab).toHaveAttribute('aria-current', 'page');
    expect(screen.getByText(/analyze playground/i)).toBeInTheDocument();
  });

  it('permite navegar para a aba HUs e exibir o placeholder correspondente', () => {
    renderWorkspaceTabs();

    const husTab = screen.getByRole('button', { name: /\bhus\b/i });
    fireEvent.click(husTab);

    expect(husTab).toHaveAttribute('aria-current', 'page');
    expect(screen.getByText(/HUs \(User Stories\)/i)).toBeInTheDocument();
  });

  it('permite navegar para a aba Timeline', () => {
    renderWorkspaceTabs();

    const timelineTab = screen.getByRole('button', { name: /timeline/i });
    fireEvent.click(timelineTab);

    expect(timelineTab).toHaveAttribute('aria-current', 'page');
    // Conteúdo concreto da Timeline é responsabilidade do componente ExploreTimeline;
    // aqui garantimos apenas que a aba está ativa sem erro.
  });
});

describe('WorkspaceTabs - acessibilidade básica', () => {
  it('marca corretamente a aba ativa com aria-current="page"', () => {
    renderWorkspaceTabs();

    const overviewTab = screen.getByRole('button', { name: /overview/i });
    const analyzeTab = screen.getByRole('button', { name: /analyze/i });

    // Estado inicial
    expect(overviewTab).toHaveAttribute('aria-current', 'page');
    expect(analyzeTab).not.toHaveAttribute('aria-current', 'page');

    // Após click em Analyze
    fireEvent.click(analyzeTab);
    expect(analyzeTab).toHaveAttribute('aria-current', 'page');
    expect(overviewTab).not.toHaveAttribute('aria-current', 'page');
  });
});
EOF

echo "[ok] WorkspaceTabs.test.tsx criado com sucesso"

echo "========================================="
echo "✅ Testes de integração do WorkspaceTabs criados"
echo "========================================="
echo "Arquivo criado:"
echo "  - $TARGET_FILE"
echo ""
echo "Cobertura de testes:"
echo "  ✓ Renderização das 10 abas"
echo "  ✓ Aba Overview padrão"
echo "  ✓ Navegação para aba Analyze (inclui título 'Analyze Playground')"
echo "  ✓ Navegação para aba HUs (placeholder visível)"
echo "  ✓ Navegação para aba Timeline (aba ativa sem erro)"
echo "  ✓ Acessibilidade básica via aria-current"
echo ""
echo "Próximos passos sugeridos:"
echo "  1. Execute: pnpm --filter @mini-ide/ui test WorkspaceTabs"
echo "  2. Execute: pnpm --filter @mini-ide/ui lint"
echo "  3. Execute: pnpm --filter @mini-ide/ui typecheck"
echo "  4. Execute: pnpm --filter @mini-ide/ui build"
echo "========================================="
