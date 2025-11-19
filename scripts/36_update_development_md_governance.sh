#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 36_update_development_md_governance.sh
# Objetivo: Adicionar seção 5.6.5 de Governança da UI ao DEVELOPMENT.md
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Atualizando DEVELOPMENT.md - Governança da UI           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Backup
cp DEVELOPMENT.md DEVELOPMENT.md.backup-governance

# Adicionar seção 5.6.5 ao final do arquivo
cat >> DEVELOPMENT.md <<'EOF'

### 5.6.5 Governança da UI (Explore Workspace) - v1.0.17

**Wireframe Oficial:** `MiniIDE-Explore.html`

#### Estrutura Imutável

O layout base do Explore Workspace é **IMUTÁVEL** e deve ser respeitado por todas as HUs de UI, salvo HU específica de redesign:

**Layout de 3 Colunas:**
- **Sidebar Esquerda** (280px): Projeto Atual, árvore de arquivos, status
- **Painel Central** (expansível): 10 abas internas (Overview, HUs, Docs, Testes, Analyze, Personas & Plano, Timeline, Runs, Métricas, Outputs)
- **Painel Direito** (360px): Discovery Notes (Intenção, Requisitos, Restrições, Exemplos & Referências)
- **Footer**: Chat com textarea + botões Anexar/Enviar

#### Regras Obrigatórias para HUs de UI

1. **Wireframe como fonte de verdade visual**
   - Todo desenvolvimento de UI DEVE consultar `MiniIDE-Explore.html`
   - Desvios do wireframe só são permitidos com HU específica de redesign

2. **Layout de 3 colunas é obrigatório**
   - Novas funcionalidades devem ser integradas DENTRO do layout existente
   - Não é permitido remover/substituir painéis ou abas sem HU específica

3. **Abas internas do painel central (10 abas)**
   - Overview, HUs, Docs, Testes, Analyze, Personas & Plano, Timeline, Runs, Métricas, Outputs
   - Novas abas só podem ser adicionadas com HU específica

4. **Documentação de impacto**
   - Toda HU de UI deve incluir seção "Impacto na UI vs Wireframe"
   - Especificar: o que permanece, o que é novo, o que diverge (com justificativa)

#### Componentes Base (v1.0.17)

**Estrutura:**
```
packages/ui/src/
├── App.tsx                    - Layout 3 colunas (header + main + footer)
├── App.module.css             - Estilos do wireframe
├── components/
│   ├── Sidebar.tsx            - Coluna esquerda (projeto + árvore)
│   ├── WorkspaceTabs.tsx      - Abas internas do painel central
│   ├── DiscoveryNotes.tsx     - Coluna direita (notas de descoberta)
│   ├── ServerStatus.tsx       - Indicador de servidor (aba Analyze)
│   └── AnalyzePlayground.tsx  - Playground do /analyze (aba Analyze)
```

**Responsividade:**
- Desktop (>1200px): 3 colunas visíveis
- Tablet (900px-1200px): 3 colunas com larguras ajustadas
- Mobile (<900px): 1 coluna, painéis colapsáveis

#### HU de Correção: HU-UI-Fix-Align-Wireframe-Explore

**Problema Corrigido:** A HU-UI-Tabs-004 havia destruído o layout base ao criar abas em tela cheia que substituíram (incorretamente) a estrutura de 3 colunas.

**Solução Aplicada:**
- Restauração completa do wireframe MiniIDE-Explore.html
- Sidebar, WorkspaceTabs e DiscoveryNotes criados do zero
- ServerStatus e AnalyzePlayground integrados na aba "Analyze"
- Componentes obsoletos removidos

**Scripts Aplicados:**
- `19_fix_ui_align_wireframe.sh` - Restauração do wireframe
- `20_fix_app_test_button_query.sh` - Correção de testes ambíguos
- `21_remove_deprecated_components.sh` - Limpeza de componentes obsoletos
- `34_fix_server_config_eslint.sh` - Correção TypeScript strict

**Resultado:** 152 testes passando, pipeline 100% verde, wireframe restaurado.

**Commit:** `d3de0c7` - feat(ui)!: restaurar wireframe MiniIDE-Explore.html

---
EOF

echo "✅ Seção 5.6.5 adicionada ao DEVELOPMENT.md"
echo ""
echo "[info] Verificando diff..."
echo ""

git diff DEVELOPMENT.md | head -50

echo ""
echo "[info] Fazendo commit da documentação..."
echo ""

git add DEVELOPMENT.md

git commit -m "docs(ui): adicionar seção 5.6.5 - Governança da UI" \
           -m "Documentar regras de governança para o wireframe MiniIDE-Explore.html" \
           -m "" \
           -m "Conteúdo:" \
           -m "- Estrutura imutável do layout 3 colunas" \
           -m "- Regras obrigatórias para HUs de UI" \
           -m "- Componentes base v1.0.17" \
           -m "- Histórico da HU-UI-Fix-Align-Wireframe-Explore" \
           -m "" \
           -m "O wireframe é agora a fonte de verdade absoluta para UI" \
           -m "" \
           -m "Refs: HU-UI-Fix-Align-Wireframe-Explore, commit d3de0c7"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          DEVELOPMENT.md ATUALIZADO E COMMITADO ✓               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Governança da UI documentada"
echo "✅ Commit adicional criado"
echo ""
echo "Histórico recente:"
git log --oneline -3
echo ""
echo "Agora sim, HU 100% completa com documentação no repo! 🎉"
