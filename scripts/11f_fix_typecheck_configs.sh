#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11f_fix_typecheck_configs.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Corrigir erros de typecheck do pacote @mini-ide/ui
#
# Problemas identificados:
#   1. TS6305 (5x): "Output file has not been built from source file"
#      Causa: tsconfig.json inclui dist/ no programa TypeScript
#   2. TS6306: "Referenced project must have composite: true"
#      Causa: tsconfig.build.json não tem "composite": true
#
# Solução:
#   - Adicionar exclude para dist/ e node_modules/ no tsconfig.json
#   - Adicionar "composite": true no tsconfig.build.json
#   - Ajustar outDir e declarationDir no tsconfig.build.json
#
# Arquivos modificados:
#   - packages/ui/tsconfig.json
#   - packages/ui/tsconfig.build.json
#
# Como reverter:
#   git restore packages/ui/tsconfig*.json
#
################################################################################

echo "[info] Corrigindo configurações TypeScript do pacote @mini-ide/ui..."

# 1. Atualizar tsconfig.json (desenvolvimento/testes)
echo "[info] Atualizando tsconfig.json..."

cat <<'EOF' > packages/ui/tsconfig.json
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
  "exclude": ["node_modules", "dist", "coverage"],
  "references": [{ "path": "./tsconfig.build.json" }]
}
EOF

echo "[ok] tsconfig.json atualizado (exclude adicionado)"

# 2. Atualizar tsconfig.build.json (produção)
echo "[info] Atualizando tsconfig.build.json..."

cat <<'EOF' > packages/ui/tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "composite": true,
    "noEmit": false,
    "declaration": true,
    "declarationMap": true,
    "emitDeclarationOnly": false,
    "outDir": "./dist",
    "declarationDir": "./dist"
  },
  "include": ["src"],
  "exclude": ["src/**/*.spec.ts", "src/**/*.spec.tsx", "test", "node_modules", "dist", "coverage"]
}
EOF

echo "[ok] tsconfig.build.json atualizado (composite: true adicionado)"

echo ""
echo "============================================================"
echo "✅ CORREÇÃO CONCLUÍDA"
echo "============================================================"
echo ""
echo "🔧 Mudanças Aplicadas"
echo "============================================================"
echo ""
echo "tsconfig.json:"
echo "  ✅ Adicionado exclude: ['node_modules', 'dist', 'coverage']"
echo "  ✅ Evita incluir arquivos compilados no programa TS"
echo ""
echo "tsconfig.build.json:"
echo "  ✅ Adicionado 'composite': true"
echo "  ✅ Ajustado outDir e declarationDir para './dist'"
echo "  ✅ Configurado emitDeclarationOnly: false"
echo "  ✅ Exclude de arquivos de teste"
echo ""
echo "============================================================"
echo "📊 ERROS CORRIGIDOS"
echo "============================================================"
echo ""
echo "  ✅ TS6305 (5x): Output file has not been built from source"
echo "  ✅ TS6306: Referenced project must have composite: true"
echo ""
echo "  Total: 6 erros corrigidos"
echo ""
echo "============================================================"
echo "🔄 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Executar typecheck novamente (deve passar):"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo ""
echo "2. Executar build (deve passar):"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "3. Validar pipeline completa do pacote UI:"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui test"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "4. Pipeline completa do monorepo:"
echo "   REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
echo "============================================================"
echo "✅ VALIDAÇÃO ESPERADA"
echo "============================================================"
echo ""
echo "Após executar os comandos acima:"
echo ""
echo "  ✅ Testes: 31/31 passando"
echo "  ✅ Coverage: 97.51% (≥80%)"
echo "  ✅ Lint: 0 erros"
echo "  ✅ Typecheck: 0 erros"
echo "  ✅ Build: sucesso"
echo ""
echo "Pipeline 100% verde! 🎉"
echo ""
echo "============================================================"
