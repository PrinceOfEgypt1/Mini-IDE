#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 25_commit_wireframe_fix.sh
# Objetivo: Fazer commit da correção do wireframe com mensagem adequada
################################################################################

echo "[info] Fazendo commit da HU-UI-Fix-Align-Wireframe-Explore..."

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
           -m "- Documentar governança da UI (DEVELOPMENT.md 5.6.5)" \
           -m "" \
           -m "Componentes criados:" \
           -m "- Sidebar.tsx (coluna esquerda: projeto + árvore)" \
           -m "- WorkspaceTabs.tsx (10 abas internas do painel central)" \
           -m "- DiscoveryNotes.tsx (coluna direita: notas de descoberta)" \
           -m "- App.tsx refatorado para layout 3 colunas" \
           -m "" \
           -m "Funcionalidades preservadas:" \
           -m "- ServerStatus (na aba Analyze)" \
           -m "- AnalyzePlayground (na aba Analyze)" \
           -m "" \
           -m "Testes: 152 passando (shared: 47, ui: 37, agent: 1, cli: 2, server: 65)" \
           -m "Pipeline: lint ✓ | test ✓ | typecheck ✓ | build ✓" \
           -m "" \
           -m "Refs: HU-UI-Fix-Align-Wireframe-Explore"

echo ""
echo "✅ Commit realizado com sucesso!"
echo ""
echo "Verificar commit:"
echo "  git log -1 --pretty=format:'%s%n%b' | head -30"
echo ""
echo "Próximos passos:"
echo "  1. git push (se necessário)"
echo "  2. Próximas HUs respeitarão o wireframe"
echo ""
echo "[info] HU-UI-Fix-Align-Wireframe-Explore FINALIZADA!"
