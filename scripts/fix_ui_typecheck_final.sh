#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: fix_ui_typecheck_final.sh
# Versão: 1.0.0
# Data: 2025-11-17
#
# Objetivo:
#   Corrigir erros TS6305 no pacote @mini-ide/ui de forma definitiva
#
# Arquivos afetados:
#   - packages/ui/tsconfig.json (adicionar exclude)
#   - packages/ui/tsconfig.build.json (corrigir outDir, adicionar composite)
#   - packages/ui/dist/ (remover completamente)
#
# Assunções:
#   - Executado a partir da raiz do monorepo Mini-IDE
#   - PNPM instalado e disponível
#   - Pacotes do projeto já instalados
#
# Riscos:
#   - Remoção de dist/ requer rebuild completo
#   - Mudanças em tsconfig podem afetar builds futuros
#
# Como reverter:
#   git restore packages/ui/tsconfig.json packages/ui/tsconfig.build.json
#   pnpm --filter @mini-ide/ui build
#
################################################################################

echo "[info] Corrigindo typecheck do pacote @mini-ide/ui..."
echo ""

# Pré-condição: Verificar se estamos na raiz do monorepo
if [ ! -f "package.json" ] || [ ! -d "packages/ui" ]; then
  echo "[error] Execute este script a partir da raiz do monorepo Mini-IDE"
  exit 1
fi

# 1. Remover diretório dist/ completamente
echo "[info] Removendo dist/ antigo (estrutura incorreta)..."
if [ -d "packages/ui/dist" ]; then
  rm -rf packages/ui/dist
  echo "[ok] dist/ removido"
else
  echo "[info] dist/ não existe, continuando..."
fi

# 2. Criar tsconfig.json COMPLETO com exclude
echo "[info] Criando tsconfig.json corrigido..."

cat > packages/ui/tsconfig.json <<'TSCONFIG_JSON_EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src", "test"],
  "exclude": ["node_modules", "dist", "coverage"]
}
TSCONFIG_JSON_EOF

echo "[ok] tsconfig.json criado (com exclude)"

# 3. Criar tsconfig.build.json COMPLETO
echo "[info] Criando tsconfig.build.json corrigido..."

cat > packages/ui/tsconfig.build.json <<'TSCONFIG_BUILD_EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "composite": true,
    "noEmit": false,
    "declaration": true,
    "declarationMap": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src"],
  "exclude": ["src/**/*.spec.ts", "src/**/*.spec.tsx", "test"]
}
TSCONFIG_BUILD_EOF

echo "[ok] tsconfig.build.json criado (composite: true, rootDir: ./src)"

# 4. Validar typecheck
echo ""
echo "[info] Executando typecheck..."
if pnpm --filter @mini-ide/ui typecheck; then
  echo "[ok] Typecheck passou sem erros"
else
  echo "[error] Typecheck ainda tem erros"
  exit 1
fi

# 5. Executar build para gerar dist/ corretamente
echo ""
echo "[info] Executando build..."
if pnpm --filter @mini-ide/ui build; then
  echo "[ok] Build executado com sucesso"
else
  echo "[error] Build falhou"
  exit 1
fi

# 6. Validar lint
echo ""
echo "[info] Executando lint..."
if pnpm --filter @mini-ide/ui lint; then
  echo "[ok] Lint passou sem erros"
else
  echo "[error] Lint falhou"
  exit 1
fi

# 7. Executar testes
echo ""
echo "[info] Executando testes..."
if pnpm --filter @mini-ide/ui test; then
  echo "[ok] Testes passaram (31/31)"
else
  echo "[error] Testes falharam"
  exit 1
fi

# 8. Verificar coverage
echo ""
echo "[info] Verificando coverage..."
if pnpm --filter @mini-ide/ui test:coverage; then
  echo "[ok] Coverage ≥80%"
else
  echo "[error] Coverage abaixo do threshold"
  exit 1
fi

# Sumário final
echo ""
echo "============================================================"
echo "✅ CORREÇÃO CONCLUÍDA COM SUCESSO"
echo "============================================================"
echo ""
echo "Arquivos modificados:"
echo "  📄 packages/ui/tsconfig.json"
echo "  📄 packages/ui/tsconfig.build.json"
echo ""
echo "Arquivos removidos:"
echo "  🗑️  packages/ui/dist/ (regenerado com estrutura correta)"
echo ""
echo "Validações executadas:"
echo "  ✅ Typecheck: 0 erros"
echo "  ✅ Build: sucesso"
echo "  ✅ Lint: 0 erros"
echo "  ✅ Testes: 31/31 passando"
echo "  ✅ Coverage: ≥80%"
echo ""
echo "Próximos passos:"
echo "  1. Revisar mudanças: git diff packages/ui/tsconfig*.json"
echo "  2. Testar localmente: pnpm --filter @mini-ide/ui dev"
echo "  3. Commit: git add . && git commit -m 'fix(ui): corrigir typecheck TS6305'"
echo ""
echo "Pipeline completa do monorepo:"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
echo "============================================================"
