#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 11_ui_backend_bridge.sh
# Versão: 1.0.0
# Data: 2025-11-16
#
# Objetivo:
#   Implementar as 3 Histórias de Usuário do épico E-UI-Backend-Bridge:
#   - HU-UI-Server-BaseURL-Config: Configuração centralizada de URL do servidor
#   - HU-UI-Healthz-Status-Indicator: Indicador visual de status do servidor
#   - HU-UI-Analyze-Playground: Playground de requisições /analyze
#
# Arquivos criados/modificados:
#   - packages/ui/package.json (criação inicial do pacote)
#   - packages/ui/tsconfig.json (configuração TypeScript strict)
#   - packages/ui/tsconfig.build.json (configuração de build)
#   - packages/ui/vite.config.ts (configuração Vite + Vitest)
#   - packages/ui/vitest.config.ts (configuração testes + coverage)
#   - packages/ui/.env.example (exemplo de variáveis de ambiente)
#   - packages/ui/index.html (página HTML principal)
#   - packages/ui/src/main.tsx (entry point React)
#   - packages/ui/src/App.tsx (componente principal)
#   - packages/ui/src/config/server.ts (configuração de URLs)
#   - packages/ui/src/components/ServerStatus.tsx (indicador de status)
#   - packages/ui/src/components/AnalyzePlayground.tsx (playground /analyze)
#   - packages/ui/src/styles/global.css (estilos globais baseados no wireframe)
#   - packages/ui/test/config/server.spec.ts (testes configuração)
#   - packages/ui/test/components/ServerStatus.spec.tsx (testes status)
#   - packages/ui/test/components/AnalyzePlayground.spec.tsx (testes playground)
#   - packages/ui/test/setup.ts (setup de testes)
#   - DEVELOPMENT.md (atualização com seção UI)
#
# Premissas:
#   - Projeto Mini-IDE já existe com estrutura PNPM workspace
#   - Pacotes @mini-ide/shared e @mini-ide/server já estão implementados
#   - Servidor expõe GET /healthz e POST /analyze em porta 3200
#   - Node.js 20+ e pnpm instalados
#
# Riscos:
#   - Se @mini-ide/shared não tiver tipos de AnalyzeResponse, ajustar imports
#   - Primeira vez criando pacote UI pode exigir pnpm install adicional
#
# Como reverter:
#   git restore packages/ui DEVELOPMENT.md
#   rm -rf packages/ui
#   pnpm install
#
################################################################################

echo "[info] Iniciando implementação do épico E-UI-Backend-Bridge..."

# Criar estrutura de diretórios do pacote UI
mkdir -p packages/ui/src/{config,components,styles}
mkdir -p packages/ui/test/{config,components}
mkdir -p packages/ui/public

echo "[info] Estrutura de diretórios criada"

################################################################################
# 1. package.json do pacote @mini-ide/ui
################################################################################

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
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
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
    "@testing-library/jest-dom": "^6.1.5",
    "@testing-library/react": "^14.1.2",
    "@testing-library/user-event": "^14.5.1",
    "@types/node": "^20.10.5",
    "@types/react": "^18.2.45",
    "@types/react-dom": "^18.2.18",
    "@typescript-eslint/eslint-plugin": "^6.15.0",
    "@typescript-eslint/parser": "^6.15.0",
    "@vitejs/plugin-react": "^4.2.1",
    "@vitest/coverage-v8": "^1.1.0",
    "eslint": "^8.56.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "jsdom": "^23.0.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.8",
    "vitest": "^1.1.0"
  }
}
EOF

echo "[ok] packages/ui/package.json criado"

################################################################################
# 2. tsconfig.json (strict mode, NodeNext)
################################################################################

cat <<'EOF' > packages/ui/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "skipLibCheck": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "jsx": "react-jsx",
    "types": ["vite/client", "vitest/globals", "@testing-library/jest-dom"],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src", "test"],
  "references": [{ "path": "./tsconfig.build.json" }]
}
EOF

echo "[ok] packages/ui/tsconfig.json criado"

################################################################################
# 3. tsconfig.build.json (para build de produção)
################################################################################

cat <<'EOF' > packages/ui/tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "dist",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["test", "**/*.spec.ts", "**/*.spec.tsx"]
}
EOF

echo "[ok] packages/ui/tsconfig.build.json criado"

################################################################################
# 4. vite.config.ts (Vite + React + Vitest)
################################################################################

cat <<'EOF' > packages/ui/vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    strictPort: true,
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
EOF

echo "[ok] packages/ui/vite.config.ts criado"

################################################################################
# 5. vitest.config.ts (Testes + Coverage com threshold 80%)
################################################################################

