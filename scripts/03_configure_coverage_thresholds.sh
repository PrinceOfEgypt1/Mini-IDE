#!/usr/bin/env bash
################################################################################
# Script: 03_configure_coverage_thresholds.sh
# Objetivo: Configurar thresholds de cobertura de testes (Vitest) no Mini-IDE
# HU: HU-Quality-Coverage-Thresholds
# 
# Arquivos afetados:
#   - packages/shared/vitest.config.ts (CREATE/MODIFY)
#   - packages/server/vitest.config.ts (CREATE/MODIFY)
#   - scripts/coverage-report.sh (CREATE)
#   - DEVELOPMENT.md (MODIFY)
#
# Assumções:
#   - Projeto usa Vitest para testes
#   - Estrutura monorepo PNPM com packages/shared e packages/server
#   - DEVELOPMENT.md existe na raiz
#
# Riscos:
#   - Pode quebrar testes se cobertura atual < thresholds configurados
#   - Validação final necessária com `pnpm test`
#
# Como reverter:
#   - git checkout packages/shared/vitest.config.ts
#   - git checkout packages/server/vitest.config.ts
#   - rm scripts/coverage-report.sh
#   - git checkout DEVELOPMENT.md
################################################################################

set -euo pipefail

echo "[info] Iniciando configuração de coverage thresholds..."

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[error] Execute este script a partir da raiz do projeto Mini-IDE"
  exit 1
fi

################################################################################
# 1. Configurar packages/shared/vitest.config.ts
################################################################################

echo "[info] Configurando packages/shared/vitest.config.ts..."

mkdir -p packages/shared

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
        global: {
          lines: 80,
          functions: 80,
          branches: 80,
          statements: 80,
        },
      },
    },
  },
});
EOF

echo "[ok] packages/shared/vitest.config.ts configurado"

################################################################################
# 2. Configurar packages/server/vitest.config.ts
################################################################################

echo "[info] Configurando packages/server/vitest.config.ts..."

mkdir -p packages/server

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
        global: {
          lines: 90,
          functions: 90,
          branches: 90,
          statements: 90,
        },
      },
    },
  },
});
EOF

echo "[ok] packages/server/vitest.config.ts configurado"

################################################################################
# 3. Criar scripts/coverage-report.sh
################################################################################

echo "[info] Criando scripts/coverage-report.sh..."

mkdir -p scripts

cat > scripts/coverage-report.sh << 'EOF'
#!/usr/bin/env bash
################################################################################
# Script: coverage-report.sh
# Objetivo: Executar testes com coverage e abrir relatório HTML
# Uso: bash scripts/coverage-report.sh
################################################################################

set -euo pipefail

echo "[info] Executando testes com cobertura..."

# Executar testes com coverage em todos os pacotes
pnpm test -- --coverage

echo "[ok] Testes com cobertura concluídos"
echo "[info] Relatórios de cobertura gerados:"
echo "  - packages/shared/coverage/index.html"
echo "  - packages/server/coverage/index.html"
echo "  - packages/analysis-agent/coverage/index.html (se existir)"
echo "  - packages/cli/coverage/index.html (se existir)"

# Detectar SO e abrir relatório no browser
if [[ -f "packages/server/coverage/index.html" ]]; then
  echo "[info] Abrindo relatório do servidor no browser..."
  
  if command -v xdg-open > /dev/null; then
    # Linux
    xdg-open packages/server/coverage/index.html
  elif command -v open > /dev/null; then
    # macOS
    open packages/server/coverage/index.html
  elif command -v start > /dev/null; then
    # Windows (Git Bash/WSL)
    start packages/server/coverage/index.html
  else
    echo "[warn] Não foi possível detectar comando para abrir browser"
    echo "[info] Abra manualmente: packages/server/coverage/index.html"
  fi
else
  echo "[warn] Relatório do servidor não encontrado"
fi

echo "[ok] Processo de coverage concluído"
EOF

chmod +x scripts/coverage-report.sh

echo "[ok] scripts/coverage-report.sh criado e tornado executável"

################################################################################
# 4. Atualizar DEVELOPMENT.md
################################################################################

echo "[info] Atualizando DEVELOPMENT.md..."

# Verificar se seção de testes já existe
if ! grep -q "## 4. Testes automatizados" DEVELOPMENT.md; then
  echo "[error] Seção de testes não encontrada em DEVELOPMENT.md"
  echo "[warn] Será necessário adicionar manualmente a documentação de coverage"
else
  # Criar backup
  cp DEVELOPMENT.md DEVELOPMENT.md.bak
  
  # Adicionar seção de coverage após "## 4. Testes automatizados"
  # Vamos fazer isso de forma mais segura com um script Python/awk inline
  
  # Por simplicidade, vamos adicionar ao final da seção 4
  awk '
    /^## 4\. Testes automatizados/ { in_section=1 }
    /^## 5\./ { 
      if (in_section) {
        print ""
        print "**4.3 Cobertura de testes (Coverage)**"
        print ""
        print "O projeto utiliza thresholds mínimos de cobertura configurados no Vitest:"
        print ""
        print "- **Global (shared, cli, etc.):** 80% (lines, functions, branches, statements)"
        print "- **Server (código crítico):** 90% (lines, functions, branches, statements)"
        print ""
        print "Comandos de cobertura:"
        print ""
        print "```bash"
        print "# Executar testes com cobertura em todos os pacotes"
        print "pnpm test -- --coverage"
        print ""
        print "# Gerar relatório HTML e abrir no browser"
        print "bash scripts/coverage-report.sh"
        print ""
        print "# Executar cobertura em pacote específico"
        print "pnpm --filter @mini-ide/server test -- --coverage"
        print "```"
        print ""
        print "**Thresholds configurados:**"
        print ""
        print "- Se a cobertura ficar abaixo do threshold, o comando `pnpm test -- --coverage` **falhará**"
        print "- Isso garante que commits não reduzam a qualidade do código"
        print "- Relatórios HTML são gerados em `packages/<nome>/coverage/index.html`"
        print ""
        in_section=0
      }
    }
    { print }
  ' DEVELOPMENT.md.bak > DEVELOPMENT.md.tmp
  
  mv DEVELOPMENT.md.tmp DEVELOPMENT.md
  rm DEVELOPMENT.md.bak
  
  echo "[ok] DEVELOPMENT.md atualizado com documentação de coverage"
fi

################################################################################
# 5. Validação final
################################################################################

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[ok] Configuração de coverage thresholds concluída!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Arquivos criados/modificados:"
echo "  ✓ packages/shared/vitest.config.ts (threshold: 80%)"
echo "  ✓ packages/server/vitest.config.ts (threshold: 90%)"
echo "  ✓ scripts/coverage-report.sh (executável)"
echo "  ✓ DEVELOPMENT.md (seção de coverage adicionada)"
echo ""
echo "Próximos passos:"
echo ""
echo "  1. Validar configuração:"
echo "     pnpm test -- --coverage"
echo ""
echo "  2. Se testes falharem por coverage insuficiente:"
echo "     - Adicione mais testes para atingir os thresholds"
echo "     - Ou ajuste temporariamente os thresholds nos arquivos vitest.config.ts"
echo ""
echo "  3. Gerar relatório HTML:"
echo "     bash scripts/coverage-report.sh"
echo ""
echo "  4. Após validação bem-sucedida, executar pipeline completa:"
echo "     pnpm lint"
echo "     pnpm test"
echo "     pnpm typecheck"
echo "     pnpm build"
echo "     bash ./42_pipeline_checklist.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
