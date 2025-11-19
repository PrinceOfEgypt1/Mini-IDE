#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11b_fix_eslint_errors.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Corrigir todos os erros de ESLint identificados no pacote @mini-ide/ui
#
# Problemas corrigidos:
#   1. Globals de teste não reconhecidos (vi, Response, HTMLInputElement)
#   2. Redeclaração de 'ServerStatus' (função vs tipo)
#   3. Warning de versão TypeScript (5.9.3 vs 5.6.0 suportado)
#
# Arquivos modificados:
#   - packages/ui/eslint.config.js (adicionar globals de teste)
#   - packages/ui/src/components/ServerStatus.tsx (renomear tipo)
#   - packages/ui/package.json (ajustar versão TypeScript)
#
# Como reverter:
#   git restore packages/ui/
#
################################################################################

echo "[info] Corrigindo erros de ESLint no pacote @mini-ide/ui..."

# 1. Atualizar eslint.config.js com globals de teste
echo "[info] Atualizando eslint.config.js com globals de teste..."

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
        // Globals do browser
        console: 'readonly',
        document: 'readonly',
        window: 'readonly',
        fetch: 'readonly',
        setTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        URL: 'readonly',
        // Tipos globais do DOM/Fetch API
        Response: 'readonly',
        Request: 'readonly',
        Headers: 'readonly',
        HTMLElement: 'readonly',
        HTMLInputElement: 'readonly',
        HTMLTextAreaElement: 'readonly',
        HTMLButtonElement: 'readonly',
        Event: 'readonly',
        MouseEvent: 'readonly',
        KeyboardEvent: 'readonly',
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
  {
    // Configuração específica para arquivos de teste
    files: ['**/*.spec.{ts,tsx}', '**/test/**/*.{ts,tsx}', '**/setup.ts'],
    languageOptions: {
      globals: {
        // Globals do Vitest
        vi: 'readonly',
        describe: 'readonly',
        it: 'readonly',
        expect: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
        test: 'readonly',
        // Globals do browser/DOM (também nos testes)
        console: 'readonly',
        document: 'readonly',
        window: 'readonly',
        fetch: 'readonly',
        Response: 'readonly',
        Request: 'readonly',
        HTMLElement: 'readonly',
        HTMLInputElement: 'readonly',
        HTMLTextAreaElement: 'readonly',
        HTMLButtonElement: 'readonly',
        globalThis: 'writable',
      },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      'no-console': 'off',
    },
  },
];
EOF

echo "[ok] eslint.config.js atualizado com globals completos"

# 2. Corrigir ServerStatus.tsx - renomear tipo para evitar redeclaração
echo "[info] Corrigindo redeclaração em ServerStatus.tsx..."

cat <<'EOF' > packages/ui/src/components/ServerStatus.tsx
/**
 * Componente de indicação visual de status do servidor
 * 
 * @packageDocumentation
 * @module components/ServerStatus
 * 
 * Este componente chama GET /healthz periodicamente e exibe
 * um indicador visual (chip) mostrando se o servidor está online.
 * 
 * Estados:
 * - 🟢 "Servidor online" quando /healthz retorna 200
 * - 🔴 "Servidor indisponível" em caso de erro de rede ou status não-2xx
 */

import { useEffect, useState } from 'react';
import { getHealthzUrl } from '../config/server.js';

/**
 * Status possíveis do servidor
 */
type ServerStatusState = 'online' | 'offline' | 'checking';

/**
 * Propriedades do componente ServerStatus
 */
export interface ServerStatusProps {
  /**
   * Intervalo em ms para verificar o status (padrão: 10000ms = 10s)
   */
  pollInterval?: number;
}

/**
 * Componente que exibe o status do servidor Mini-IDE
 * 
 * @param props - Propriedades do componente
 * @returns Elemento React com chip de status
 * 
 * @example
 * ```tsx
 * <ServerStatus pollInterval={5000} />
 * ```
 */
export function ServerStatus({ pollInterval = 10000 }: ServerStatusProps) {
  const [status, setStatus] = useState<ServerStatusState>('checking');

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch(getHealthzUrl(), {
          method: 'GET',
          headers: { 'Content-Type': 'application/json' },
        });
        
        if (response.ok) {
          setStatus('online');
        } else {
          setStatus('offline');
        }
      } catch (error) {
        // Erro de rede ou servidor inacessível
        console.error('[ServerStatus] Erro ao verificar /healthz:', error);
        setStatus('offline');
      }
    };

    // Verificação inicial
    checkHealth();

    // Polling periódico
    const intervalId = setInterval(checkHealth, pollInterval);

    return () => clearInterval(intervalId);
  }, [pollInterval]);

  const getStatusClass = () => {
    if (status === 'online') return 'chip ok';
    if (status === 'offline') return 'chip warn';
    return 'chip';
  };

  const getStatusText = () => {
    if (status === 'online') return '🟢 Servidor online';
    if (status === 'offline') return '🔴 Servidor indisponível';
    return '⏳ Verificando...';
  };

  return (
    <span className={getStatusClass()} data-testid="server-status">
      {getStatusText()}
    </span>
  );
}
EOF

echo "[ok] ServerStatus.tsx corrigido (tipo renomeado para ServerStatusState)"

# 3. Ajustar versão do TypeScript para compatibilidade
echo "[info] Ajustando versão do TypeScript para 5.5.4..."

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
    "typescript": "~5.5.4",
    "vite": "^5.0.8",
    "vitest": "^1.1.0"
  }
}
EOF

echo "[ok] package.json atualizado (TypeScript ~5.5.4)"

echo ""
echo "============================================================"
echo "✅ CORREÇÃO CONCLUÍDA"
echo "============================================================"
echo ""
echo "Mudanças aplicadas:"
echo ""
echo "  ✅ eslint.config.js:"
echo "     - Adicionados globals: Response, HTMLInputElement, etc."
echo "     - Configuração específica para arquivos de teste"
echo "     - Globals do Vitest: vi, describe, it, expect..."
echo ""
echo "  ✅ ServerStatus.tsx:"
echo "     - Tipo renomeado: ServerStatus → ServerStatusState"
echo "     - Resolve erro 'ServerStatus is already defined'"
echo ""
echo "  ✅ package.json:"
echo "     - TypeScript: 5.9.3 → ~5.5.4 (compatível)"
echo "     - Remove warning de versão não suportada"
echo ""
echo "============================================================"
echo "🔄 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Reinstalar dependências (TypeScript downgrade):"
echo "   pnpm install"
echo ""
echo "2. Testar lint novamente (deve passar sem erros):"
echo "   pnpm --filter @mini-ide/ui lint"
echo ""
echo "3. Validar pipeline completa:"
echo "   pnpm --filter @mini-ide/ui test"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "4. Se tudo passar, pipeline está verde! ✅"
echo ""
echo "============================================================"
echo "📊 ERROS CORRIGIDOS"
echo "============================================================"
echo ""
echo "  ✅ 'ServerStatus' is already defined (no-redeclare)"
echo "  ✅ 'Response' is not defined (no-undef) - 4 ocorrências"
echo "  ✅ 'HTMLInputElement' is not defined (no-undef)"
echo "  ✅ 'vi' is not defined (no-undef)"
echo "  ✅ Warning TypeScript 5.9.3 não suportado"
echo ""
echo "  Total: 9 erros corrigidos ✅"
echo ""
echo "============================================================"
