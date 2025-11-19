#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11a_fix_eslint_ui.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Corrigir configuração ESLint do pacote @mini-ide/ui para flat config (v9+)
#
# Problema identificado:
#   - ESLint v9+ usa flat config (eslint.config.js)
#   - Script de lint estava usando --ext (sintaxe antiga v8)
#   - Havia .eslintrc.cjs (formato antigo) em vez de eslint.config.js
#
# Arquivos modificados:
#   - packages/ui/package.json (atualizar script de lint)
#   - packages/ui/eslint.config.js (criar flat config correto)
#   - packages/ui/.eslintrc.cjs (remover formato antigo)
#
# Como reverter:
#   git restore packages/ui/package.json packages/ui/eslint.config.js
#   git checkout packages/ui/.eslintrc.cjs
#
################################################################################

echo "[info] Corrigindo configuração ESLint do pacote @mini-ide/ui..."

# 1. Remover .eslintrc.cjs antigo
if [ -f packages/ui/.eslintrc.cjs ]; then
  echo "[info] Removendo .eslintrc.cjs (formato antigo)..."
  rm packages/ui/.eslintrc.cjs
  echo "[ok] .eslintrc.cjs removido"
fi

# 2. Criar eslint.config.js (flat config para TypeScript + React)
cat <<'EOF' > packages/ui/eslint.config.js
import js from '@eslint/js';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import reactHooksPlugin from 'eslint-plugin-react-hooks';
import reactRefreshPlugin from 'eslint-plugin-react-refresh';

export default [
  {
    ignores: ['dist/**', 'coverage/**', '*.config.ts', '*.config.js'],
  },
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: {
          jsx: true,
        },
      },
      globals: {
        console: 'readonly',
        document: 'readonly',
        window: 'readonly',
        fetch: 'readonly',
        setTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        URL: 'readonly',
      },
    },
    plugins: {
      '@typescript-eslint': tsPlugin,
      'react-hooks': reactHooksPlugin,
      'react-refresh': reactRefreshPlugin,
    },
    rules: {
      ...js.configs.recommended.rules,
      ...tsPlugin.configs.recommended.rules,
      ...reactHooksPlugin.configs.recommended.rules,
      'react-refresh/only-export-components': [
        'warn',
        { allowConstantExport: true },
      ],
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_' },
      ],
      'no-console': 'off',
    },
  },
];
EOF

echo "[ok] eslint.config.js criado (flat config)"

# 3. Atualizar package.json - remover --ext e outras flags antigas
cat <<'EOF' > packages/ui/package.json
{
  "name": "@mini-ide/ui",
  "version": "1.0.17",
  "type": "module",
  "private": true,
  "description": "Interface web da Mini-IDE - conexão com backend via /healthz e /analyze",
  "scripts": {
    "dev": "vite",
    "build": "tsc -p tsconfig.build.json && vite build",
    "preview": "vite preview",
    "lint": "eslint .",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "typecheck": "tsc --noEmit -p tsconfig.json"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@eslint/js": "^9.0.0",
    "@testing-library/jest-dom": "^6.1.5",
    "@testing-library/react": "^14.1.2",
    "@testing-library/user-event": "^14.5.1",
    "@types/node": "^20.10.5",
    "@types/react": "^18.2.45",
    "@types/react-dom": "^18.2.18",
    "@typescript-eslint/eslint-plugin": "^7.0.0",
    "@typescript-eslint/parser": "^7.0.0",
    "@vitejs/plugin-react": "^4.2.1",
    "@vitest/coverage-v8": "^1.1.0",
    "eslint": "^9.0.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "jsdom": "^23.0.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.8",
    "vitest": "^1.1.0"
  }
}
EOF

echo "[ok] package.json atualizado (script de lint simplificado)"

echo ""
echo "============================================================"
echo "✅ CORREÇÃO CONCLUÍDA"
echo "============================================================"
echo ""
echo "Mudanças aplicadas:"
echo "  ✅ Removido .eslintrc.cjs (formato antigo)"
echo "  ✅ Criado eslint.config.js (flat config v9+)"
echo "  ✅ Atualizado package.json:"
echo "     - lint: 'eslint .' (sem --ext, --report-unused-disable-directives)"
echo "     - Versões de ESLint atualizadas para v9+"
echo ""
echo "Próximos passos:"
echo ""
echo "1. Reinstalar dependências:"
echo "   pnpm install"
echo ""
echo "2. Testar lint novamente:"
echo "   pnpm --filter @mini-ide/ui lint"
echo ""
echo "3. Se houver warnings de imports '.js' em arquivos .tsx:"
echo "   Isso é esperado por causa do NodeNext/ESM"
echo "   Pode ignorar ou adicionar regra no eslint.config.js"
echo ""
echo "4. Validar pipeline completa:"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui test"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "============================================================"