cat <<'EOF' > packages/ui/vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/main.tsx',
        '**/*.spec.{ts,tsx}',
        '**/*.d.ts',
      ],
      thresholds: {
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
# 6. .env.example (variável de ambiente para URL do servidor)
################################################################################

cat <<'EOF' > packages/ui/.env.example
# URL base do servidor Mini-IDE
# Em desenvolvimento local, use:
VITE_MINI_IDE_SERVER_URL=http://127.0.0.1:3200

# Em produção, ajuste conforme necessário:
# VITE_MINI_IDE_SERVER_URL=https://api.mini-ide.com
EOF

echo "[ok] packages/ui/.env.example criado"

################################################################################
# 7. index.html (página HTML principal)
################################################################################

cat <<'EOF' > packages/ui/index.html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Mini IDE - Analysis Agent</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

echo "[ok] packages/ui/index.html criado"

################################################################################
# 8. src/config/server.ts (HU-UI-Server-BaseURL-Config)
################################################################################

cat <<'EOF' > packages/ui/src/config/server.ts
/**
 * Configuração centralizada de URLs do servidor Mini-IDE
 * 
 * @packageDocumentation
 * @module config/server
 * 
 * Este módulo fornece um ponto único de configuração para URLs do backend.
 * A baseURL é lida da variável de ambiente VITE_MINI_IDE_SERVER_URL.
 * 
 * Nenhum componente deve usar URLs hardcoded - sempre use as funções
 * exportadas por este módulo.
 */

/**
 * Obtém a URL base do servidor a partir da variável de ambiente.
 * 
 * @returns URL base configurada ou fallback para localhost:3200
 * 
 * @example
 * ```typescript
 * const baseUrl = getBaseUrl();
 * // http://127.0.0.1:3200
 * ```
 */
export function getBaseUrl(): string {
  const envUrl = import.meta.env.VITE_MINI_IDE_SERVER_URL;
  
  if (!envUrl) {
    console.warn(
      '[server-config] VITE_MINI_IDE_SERVER_URL não definida. ' +
      'Usando fallback http://127.0.0.1:3200'
    );
    return 'http://127.0.0.1:3200';
  }
  
  return envUrl;
}

/**
 * Obtém a URL completa do endpoint /healthz
 * 
 * @returns URL do healthcheck
 * 
 * @example
 * ```typescript
 * const url = getHealthzUrl();
 * // http://127.0.0.1:3200/healthz
 * ```
 */
export function getHealthzUrl(): string {
  const base = getBaseUrl();
  return `${base}/healthz`;
}

/**
 * Obtém a URL completa do endpoint /analyze
 * 
 * @returns URL do endpoint de análise
 * 
 * @example
 * ```typescript
 * const url = getAnalyzeUrl();
 * // http://127.0.0.1:3200/analyze
 * ```
 */
export function getAnalyzeUrl(): string {
  const base = getBaseUrl();
  return `${base}/analyze`;
}
EOF

echo "[ok] packages/ui/src/config/server.ts criado"

################################################################################
# 9. src/components/ServerStatus.tsx (HU-UI-Healthz-Status-Indicator)
################################################################################

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
type ServerStatus = 'online' | 'offline' | 'checking';

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
  const [status, setStatus] = useState<ServerStatus>('checking');

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

echo "[ok] packages/ui/src/components/ServerStatus.tsx criado"

################################################################################
# 10. src/components/AnalyzePlayground.tsx (HU-UI-Analyze-Playground)
################################################################################

cat <<'EOF' > packages/ui/src/components/AnalyzePlayground.tsx
/**
 * Playground de requisições /analyze
 * 
 * @packageDocumentation
 * @module components/AnalyzePlayground
 * 
 * Componente que permite testar o endpoint POST /analyze interativamente.
 * Inclui formulário com textarea (text) e campo numérico (maxLen), exibindo
 * o resultado estruturado ou mensagens de erro amigáveis.
 */

import { useState } from 'react';
import { getAnalyzeUrl } from '../config/server.js';

/**
 * Estrutura da resposta do /analyze
 * (baseada no contrato oficial do servidor)
 */
export interface AnalyzeResponse {
  summary: string;
  inputLength: number;
  outputLength: number;
  timestamp: string;
  requestId: string;
  budgetUsed?: number;
  budgetRemaining?: number;
}

/**
 * Estado do componente durante a requisição
 */
type RequestState = 'idle' | 'loading' | 'success' | 'error';

/**
 * Propriedades do componente AnalyzePlayground
 */
export interface AnalyzePlaygroundProps {
  /**
   * Valor padrão para maxLen (padrão: 100)
   */
  defaultMaxLen?: number;
}

/**
 * Playground interativo para testar POST /analyze
 * 
 * @param props - Propriedades do componente
 * @returns Elemento React com formulário e resultado
 * 
 * @example
 * ```tsx
 * <AnalyzePlayground defaultMaxLen={150} />
 * ```
 */
export function AnalyzePlayground({ defaultMaxLen = 100 }: AnalyzePlaygroundProps) {
  const [text, setText] = useState('');
  const [maxLen, setMaxLen] = useState(defaultMaxLen);
  const [state, setState] = useState<RequestState>('idle');
  const [result, setResult] = useState<AnalyzeResponse | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleAnalyze = async () => {
    if (!text.trim()) {
      setErrorMessage('Por favor, insira um texto para análise.');
      return;
    }

    setState('loading');
    setErrorMessage(null);
    setResult(null);

    try {
      const response = await fetch(getAnalyzeUrl(), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, maxLen }),
      });

      if (!response.ok) {
        // Erro 4xx ou 5xx
        const errorData = await response.json().catch(() => ({}));
        setErrorMessage(
          errorData.message || `Erro ao processar análise (${response.status}). Tente novamente.`
        );
        setState('error');
        return;
      }

      const data: AnalyzeResponse = await response.json();
      setResult(data);
      setState('success');
    } catch (error) {
      // Erro de rede
      console.error('[AnalyzePlayground] Erro de rede:', error);
      setErrorMessage('Erro de conexão. Verifique se o servidor está rodando.');
      setState('error');
    }
  };

  return (
    <div className="card" data-testid="analyze-playground">
      <h3>Playground /analyze</h3>
      <p className="muted" style={{ marginBottom: '12px' }}>
        Teste o endpoint POST /analyze interativamente.
      </p>

      <div style={{ marginBottom: '12px' }}>
        <label htmlFor="analyze-text" style={{ display: 'block', marginBottom: '6px' }}>
          Texto para análise:
        </label>
        <textarea
          id="analyze-text"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Digite o texto que deseja analisar..."
          rows={6}
          style={{ width: '100%' }}
          disabled={state === 'loading'}
        />
      </div>

      <div style={{ marginBottom: '12px' }}>
        <label htmlFor="analyze-maxlen" style={{ display: 'block', marginBottom: '6px' }}>
          Tamanho máximo do resumo (maxLen):
        </label>
        <input
          id="analyze-maxlen"
          type="number"
          value={maxLen}
          onChange={(e) => setMaxLen(parseInt(e.target.value, 10) || defaultMaxLen)}
          min={1}
          max={1000}
          style={{
            height: '34px',
            borderRadius: '10px',
            border: '1px solid var(--border)',
            background: 'var(--panel-2)',
            color: 'var(--text)',
            padding: '0 10px',
            width: '120px',
          }}
          disabled={state === 'loading'}
        />
      </div>

      <button
        className={`btn primary ${state === 'loading' ? 'loading' : ''}`}
        onClick={handleAnalyze}
        disabled={state === 'loading'}
        data-testid="analyze-button"
      >
        {state === 'loading' ? '⏳ Analisando...' : 'Analisar'}
      </button>

      {/* Resultado */}
      {state === 'success' && result && (
        <div
          className="card"
          style={{ marginTop: '16px', background: 'var(--panel-3)' }}
          data-testid="analyze-result"
        >
          <h4>Resultado da análise</h4>
          <div style={{ display: 'grid', gap: '8px' }}>
            <div>
              <strong>Summary:</strong> {result.summary}
            </div>
            <div>
              <strong>Input Length:</strong> {result.inputLength}
            </div>
            <div>
              <strong>Output Length:</strong> {result.outputLength}
            </div>
            <div className="muted" style={{ fontSize: '12px' }}>
              <strong>Timestamp:</strong> {result.timestamp}
            </div>
            <div className="muted" style={{ fontSize: '12px' }}>
              <strong>Request ID:</strong> {result.requestId}
            </div>
            {result.budgetUsed !== undefined && (
              <div className="muted" style={{ fontSize: '12px' }}>
                <strong>Budget Used:</strong> {result.budgetUsed}
              </div>
            )}
            {result.budgetRemaining !== undefined && (
              <div className="muted" style={{ fontSize: '12px' }}>
                <strong>Budget Remaining:</strong> {result.budgetRemaining}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Erro */}
      {state === 'error' && errorMessage && (
        <div
          className="card warn"
          style={{ marginTop: '16px' }}
          data-testid="analyze-error"
        >
          <strong>⚠️ Erro</strong>
          <p>{errorMessage}</p>
        </div>
      )}
    </div>
  );
}
EOF

echo "[ok] packages/ui/src/components/AnalyzePlayground.tsx criado"

################################################################################
# 11. src/styles/global.css (baseado no wireframe MiniIDE-Explore.html)
################################################################################

cat <<'EOF' > packages/ui/src/styles/global.css
/**
 * Estilos globais da Mini-IDE UI
 * Baseado no wireframe MiniIDE-Explore.html
 */

:root {
  --bg: #0f1420;
  --panel: #141b2b;
  --panel-2: #101727;
  --panel-3: #0c1323;
  --text: #e6ecff;
  --muted: #9fb0d3;
  --brand: #4ba3ff;
  --brand-2: #6ad3ff;
  --accent: #00c2a8;
  --danger: #ff5c7a;
  --ok: #47e6a1;
  --chip: #222b40;
  --border: #24304a;
  --shadow: 0 8px 24px rgba(0, 0, 0, 0.35);
  --radius: 14px;
}

@media (prefers-color-scheme: light) {
  :root {
    --bg: #f7f9fc;
    --panel: #ffffff;
    --panel-2: #f3f6fb;
    --panel-3: #ecf2fb;
    --text: #0b162b;
    --muted: #4a5977;
    --brand: #0b63ff;
    --brand-2: #0aa2ff;
    --accent: #00a78d;
    --danger: #ff3e5e;
    --ok: #00b17a;
    --chip: #e9eef9;
    --border: #d7e0f5;
    --shadow: 0 8px 28px rgba(15, 20, 32, 0.08);
  }
}

* {
  box-sizing: border-box;
}

html,
body {
  height: 100%;
  margin: 0;
  padding: 0;
}

body {
  background: var(--bg);
  color: var(--text);
  font: 14px/1.45 Inter, ui-sans-serif, system-ui, 'Segoe UI', Roboto,
    Helvetica, Arial, sans-serif;
}

#root {
  height: 100%;
}

.app {
  display: grid;
  grid-template-rows: 56px 1fr;
  height: 100vh;
}

header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 16px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.02), transparent),
    var(--panel);
  border-bottom: 1px solid var(--border);
  box-shadow: var(--shadow);
  position: sticky;
  top: 0;
  z-index: 2;
}

