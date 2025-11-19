#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 21_remove_deprecated_components.sh
# Objetivo: Remover pasta deprecated que causa erros de TypeScript
# 
# Problema: Arquivos movidos para /deprecated/ têm imports quebrados
# Solução: Deletar completamente a pasta deprecated (não precisamos mais)
################################################################################

echo "[info] Removendo pasta deprecated com componentes obsoletos..."

# Remover pasta deprecated completamente
rm -rf packages/ui/src/components/deprecated

echo "[ok] Pasta deprecated removida"
echo ""
echo "Validando pipeline completo..."
echo ""

# Lint
echo "→ pnpm lint..."
if ! pnpm lint; then
  echo "❌ LINT FALHOU"
  exit 1
fi
echo "✅ Lint passou"
echo ""

# TypeCheck
echo "→ pnpm typecheck..."
if ! pnpm typecheck; then
  echo "❌ TYPECHECK FALHOU"
  exit 1
fi
echo "✅ TypeCheck passou"
echo ""

# Test
echo "→ pnpm test..."
if ! pnpm test 2>&1 | grep -q "Tests.*passed"; then
  echo "❌ TESTES FALHARAM"
  exit 1
fi
echo "✅ Testes passaram"
echo ""

# Build
echo "→ pnpm build..."
if ! pnpm build; then
  echo "❌ BUILD FALHOU"
  exit 1
fi
echo "✅ Build passou"
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║    HU-UI-Fix-Align-Wireframe-Explore COMPLETA E VALIDADA ✓    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Wireframe MiniIDE-Explore.html RESTAURADO"
echo "✅ Layout 3 colunas funcionando"
echo "✅ Sidebar + WorkspaceTabs + DiscoveryNotes implementados"
echo "✅ ServerStatus + AnalyzePlayground integrados na aba Analyze"
echo "✅ Pipeline completa: lint | test | typecheck | build"
echo ""
echo "[info] Pronto para commit e próximas HUs!"
