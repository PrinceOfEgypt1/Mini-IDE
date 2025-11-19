#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 31_add_missing_server_config_functions.sh
# Objetivo: Adicionar funções getBaseUrl, getHealthzUrl, getAnalyzeUrl
################################################################################

echo "[info] Adicionando funções faltantes ao config/server.ts..."

cat > packages/ui/src/config/server.ts <<'EOF'
/**
 * Configuração do servidor backend
 */
export interface ServerConfig {
  baseUrl: string;
  timeout: number;
}

/**
 * Retorna a configuração do servidor
 */
export function getServerConfig(): ServerConfig {
  const port = import.meta.env.VITE_SERVER_PORT || '3200';
  const host = import.meta.env.VITE_SERVER_HOST || 'localhost';

  return {
    baseUrl: `http://${host}:${port}`,
    timeout: 30000,
  };
}

/**
 * Retorna a URL base do servidor
 */
export function getBaseUrl(): string {
  return getServerConfig().baseUrl;
}

/**
 * Retorna a URL do endpoint /healthz
 */
export function getHealthzUrl(): string {
  return `${getBaseUrl()}/healthz`;
}

/**
 * Retorna a URL do endpoint /analyze
 */
export function getAnalyzeUrl(): string {
  return `${getBaseUrl()}/analyze`;
}
EOF

echo "✅ Funções adicionadas"
echo ""
echo "[info] Validando TypeScript..."
pnpm --filter @mini-ide/ui typecheck

echo ""
echo "[info] Executando testes..."
pnpm --filter @mini-ide/ui test

echo ""
echo "✅ TUDO FUNCIONANDO!"
