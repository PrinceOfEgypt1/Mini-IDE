#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 24_update_development_md.sh
# Objetivo: Adicionar documentação de Governança da UI ao DEVELOPMENT.md
################################################################################

echo "[info] Atualizando DEVELOPMENT.md com governança da UI..."

# Backup
cp DEVELOPMENT.md DEVELOPMENT.md.backup

# Adicionar seção 5.6.5
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
- Componentes obsoletos movidos para deprecated/ e posteriormente removidos

**Scripts Aplicados:**
- `19_fix_ui_align_wireframe.sh` - Restauração do wireframe
- `20_fix_app_test_button_query.sh` - Correção de testes ambíguos
- `21_remove_deprecated_components.sh` - Limpeza de componentes obsoletos
- `23_validate_complete_pipeline.sh` - Validação final

**Resultado:** 152 testes passando, pipeline 100% verde, wireframe restaurado.
EOF

echo "[ok] DEVELOPMENT.md atualizado com seção 5.6.5"
echo ""
echo "Próximos passos:"
echo "  1. git add DEVELOPMENT.md"
echo "  2. Revisar mudanças: git diff DEVELOPMENT.md"
echo ""
echo "[info] Documentação concluída!"
