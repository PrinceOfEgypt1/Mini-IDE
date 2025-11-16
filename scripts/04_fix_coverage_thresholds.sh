#!/usr/bin/env bash
################################################################################
# Script: 04_fix_coverage_thresholds.sh
# Objetivo: Corrigir configuração de thresholds para ENFORÇAR bloqueio
# HU: HU-Quality-Coverage-Thresholds (correção)
# 
# Problema identificado:
#   - Os thresholds configurados no script anterior NÃO estão bloqueando
#   - pnpm test -- --coverage passou mesmo com server em 82% (threshold: 90%)
#   - analysis-agent em 11% e cli em 55% (threshold: 80%)
#
# Arquivos afetados:
#   - packages/shared/vitest.config.ts (MODIFY - adicionar thresholdAutoUpdate)
#   - packages/server/vitest.config.ts (MODIFY - adicionar thresholdAutoUpdate)
#   - packages/analysis-agent/vitest.config.ts (CREATE - enforçar 80%)
#   - packages/cli/vitest.config.ts (CREATE - enforçar 80%)
#
# Assumções:
#   - Vitest está instalado e configurado
#   - Testes existem mas coverage está abaixo dos thresholds
#
# Riscos:
#   - pnpm test -- --coverage DEVE falhar após essa correção (esperado!)
#   - Será necessário aumentar cobertura de testes OU ajustar thresholds
#
# Como reverter:
#   - git checkout packages/*/vitest.config.ts
################################################################################

set -euo pipefail

echo "[info] Iniciando correção de coverage thresholds..."

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[error] Execute este script a partir da raiz do projeto Mini-IDE"
  exit 1
fi

################################################################################
# 1. Corrigir packages/shared/vitest.config.ts
################################################################################

echo "[info] Corrigindo packages/shared/vitest.config.ts..."

cat > packages/shared/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false, // CRITICAL: impede atualização automática
        perFile: false,     // threshold global, não por arquivo
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
EOF

echo "[ok] packages/shared/vitest.config.ts corrigido"

################################################################################
# 2. Corrigir packages/server/vitest.config.ts
################################################################################

echo "[info] Corrigindo packages/server/vitest.config.ts..."

cat > packages/server/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false, // CRITICAL: impede atualização automática
        perFile: false,     // threshold global, não por arquivo
        lines: 90,
        functions: 90,
        branches: 90,
        statements: 90,
      },
    },
  },
});
EOF

echo "[ok] packages/server/vitest.config.ts corrigido"

################################################################################
# 3. Criar packages/analysis-agent/vitest.config.ts
################################################################################

echo "[info] Criando packages/analysis-agent/vitest.config.ts..."

cat > packages/analysis-agent/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false,
        perFile: false,
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
EOF

echo "[ok] packages/analysis-agent/vitest.config.ts criado"

################################################################################
# 4. Criar packages/cli/vitest.config.ts
################################################################################

echo "[info] Criando packages/cli/vitest.config.ts..."

cat > packages/cli/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false,
        perFile: false,
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
EOF

echo "[ok] packages/cli/vitest.config.ts criado"

################################################################################
# 5. Criar packages/ui/vitest.config.ts (já tem 100% mas precisa de config)
################################################################################

echo "[info] Criando packages/ui/vitest.config.ts..."

cat > packages/ui/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/**',
        'dist/**',
        '**/*.spec.ts',
        '**/*.test.ts',
        '**/test/**',
        '**/__tests__/**',
      ],
      thresholds: {
        autoUpdate: false,
        perFile: false,
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
EOF

echo "[ok] packages/ui/vitest.config.ts criado"

################################################################################
# 6. Validação e avisos importantes
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[ok] Correção de coverage thresholds concluída!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Arquivos corrigidos/criados:"
echo "  ✓ packages/shared/vitest.config.ts"
echo "  ✓ packages/server/vitest.config.ts"
echo "  ✓ packages/analysis-agent/vitest.config.ts"
echo "  ✓ packages/cli/vitest.config.ts"
echo "  ✓ packages/ui/vitest.config.ts"
echo ""
echo "⚠️  ATENÇÃO CRÍTICA:"
echo ""
echo "  Os thresholds agora estão ENFORÇADOS corretamente."
echo "  Baseado no log anterior, os seguintes pacotes FALHARÃO:"
echo ""
echo "    • server:          82% atual vs 90% threshold"
echo "    • analysis-agent:  11% atual vs 80% threshold"
echo "    • cli:             55% atual vs 80% threshold"
echo ""
echo "  Isso é ESPERADO e CORRETO - é o comportamento desejado!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Testar que os thresholds agora BLOQUEIAM:"
echo "     pnpm test -- --coverage"
echo ""
echo "  2. Escolher uma estratégia:"
echo ""
echo "     OPÇÃO A - Ajustar thresholds temporariamente"
echo "     (para fazer a pipeline passar enquanto aumenta coverage gradualmente)"
echo ""
echo "       • server: reduzir de 90% para 82%"
echo "       • analysis-agent: reduzir de 80% para 15%"
echo "       • cli: reduzir de 80% para 55%"
echo ""
echo "     OPÇÃO B - Aumentar cobertura imediatamente"
echo "     (criar mais testes para atingir os thresholds definidos)"
echo ""
echo "       • Focar primeiro em server (mais crítico)"
echo "       • Depois analysis-agent e cli"
echo ""
echo "  3. Após decisão, validar pipeline completa:"
echo "     pnpm lint"
echo "     pnpm test"
echo "     pnpm typecheck"
echo "     pnpm build"
echo "     bash ./42_pipeline_checklist.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