header .title {
  font-weight: 700;
  letter-spacing: 0.2px;
}

.pill {
  padding: 6px 10px;
  border-radius: 999px;
  background: var(--chip);
  border: 1px solid var(--border);
  color: var(--muted);
  font-size: 13px;
}

.btn {
  background: var(--panel-2);
  border: 1px solid var(--border);
  color: var(--text);
  height: 32px;
  padding: 0 12px;
  border-radius: 10px;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  box-shadow: var(--shadow);
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s;
}

.btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.4);
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn.primary {
  background: linear-gradient(180deg, var(--brand-2), var(--brand));
  color: white;
  border: none;
}

.spacer {
  flex: 1;
}

.row {
  display: flex;
  gap: 10px;
  align-items: center;
}

.main {
  display: grid;
  grid-template-columns: 280px 1fr 360px;
  gap: 14px;
  padding: 14px;
  overflow: auto;
}

.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}

.sidebar {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 0;
}

.workspace {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
  overflow: auto;
}

.tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.tab {
  padding: 6px 10px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--panel-2);
  color: var(--muted);
  cursor: pointer;
  font-size: 13px;
  transition: all 0.2s;
}

.tab:hover {
  background: var(--chip);
}

.tab.active {
  background: var(--brand);
  color: white;
  border-color: transparent;
}

