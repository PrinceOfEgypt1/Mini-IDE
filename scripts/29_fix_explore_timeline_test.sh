#!/usr/bin/env bash
################################################################################
# Script: 29_fix_explore_timeline_test.sh
# Objetivo:
#   Alinhar o teste ExploreTimeline.test.tsx ao comportamento atual do componente:
#   - Cabeçalho "Timeline de Exploração"
#   - Filtros de categoria (Análise, Discovery, Projeto, Execução, Sistema)
#   - Estado vazio com texto "Nenhum evento encontrado..."
#
# Afeta:
#   - packages/ui/test/components/ExploreTimeline.test.tsx (reescrito)
################################################################################

set -euo pipefail

echo "[info] Reescrevendo test/components/ExploreTimeline.test.tsx ..."

TARGET="packages/ui/test/components/ExploreTimeline.test.tsx"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" << 'EOF'
/**
 * @file ExploreTimeline.test.tsx
 * @description Testes da Timeline de Exploração (aba Timeline)
 */

import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ExploreTimeline } from '../../src/components/explore/ExploreTimeline.js';

describe('ExploreTimeline', () => {
  it('renderiza o cabeçalho da timeline e a contagem de eventos', () => {
    render(<ExploreTimeline />);

    expect(screen.getByText(/Timeline de Exploração/i)).toBeInTheDocument();
    expect(screen.getByText(/0\s+eventos/i)).toBeInTheDocument();
  });

  it('renderiza os filtros de categoria com 5 chips ativos', () => {
    render(<ExploreTimeline />);

    // Botões de filtro principais
    expect(
      screen.getByRole('button', { name: /habilitar todos os filtros/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /desabilitar todos os filtros/i }),
    ).toBeInTheDocument();

    // Chips por tipo
    expect(
      screen.getByRole('button', { name: /filtrar por análise/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /filtrar por discovery/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /filtrar por projeto/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /filtrar por execução/i }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole('button', { name: /filtrar por sistema/i }),
    ).toBeInTheDocument();
  });

  it('exibe estado vazio quando não há eventos compatíveis com os filtros', () => {
    render(<ExploreTimeline />);

    expect(
      screen.getByText(/Nenhum evento encontrado com os filtros atuais/i),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/Ajuste os filtros acima para ver mais eventos/i),
    ).toBeInTheDocument();
  });
});
EOF

echo "[ok] ExploreTimeline.test.tsx reescrito com sucesso"

echo ""
echo "=========================================="
echo "✅ Correção aplicada em ExploreTimeline.test.tsx"
echo "=========================================="
echo "Arquivo atualizado:"
echo "  - $TARGET"
echo ""
echo "Próximo passo sugerido:"
echo "  pnpm --filter @mini-ide/ui test"
echo "=========================================="
