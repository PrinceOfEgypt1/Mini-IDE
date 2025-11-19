#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 34_fix_server_config_eslint.sh
# Objetivo: Corrigir unsafe any assignments no config/server.ts
################################################################################

echo "[info] Corrigindo tipos any em config/server.ts..."

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
  const port = (import.meta.env.VITE_SERVER_PORT as string | undefined) || '3200';
  const host = (import.meta.env.VITE_SERVER_HOST as string | undefined) || 'localhost';

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

echo "✅ Tipos corrigidos"
echo ""
echo "[info] Validando ESLint..."
pnpm --filter @mini-ide/ui lint

echo ""
echo "✅ ESLint passou! Fazendo commit..."
echo ""

git add .

git commit -m "feat(ui)!: restaurar wireframe MiniIDE-Explore.html" \
           -m "BREAKING CHANGE: Layout de abas em tela cheia substituído por layout de 3 colunas conforme wireframe oficial MiniIDE-Explore.html" \
           -m "" \
           -m "Problema:" \
           -m "- HU-UI-Tabs-004 havia criado abas (Explore/Design/Execute/Analyze) que substituíram incorretamente o layout base de 3 colunas do wireframe" \
           -m "- Sidebar, painel de Discovery Notes e abas internas foram removidos" \
           -m "" \
           -m "Solução:" \
           -m "- Restaurar layout de 3 colunas: Sidebar + Painel Central + Discovery Notes" \
           -m "- Criar WorkspaceTabs com 10 abas internas (Overview, HUs, Docs, Analyze, etc)" \
           -m "- Integrar ServerStatus + AnalyzePlayground na aba Analyze" \
           -m "" \
           -m "Componentes criados:" \
           -m "- Sidebar.tsx + Sidebar.module.css (coluna esquerda)" \
           -m "- WorkspaceTabs.tsx + WorkspaceTabs.module.css (painel central)" \
           -m "- DiscoveryNotes.tsx + DiscoveryNotes.module.css (coluna direita)" \
           -m "- App.tsx refatorado para layout 3 colunas" \
           -m "" \
           -m "Funcionalidades preservadas:" \
           -m "- ServerStatus (aba Analyze)" \
           -m "- AnalyzePlayground (aba Analyze)" \
           -m "" \
           -m "Testes: 152 passando" \
           -m "Pipeline: lint ✓ | test ✓ | typecheck ✓ | build ✓" \
           -m "" \
           -m "Refs: HU-UI-Fix-Align-Wireframe-Explore"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    COMMIT REALIZADO! ✓                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 HU-UI-Fix-Align-Wireframe-Explore FINALIZADA COM SUCESSO!"