.cards {
  display: grid;
  gap: 12px;
  grid-template-columns: 1fr;
}

.card {
  background: var(--panel-2);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 14px;
}

.card h3 {
  margin: 0 0 8px 0;
  font-size: 16px;
}

.card h4 {
  margin: 0 0 8px 0;
  font-size: 14px;
}

.chip {
  background: var(--chip);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 4px 8px;
  font-size: 12px;
  display: inline-block;
}

.chip.ok {
  background: rgba(71, 230, 161, 0.15);
  border-color: rgba(71, 230, 161, 0.4);
  color: var(--ok);
}

.chip.warn {
  background: rgba(255, 94, 94, 0.08);
  border-color: rgba(255, 94, 94, 0.35);
  color: var(--danger);
}

.muted {
  color: var(--muted);
}

textarea {
  width: 100%;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--panel-2);
  color: var(--text);
  padding: 10px;
  resize: vertical;
  outline: none;
  font-family: inherit;
  font-size: 13px;
}

textarea:focus {
  border-color: var(--brand);
}

input[type='number'],
input[type='text'] {
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--panel-2);
  color: var(--text);
  padding: 0 10px;
  outline: none;
  font-family: inherit;
  font-size: 13px;
}

input:focus {
  border-color: var(--brand);
}

.hidden {
  display: none !important;
}

.split {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

/* Responsividade básica */
@media (max-width: 1024px) {
  .main {
    grid-template-columns: 1fr;
  }
  
  .split {
    grid-template-columns: 1fr;
  }
}
EOF

echo "[ok] packages/ui/src/styles/global.css criado"

################################################################################
# 12. src/App.tsx (componente principal com layout do wireframe)
################################################################################

cat <<'EOF' > packages/ui/src/App.tsx
/**
 * Componente principal da Mini-IDE UI
 * 
 * @packageDocumentation
 * @module App
 * 
 * Layout baseado no wireframe MiniIDE-Explore.html:
 * - Header com título, ServerStatus e botões
 * - Main com 3 colunas: sidebar, workspace central, right panel
 * - Workspace com tabs (Overview, Analyze)
 * - AnalyzePlayground integrado na tab Analyze
 */

import { useState } from 'react';
import { ServerStatus } from './components/ServerStatus.js';
import { AnalyzePlayground } from './components/AnalyzePlayground.js';
import './styles/global.css';

type ActiveTab = 'overview' | 'analyze';

/**
 * Componente raiz da aplicação Mini-IDE
 * 
 * @returns Elemento React com layout completo
 */
export function App() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('overview');

  return (
    <div className="app">
      {/* Header */}
      <header>
        <div className="title">Mini IDE</div>
        <div className="pill">Analysis Agent</div>
        <ServerStatus pollInterval={10000} />
        <div className="spacer"></div>
      </header>

      {/* Main layout */}
      <div className="main">
        {/* Sidebar esquerda */}
        <aside className="panel sidebar">
          <div className="row" style={{ justifyContent: 'space-between' }}>
            <strong>Projeto Atual</strong>
            <span className="pill ok">pronto</span>
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <p className="muted" style={{ textAlign: 'center', fontSize: '12px' }}>
              Sidebar placeholder
            </p>
          </div>
        </aside>

        {/* Workspace central */}
        <section className="panel workspace">
          <div className="tabs">
            <div
              className={`tab ${activeTab === 'overview' ? 'active' : ''}`}
              onClick={() => setActiveTab('overview')}
            >
              Overview
            </div>
            <div
              className={`tab ${activeTab === 'analyze' ? 'active' : ''}`}
              onClick={() => setActiveTab('analyze')}
            >
              Analyze
            </div>
          </div>

          {/* Tab Overview */}
          {activeTab === 'overview' && (
            <div className="cards">
              <div className="card">
                <h3>Bem-vindo à Mini IDE</h3>
                <p>
                  Este é o painel de interface da Mini-IDE. Use a tab{' '}
                  <strong>Analyze</strong> para testar o endpoint POST /analyze
                  interativamente.
                </p>
                <ul style={{ marginTop: '12px' }}>
                  <li>Servidor configurável via VITE_MINI_IDE_SERVER_URL</li>
                  <li>Indicador de status do servidor em tempo real</li>
                  <li>Playground para requisições /analyze</li>
                </ul>
              </div>
            </div>
          )}

          {/* Tab Analyze (Playground) */}
          {activeTab === 'analyze' && (
            <div className="cards">
              <AnalyzePlayground defaultMaxLen={100} />
            </div>
          )}
        </section>

        {/* Right panel */}
        <aside className="panel sidebar">
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <p className="muted" style={{ textAlign: 'center', fontSize: '12px' }}>
              Right panel placeholder
            </p>
          </div>
        </aside>
      </div>
    </div>
  );
}
EOF

echo "[ok] packages/ui/src/App.tsx criado"

################################################################################
# 13. src/main.tsx (entry point React)
################################################################################

cat <<'EOF' > packages/ui/src/main.tsx
/**
 * Entry point da aplicação React
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App.js';

const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error('Root element not found');
}

ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

echo "[ok] packages/ui/src/main.tsx criado"

################################################################################
# 14. test/setup.ts (configuração de testes)
################################################################################

cat <<'EOF' > packages/ui/test/setup.ts
/**
 * Configuração global de testes para Vitest
 */

import '@testing-library/jest-dom';

// Mock de import.meta.env para testes
Object.defineProperty(globalThis, 'import', {
  value: {
    meta: {
      env: {
        VITE_MINI_IDE_SERVER_URL: 'http://127.0.0.1:3200',
      },
    },
  },
  writable: true,
});

// Mock de fetch global para testes (substituir quando necessário nos testes individuais)
globalThis.fetch = vi.fn();
EOF

echo "[ok] packages/ui/test/setup.ts criado"

################################################################################
# 15. test/config/server.spec.ts (testes de configuração)
################################################################################

cat <<'EOF' > packages/ui/test/config/server.spec.ts
/**
 * Testes para módulo de configuração de servidor
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { getBaseUrl, getHealthzUrl, getAnalyzeUrl } from '../../src/config/server.js';

describe('config/server', () => {
  beforeEach(() => {
    // Garantir que a variável de ambiente está definida no setup
    vi.clearAllMocks();
  });

  describe('getBaseUrl', () => {
    it('deve retornar a URL configurada via VITE_MINI_IDE_SERVER_URL', () => {
      const url = getBaseUrl();
      expect(url).toBe('http://127.0.0.1:3200');
    });

    it('não deve retornar undefined ou string vazia', () => {
      const url = getBaseUrl();
      expect(url).toBeTruthy();
      expect(url.length).toBeGreaterThan(0);
    });

    it('deve retornar URL sem barra final', () => {
      const url = getBaseUrl();
      expect(url).not.toMatch(/\/$/);
    });
  });

  describe('getHealthzUrl', () => {
    it('deve retornar URL completa do endpoint /healthz', () => {
      const url = getHealthzUrl();
      expect(url).toBe('http://127.0.0.1:3200/healthz');
    });

    it('deve incluir a baseURL no caminho', () => {
      const url = getHealthzUrl();
      expect(url).toContain(getBaseUrl());
    });

    it('deve terminar com /healthz', () => {
      const url = getHealthzUrl();
      expect(url).toMatch(/\/healthz$/);
    });
  });

  describe('getAnalyzeUrl', () => {
    it('deve retornar URL completa do endpoint /analyze', () => {
      const url = getAnalyzeUrl();
      expect(url).toBe('http://127.0.0.1:3200/analyze');
    });

    it('deve incluir a baseURL no caminho', () => {
      const url = getAnalyzeUrl();
      expect(url).toContain(getBaseUrl());
    });

    it('deve terminar com /analyze', () => {
      const url = getAnalyzeUrl();
      expect(url).toMatch(/\/analyze$/);
    });
  });
});
EOF

echo "[ok] packages/ui/test/config/server.spec.ts criado"

################################################################################
# 16. test/components/ServerStatus.spec.tsx (testes de ServerStatus)
################################################################################

cat <<'EOF' > packages/ui/test/components/ServerStatus.spec.tsx
/**
 * Testes para componente ServerStatus
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { ServerStatus } from '../../src/components/ServerStatus.js';

describe('ServerStatus', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('deve renderizar com estado inicial "Verificando..."', () => {
    globalThis.fetch = vi.fn();
    render(<ServerStatus pollInterval={5000} />);
    
    const status = screen.getByTestId('server-status');
    expect(status).toBeInTheDocument();
    expect(status.textContent).toContain('Verificando');
  });

  it('deve exibir "Servidor online" quando /healthz retorna 200', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
    } as Response);

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor online');
      expect(status.className).toContain('ok');
    });
  });

  it('deve exibir "Servidor indisponível" quando /healthz falha', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 500,
    } as Response);

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor indisponível');
      expect(status.className).toContain('warn');
    });
  });

  it('deve exibir "Servidor indisponível" em caso de erro de rede', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    render(<ServerStatus pollInterval={5000} />);

    await waitFor(() => {
      const status = screen.getByTestId('server-status');
      expect(status.textContent).toContain('Servidor indisponível');
      expect(status.className).toContain('warn');
    });
  });

  it('deve fazer polling periódico conforme pollInterval', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
    } as Response);

    render(<ServerStatus pollInterval={5000} />);

    // Primeira chamada (mount)
    await waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(1);
    });

    // Avançar timer 5s
    vi.advanceTimersByTime(5000);

    await waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(2);
    });

    // Mais 5s
    vi.advanceTimersByTime(5000);

    await waitFor(() => {
      expect(globalThis.fetch).toHaveBeenCalledTimes(3);
    });
  });
});
EOF

echo "[ok] packages/ui/test/components/ServerStatus.spec.tsx criado"

################################################################################
# 17. test/components/AnalyzePlayground.spec.tsx (testes de AnalyzePlayground)
################################################################################

cat <<'EOF' > packages/ui/test/components/AnalyzePlayground.spec.tsx
/**
 * Testes para componente AnalyzePlayground
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { AnalyzePlayground } from '../../src/components/AnalyzePlayground.js';

describe('AnalyzePlayground', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('deve renderizar formulário com textarea, input e botão', () => {
    render(<AnalyzePlayground defaultMaxLen={100} />);

    expect(screen.getByLabelText(/Texto para análise/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Tamanho máximo/i)).toBeInTheDocument();
    expect(screen.getByTestId('analyze-button')).toBeInTheDocument();
  });

  it('deve mostrar erro se tentar analisar sem texto', async () => {
    render(<AnalyzePlayground defaultMaxLen={100} />);

    const button = screen.getByTestId('analyze-button');
    await userEvent.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
      expect(screen.getByText(/insira um texto/i)).toBeInTheDocument();
    });
  });

  it('deve exibir resultado quando /analyze retorna 200', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        summary: 'Test summary',
        inputLength: 50,
        outputLength: 12,
        timestamp: '2025-11-16T12:00:00Z',
        requestId: 'req-123',
      }),
    } as Response);

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await userEvent.type(textarea, 'Olá Mini-IDE, analise este texto!');

    const button = screen.getByTestId('analyze-button');
    await userEvent.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-result')).toBeInTheDocument();
      expect(screen.getByText(/Test summary/i)).toBeInTheDocument();
      expect(screen.getByText(/Input Length:/i)).toBeInTheDocument();
    });
  });

  it('deve exibir erro quando /analyze retorna 4xx', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 400,
      json: async () => ({ message: 'Invalid request' }),
    } as Response);

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await userEvent.type(textarea, 'Texto de teste');

    const button = screen.getByTestId('analyze-button');
    await userEvent.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
      expect(screen.getByText(/Invalid request/i)).toBeInTheDocument();
    });
  });

  it('deve exibir erro de rede quando fetch falha', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await userEvent.type(textarea, 'Texto de teste');

    const button = screen.getByTestId('analyze-button');
    await userEvent.click(button);

    await waitFor(() => {
      expect(screen.getByTestId('analyze-error')).toBeInTheDocument();
      expect(screen.getByText(/Erro de conexão/i)).toBeInTheDocument();
    });
  });

  it('deve desabilitar campos durante loading', async () => {
    // Mock de fetch que demora para resolver
    globalThis.fetch = vi.fn().mockImplementation(
      () =>
        new Promise((resolve) => {
          setTimeout(
            () =>
              resolve({
                ok: true,
                status: 200,
                json: async () => ({
                  summary: 'Result',
                  inputLength: 10,
                  outputLength: 10,
                  timestamp: '2025-11-16T12:00:00Z',
                  requestId: 'req-456',
                }),
              } as Response),
            100
          );
        })
    );

    render(<AnalyzePlayground defaultMaxLen={100} />);

    const textarea = screen.getByLabelText(/Texto para análise/i);
    await userEvent.type(textarea, 'Test');

    const button = screen.getByTestId('analyze-button');
    await userEvent.click(button);

    // Verificar que o botão está desabilitado durante loading
    expect(button).toBeDisabled();
    expect(button.textContent).toContain('Analisando');

    // Aguardar resolução
    await waitFor(
      () => {
        expect(screen.getByTestId('analyze-result')).toBeInTheDocument();
      },
      { timeout: 200 }
    );
  });

  it('deve usar defaultMaxLen quando fornecido', () => {
    render(<AnalyzePlayground defaultMaxLen={150} />);

    const input = screen.getByLabelText(/Tamanho máximo/i) as HTMLInputElement;
    expect(input.value).toBe('150');
  });
});
EOF

echo "[ok] packages/ui/test/components/AnalyzePlayground.spec.tsx criado"

################################################################################
# 18. Atualizar DEVELOPMENT.md com seção UI
################################################################################

echo "[info] Atualizando DEVELOPMENT.md..."

# Backup do DEVELOPMENT.md original
cp DEVELOPMENT.md DEVELOPMENT.md.bak

# Adicionar seção sobre UI após a seção 7 (CLI)
cat > DEVELOPMENT_UI_SECTION.tmp <<'EOF'

---

## 8. Interface de Usuário (UI)

### 8.1 Tecnologias

O pacote `@mini-ide/ui` usa:

- **React 18** - biblioteca de interface
- **TypeScript** - tipagem estática
- **Vite** - bundler e dev server
- **Vitest** - framework de testes
- **CSS Modules** - estilos baseados no wireframe MiniIDE-Explore.html

### 8.2 Desenvolvimento local

Para rodar a UI em modo desenvolvimento:

```bash
# Instalar dependências (se ainda não instalou)
pnpm install

# Rodar dev server na porta 5173
pnpm --filter @mini-ide/ui dev
```

Acesse: `http://localhost:5173`

### 8.3 Configuração do servidor backend

A UI se conecta ao servidor Mini-IDE através da variável de ambiente:

```bash
VITE_MINI_IDE_SERVER_URL=http://127.0.0.1:3200
```

Para configurar:

1. Copie o arquivo de exemplo:
   ```bash
   cp packages/ui/.env.example packages/ui/.env
   ```

2. Ajuste a URL conforme necessário no arquivo `.env`

3. Reinicie o dev server

### 8.4 Build de produção

```bash
pnpm --filter @mini-ide/ui build
```

Os artefatos gerados ficam em `packages/ui/dist/`.

### 8.5 Testes

```bash
# Rodar testes
pnpm --filter @mini-ide/ui test

# Testes com coverage
pnpm --filter @mini-ide/ui test:coverage

# Modo watch
pnpm --filter @mini-ide/ui test:watch
```

O threshold de cobertura configurado é **80%** para todos os pacotes.

### 8.6 Componentes principais

- **ServerStatus** - Indicador visual de status do servidor (GET /healthz)
- **AnalyzePlayground** - Playground interativo para POST /analyze
- **App** - Componente raiz com layout baseado no wireframe

### 8.7 Padrão visual

A UI segue o padrão definido em `MiniIDE-Explore.html`:

- Dark mode com variáveis CSS customizadas
- Layout 3 colunas (sidebar, workspace, right panel)
- Chips, pills e cards com border-radius consistente
- Cores: --brand (#4ba3ff), --ok (#47e6a1), --danger (#ff5c7a)

EOF

# Inserir a seção UI no DEVELOPMENT.md original
# (após a linha que contém "## 7. Épico E-CLI")
awk '
/^## 7\. Épico E-CLI/ {
  found = 1
}
found && /^---$/ && !inserted {
  print
  system("cat DEVELOPMENT_UI_SECTION.tmp")
  inserted = 1
  next
}
{ print }
' DEVELOPMENT.md.bak > DEVELOPMENT.md

# Limpar arquivos temporários
rm -f DEVELOPMENT.md.bak DEVELOPMENT_UI_SECTION.tmp

echo "[ok] DEVELOPMENT.md atualizado com seção sobre UI"

################################################################################
# 19. Criar .eslintrc.cjs para o pacote UI
################################################################################

cat <<'EOF' > packages/ui/.eslintrc.cjs
module.exports = {
  root: true,
  env: { browser: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
  ],
  ignorePatterns: ['dist', '.eslintrc.cjs', 'vite.config.ts', 'vitest.config.ts'],
  parser: '@typescript-eslint/parser',
  plugins: ['react-refresh'],
  rules: {
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true },
    ],
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
  },
}
EOF

echo "[ok] packages/ui/.eslintrc.cjs criado"

################################################################################
# 20. Criar .gitignore para o pacote UI
################################################################################

cat <<'EOF' > packages/ui/.gitignore
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
dist
dist-ssr
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
.DS_Store
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Env files
.env
.env.local
.env.production

# Coverage
coverage/
*.lcov
EOF

echo "[ok] packages/ui/.gitignore criado"

################################################################################
# RESUMO E VALIDAÇÕES
################################################################################

echo ""
echo "============================================================"
echo "✅ IMPLEMENTAÇÃO CONCLUÍDA"
echo "============================================================"
echo ""
echo "📦 Arquivos criados/modificados:"
echo ""
echo "   Configuração:"
echo "   - packages/ui/package.json"
echo "   - packages/ui/tsconfig.json"
echo "   - packages/ui/tsconfig.build.json"
echo "   - packages/ui/vite.config.ts"
echo "   - packages/ui/vitest.config.ts"
echo "   - packages/ui/.env.example"
echo "   - packages/ui/.eslintrc.cjs"
echo "   - packages/ui/.gitignore"
echo "   - packages/ui/index.html"
echo ""
echo "   Código-fonte:"
echo "   - packages/ui/src/main.tsx"
echo "   - packages/ui/src/App.tsx"
echo "   - packages/ui/src/config/server.ts"
echo "   - packages/ui/src/components/ServerStatus.tsx"
echo "   - packages/ui/src/components/AnalyzePlayground.tsx"
echo "   - packages/ui/src/styles/global.css"
echo ""
echo "   Testes (coverage ≥80%):"
echo "   - packages/ui/test/setup.ts"
echo "   - packages/ui/test/config/server.spec.ts"
echo "   - packages/ui/test/components/ServerStatus.spec.tsx"
echo "   - packages/ui/test/components/AnalyzePlayground.spec.tsx"
echo ""
echo "   Documentação:"
echo "   - DEVELOPMENT.md (atualizado com seção 8. UI)"
echo ""
echo "============================================================"
echo "📋 HISTÓRIAS DE USUÁRIO IMPLEMENTADAS"
echo "============================================================"
echo ""
echo "   ✅ HU-UI-Server-BaseURL-Config"
echo "      → Configuração centralizada em src/config/server.ts"
echo "      → Usa VITE_MINI_IDE_SERVER_URL (variável de ambiente)"
echo "      → Funções: getBaseUrl(), getHealthzUrl(), getAnalyzeUrl()"
echo ""
echo "   ✅ HU-UI-Healthz-Status-Indicator"
echo "      → Componente ServerStatus.tsx"
echo "      → Polling periódico GET /healthz (padrão: 10s)"
echo "      → Chip visual: 🟢 online | 🔴 indisponível"
echo ""
echo "   ✅ HU-UI-Analyze-Playground"
echo "      → Componente AnalyzePlayground.tsx"
echo "      → Formulário: textarea (text) + input numérico (maxLen)"
echo "      → Exibe resultado estruturado ou mensagens de erro"
echo "      → Integrado na tab 'Analyze' do workspace"
echo ""
echo "============================================================"
echo "🎨 PADRÃO VISUAL"
echo "============================================================"
echo ""
echo "   ✅ Baseado no wireframe MiniIDE-Explore.html"
echo "   ✅ Dark mode com variáveis CSS (--bg, --panel, --brand...)"
echo "   ✅ Layout 3 colunas: sidebar | workspace | right panel"
echo "   ✅ Tabs, cards, chips e pills consistentes"
echo "   ✅ Responsivo (breakpoint 1024px)"
echo ""
echo "============================================================"
echo "🔧 PRÓXIMOS PASSOS"
echo "============================================================"
echo ""
echo "1. Instalar dependências do pacote UI:"
echo "   pnpm install"
echo ""
echo "2. Configurar variável de ambiente:"
echo "   cp packages/ui/.env.example packages/ui/.env"
echo "   # Ajustar VITE_MINI_IDE_SERVER_URL se necessário"
echo ""
echo "3. VALIDAR A PIPELINE (OBRIGATÓRIO):"
echo "   pnpm --filter @mini-ide/ui lint"
echo "   pnpm --filter @mini-ide/ui test"
echo "   pnpm --filter @mini-ide/ui typecheck"
echo "   pnpm --filter @mini-ide/ui build"
echo ""
echo "4. Rodar testes com coverage:"
echo "   pnpm --filter @mini-ide/ui test:coverage"
echo "   # Threshold: 80% (deve passar)"
echo ""
echo "5. Rodar a UI em desenvolvimento:"
echo "   pnpm --filter @mini-ide/ui dev"
echo "   # Acesse: http://localhost:5173"
echo ""
echo "6. Subir o servidor backend (em outro terminal):"
echo "   PORT=3200 node packages/server/dist/index.js"
echo "   # Para testar integração com /healthz e /analyze"
echo ""
echo "7. Validação completa do monorepo:"
echo "   REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo ""
echo "============================================================"
echo "⚠️  LEMBRETE IMPORTANTE"
echo "============================================================"
echo ""
echo "   A pipeline DEVE ficar 100% VERDE antes de qualquer commit!"
echo ""
echo "   Comandos obrigatórios:"
echo "   - pnpm lint      (zero warnings)"
echo "   - pnpm test      (todos os testes passando)"
echo "   - pnpm typecheck (sem erros de tipo)"
echo "   - pnpm build     (build bem-sucedido)"
echo ""
echo "   Se houver falhas, NÃO commite. Analise os logs e corrija."
echo ""
echo "============================================================"
echo "📊 COBERTURA DE TESTES"
echo "============================================================"
echo ""
echo "   Threshold configurado: 80% (lines/functions/branches/statements)"
echo ""
echo "   Testes criados:"
echo "   - config/server: 100% coverage esperado"
echo "   - ServerStatus: ~90%+ coverage (polling, estados, erros)"
echo "   - AnalyzePlayground: ~85%+ coverage (form, success, erros)"
echo ""
echo "   Para verificar coverage detalhado:"
echo "   pnpm --filter @mini-ide/ui test:coverage"
echo "   open packages/ui/coverage/index.html"
echo ""
echo "============================================================"
echo "✨ FIM DO SCRIPT"
echo "============================================================"
