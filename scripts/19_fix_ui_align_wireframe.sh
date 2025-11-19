#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 19_fix_ui_align_wireframe.sh
# HU: HU-UI-Fix-Align-Wireframe-Explore
# Objetivo: Restaurar UI ao wireframe oficial MiniIDE-Explore.html
# 
# Problema: HU-UI-Tabs-004 destruiu o layout base (3 colunas, sidebar, 
#           Discovery Notes, abas internas). Precisamos restaurar o wireframe.
#
# Solução: Recriar estrutura de 3 colunas + abas internas + Discovery Notes,
#          integrando ServerStatus e AnalyzePlayground na aba "Analyze"
#
# Arquivos modificados:
#   - packages/ui/src/App.tsx (restaurar layout 3 colunas)
#   - packages/ui/src/App.module.css (estilos do wireframe)
#   - packages/ui/src/components/WorkspaceTabs.tsx (abas internas)
#   - packages/ui/src/components/Sidebar.tsx (novo)
#   - packages/ui/src/components/DiscoveryNotes.tsx (novo)
#   - packages/ui/src/components/tabs/* (ajustar estrutura)
#   - packages/ui/test/App.spec.tsx (atualizar testes)
#
# Modo de uso:
#   1. chmod +x scripts/19_fix_ui_align_wireframe.sh
#   2. ./scripts/19_fix_ui_align_wireframe.sh
#   3. Validar visualmente a UI
################################################################################

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  HU-UI-Fix-Align-Wireframe-Explore - Restauração do Wireframe ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "[info] Iniciando correção de alinhamento ao MiniIDE-Explore.html..."
echo ""

# ═══════════════════════════════════════════════════════════════
# 1. COMPONENTE: Sidebar (coluna esquerda)
# ═══════════════════════════════════════════════════════════════

echo "[1/8] Criando componente Sidebar (árvore do projeto)..."

mkdir -p packages/ui/src/components

cat <<'EOF' > packages/ui/src/components/Sidebar.tsx
import React from 'react';
import styles from './Sidebar.module.css';

/**
 * Sidebar - Painel esquerdo com árvore do projeto
 * 
 * Exibe estrutura de arquivos, status do projeto e informações contextuais.
 * Segue o wireframe MiniIDE-Explore.html.
 */
export const Sidebar: React.FC = () => {
  return (
    <aside className={styles.sidebar}>
      <div className={styles.header}>
        <strong>Projeto Atual</strong>
        <span className={styles.statusBadge}>pronto</span>
      </div>

      <input
        type="text"
        className={styles.filterInput}
        placeholder="Filtrar árvore (regex)"
        aria-label="Filtrar estrutura do projeto"
      />

      <div className={styles.tree}>
        <div className={styles.treeItem}>apps/</div>
        <div className={styles.treeItem}>  agent-dashboard/</div>
        <div className={styles.treeItem}>    src/</div>
        <div className={styles.treeItem}>packages/</div>
        <div className={styles.treeItem}>  engine/</div>
        <div className={styles.treeItem}>    src/</div>
        <div className={styles.treeItem}>services/</div>
        <div className={styles.treeItem}>  analysis-agent/</div>
        <div className={styles.treeItem}>    src/</div>
        <div className={styles.treeItem}>docs/</div>
        <div className={styles.treeItem}>  HUs/</div>
        <div className={styles.treeItem}>  ADRs/</div>
        <div className={styles.treeItem}>  SSoT/</div>
      </div>

      <div className={styles.statusBar}>
        <div className={styles.statusItem}>
          <span className={styles.label}>Instância:</span>
          <span className={styles.value}>/home/moses/workspace</span>
        </div>
        <div className={styles.statusItem}>
          <span className={styles.label}>Branch:</span>
          <span className={styles.value}>main</span>
        </div>
        <div className={styles.statusBadge}>Ambiente: ok</div>
      </div>
    </aside>
  );
};
EOF

cat <<'EOF' > packages/ui/src/components/Sidebar.module.css
.sidebar {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  min-height: 0;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.statusBadge {
  padding: 4px 8px;
  border-radius: 12px;
  background: rgba(71, 230, 161, 0.15);
  border: 1px solid rgba(71, 230, 161, 0.4);
  color: var(--ok, #47e6a1);
  font-size: 12px;
}

.filterInput {
  height: 34px;
  border-radius: 10px;
  border: 1px solid var(--border, #24304a);
  background: var(--panel-2, #101727);
  color: var(--text, #e6ecff);
  padding: 0 10px;
  width: 100%;
  outline: none;
}

.filterInput:focus {
  border-color: var(--brand, #4ba3ff);
}

.tree {
  flex: 1;
  overflow: auto;
  border-radius: 10px;
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  padding: 10px;
  font-family: 'Courier New', monospace;
  font-size: 13px;
  color: var(--muted, #9fb0d3);
}

.treeItem {
  padding: 2px 0;
  cursor: pointer;
}

.treeItem:hover {
  color: var(--text, #e6ecff);
}

.statusBar {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 11px;
  color: var(--muted, #9fb0d3);
}

.statusItem {
  display: flex;
  gap: 6px;
}

.label {
  font-weight: 600;
}

.value {
  opacity: 0.8;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
EOF

echo "  ✓ Sidebar criado"

# ═══════════════════════════════════════════════════════════════
# 2. COMPONENTE: DiscoveryNotes (coluna direita)
# ═══════════════════════════════════════════════════════════════

echo "[2/8] Criando componente DiscoveryNotes (painel direito)..."

cat <<'EOF' > packages/ui/src/components/DiscoveryNotes.tsx
import React from 'react';
import styles from './DiscoveryNotes.module.css';

/**
 * DiscoveryNotes - Painel direito com notas de descoberta
 * 
 * Coleta automática de intenção, requisitos, restrições e exemplos
 * durante o modo Explorar. Segue o wireframe MiniIDE-Explore.html.
 */
export const DiscoveryNotes: React.FC = () => {
  return (
    <aside className={styles.discoveryNotes}>
      <div className={styles.header}>
        <h3>Discovery Notes</h3>
        <p className={styles.subtitle}>
          Coleta automática do que surge no chat
        </p>
      </div>

      <div className={styles.notes}>
        <div className={styles.noteSection}>
          <h4>Intenção</h4>
          <ul>
            <li>—</li>
          </ul>
        </div>

        <div className={styles.noteSection}>
          <h4>Requisitos</h4>
          <ul>
            <li>—</li>
          </ul>
        </div>

        <div className={styles.noteSection}>
          <h4>Restrições</h4>
          <ul>
            <li>—</li>
          </ul>
        </div>

        <div className={styles.noteSection}>
          <h4>Exemplos & Referências</h4>
          <ul>
            <li>—</li>
          </ul>
        </div>
      </div>

      <div className={styles.metrics}>
        <span className={styles.metric}>~ ms</span>
        <span className={styles.metric}>R$ 0,00</span>
        <span className={styles.metric}>auto: on</span>
      </div>
    </aside>
  );
};
EOF

cat <<'EOF' > packages/ui/src/components/DiscoveryNotes.module.css
.discoveryNotes {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  min-height: 0;
}

.header h3 {
  margin: 0 0 4px 0;
  font-size: 16px;
}

.subtitle {
  margin: 0;
  font-size: 12px;
  color: var(--muted, #9fb0d3);
}

.notes {
  flex: 1;
  overflow: auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.noteSection {
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 10px;
  padding: 10px;
}

.noteSection h4 {
  margin: 0 0 6px 0;
  font-size: 13px;
  font-weight: 600;
}

.noteSection ul {
  margin: 0;
  padding-left: 20px;
  font-size: 12px;
  color: var(--muted, #9fb0d3);
}

.noteSection li {
  margin: 4px 0;
}

.metrics {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  font-size: 11px;
}

.metric {
  padding: 4px 8px;
  background: var(--chip, #222b40);
  border: 1px solid var(--border, #24304a);
  border-radius: 12px;
  color: var(--muted, #9fb0d3);
}
EOF

echo "  ✓ DiscoveryNotes criado"

# ═══════════════════════════════════════════════════════════════
# 3. COMPONENTE: WorkspaceTabs (abas internas do painel central)
# ═══════════════════════════════════════════════════════════════

echo "[3/8] Criando componente WorkspaceTabs (abas internas)..."

cat <<'EOF' > packages/ui/src/components/WorkspaceTabs.tsx
import React, { useState } from 'react';
import { ServerStatus } from './ServerStatus.js';
import { AnalyzePlayground } from './AnalyzePlayground.js';
import styles from './WorkspaceTabs.module.css';

type TabId = 'overview' | 'hus' | 'docs' | 'tests' | 'plan' | 'timeline' | 'runs' | 'metrics' | 'outputs' | 'analyze';

interface Tab {
  id: TabId;
  label: string;
}

const TABS: Tab[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'hus', label: 'HUs' },
  { id: 'docs', label: 'Docs' },
  { id: 'tests', label: 'Testes' },
  { id: 'analyze', label: 'Analyze' },
  { id: 'plan', label: 'Personas & Plano' },
  { id: 'timeline', label: 'Timeline' },
  { id: 'runs', label: 'Runs' },
  { id: 'metrics', label: 'Métricas' },
  { id: 'outputs', label: 'Outputs' },
];

/**
 * WorkspaceTabs - Abas internas do painel central
 * 
 * Implementa as 10 abas do wireframe MiniIDE-Explore.html:
 * Overview, HUs, Docs, Testes, Analyze, Personas & Plano, Timeline, Runs, Métricas, Outputs
 */
export const WorkspaceTabs: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabId>('overview');

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return (
          <div className={styles.content}>
            <div className={styles.split}>
              <div>
                <h3>Bem-vindo à Mini IDE</h3>
                <ul>
                  <li>Entendo sua necessidade (linguagem natural) e orquestro personas em <strong>uma única chamada</strong>.</li>
                  <li>Gero HUs, arquitetura, scripts de provisionamento e documentação.</li>
                  <li>Mostro os <strong>Outputs</strong> consolidados para revisão/execução.</li>
                </ul>
                <h4>Como começar</h4>
                <ol>
                  <li>Converse livremente no Chat (modo <strong>Explorar</strong>).</li>
                  <li>Use <em>Gerar Plano</em> quando tiver direção — nada é gravado sem confirmação.</li>
                  <li>Confirme: <em>Criar Projeto</em> → <em>Provisionar</em> → <em>Executar</em>.</li>
                </ol>
              </div>
            </div>
          </div>
        );

      case 'analyze':
        return (
          <div className={styles.content}>
            <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <h3 style={{ margin: 0 }}>Analyze Endpoint</h3>
                <ServerStatus />
              </div>
              <AnalyzePlayground />
            </div>
          </div>
        );

      case 'hus':
        return <div className={styles.placeholder}>Nenhuma HU gerada ainda.</div>;
      
      case 'docs':
        return <div className={styles.placeholder}>Crie um plano ou converta a conversa em HUs para gerar documentação.</div>;
      
      case 'tests':
        return <div className={styles.placeholder}>Testes aparecerão após geração de plano técnico.</div>;
      
      case 'plan':
        return <div className={styles.placeholder}>Nenhum plano gerado ainda.</div>;
      
      case 'timeline':
        return <div className={styles.placeholder}>Timeline de exploração aparecerá aqui.</div>;
      
      case 'runs':
        return <div className={styles.placeholder}>Disponível após o provisionamento.</div>;
      
      case 'metrics':
        return <div className={styles.placeholder}>Custo (R$), tempo de resposta e tokens aparecerão após execuções.</div>;
      
      case 'outputs':
        return <div className={styles.placeholder}>Nenhum output ainda.</div>;

      default:
        return <div className={styles.placeholder}>Selecione uma aba</div>;
    }
  };

  return (
    <div className={styles.workspace}>
      <div className={styles.tabs}>
        {TABS.map((tab) => (
          <button
            key={tab.id}
            className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
            onClick={() => setActiveTab(tab.id)}
            role="tab"
            aria-selected={activeTab === tab.id}
          >
            {tab.label}
          </button>
        ))}
      </div>
      <div className={styles.tabContent}>
        {renderContent()}
      </div>
    </div>
  );
};
EOF

cat <<'EOF' > packages/ui/src/components/WorkspaceTabs.module.css
.workspace {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: 12px;
  min-height: 0;
}

.tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 12px;
}

.tab {
  padding: 6px 12px;
  border: 1px solid var(--border, #24304a);
  border-radius: 999px;
  background: var(--panel-2, #101727);
  color: var(--muted, #9fb0d3);
  cursor: pointer;
  font-size: 13px;
  font-family: inherit;
  transition: all 0.15s ease;
  outline: none;
}

.tab:hover {
  background: var(--panel, #141b2b);
  color: var(--text, #e6ecff);
}

.tab:focus-visible {
  box-shadow: 0 0 0 2px var(--brand, #4ba3ff);
}

.tab.active {
  background: var(--brand, #4ba3ff);
  color: white;
  border-color: transparent;
}

.tabContent {
  flex: 1;
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 12px;
  overflow: auto;
  min-height: 0;
}

.content {
  padding: 24px;
}

.split {
  display: grid;
  gap: 12px;
}

.placeholder {
  padding: 24px;
  color: var(--muted, #9fb0d3);
  text-align: center;
}
EOF

echo "  ✓ WorkspaceTabs criado"

# ═══════════════════════════════════════════════════════════════
# 4. ATUALIZAR App.tsx (restaurar layout 3 colunas)
# ═══════════════════════════════════════════════════════════════

echo "[4/8] Atualizando App.tsx (layout 3 colunas do wireframe)..."

cat <<'EOF' > packages/ui/src/App.tsx
import { Sidebar } from './components/Sidebar.js';
import { WorkspaceTabs } from './components/WorkspaceTabs.js';
import { DiscoveryNotes } from './components/DiscoveryNotes.js';
import styles from './App.module.css';

/**
 * App - Componente principal da Mini-IDE UI
 * 
 * Implementa o layout base de 3 colunas conforme wireframe MiniIDE-Explore.html:
 * - Sidebar esquerda: árvore do projeto
 * - Painel central: abas internas (Overview, HUs, Docs, Analyze, etc.)
 * - Painel direito: Discovery Notes
 */
function App() {
  return (
    <div className={styles.app}>
      <header className={styles.header}>
        <div className={styles.headerLeft}>
          <h1 className={styles.title}>Mini IDE</h1>
          <span className={styles.badge}>Analysis Agent</span>
          <span className={styles.badgeOk}>Explorando</span>
        </div>
        <div className={styles.headerRight}>
          <button className={styles.btn}>Provisionar</button>
          <button className={styles.btnPrimary}>Executar</button>
          <button className={styles.btn}>Quick Start</button>
        </div>
      </header>

      <main className={styles.main}>
        <div className={`${styles.panel} ${styles.panelLeft}`}>
          <Sidebar />
        </div>

        <div className={`${styles.panel} ${styles.panelCenter}`}>
          <WorkspaceTabs />
        </div>

        <div className={`${styles.panel} ${styles.panelRight}`}>
          <DiscoveryNotes />
        </div>
      </main>

      <footer className={styles.footer}>
        <textarea
          className={styles.chatInput}
          placeholder="Digite em linguagem natural… (Ctrl+Enter para enviar)"
          rows={3}
        />
        <div className={styles.footerActions}>
          <button className={styles.btn}>Anexar</button>
          <button className={styles.btnPrimary}>Enviar</button>
        </div>
      </footer>
    </div>
  );
}

export default App;
EOF

echo "  ✓ App.tsx atualizado"

# ═══════════════════════════════════════════════════════════════
# 5. ATUALIZAR App.module.css (estilos do wireframe)
# ═══════════════════════════════════════════════════════════════

echo "[5/8] Atualizando App.module.css (estilos 3 colunas)..."

cat <<'EOF' > packages/ui/src/App.module.css
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

.app {
  display: grid;
  grid-template-rows: 56px 1fr 126px;
  height: 100vh;
  background: var(--bg);
  color: var(--text);
}

/* Header */
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 16px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.02), transparent), var(--panel);
  border-bottom: 1px solid var(--border);
  box-shadow: var(--shadow);
  position: sticky;
  top: 0;
  z-index: 10;
}

.headerLeft {
  display: flex;
  align-items: center;
  gap: 12px;
}

.headerRight {
  display: flex;
  align-items: center;
  gap: 8px;
}

.title {
  font-size: 18px;
  font-weight: 700;
  margin: 0;
  letter-spacing: 0.2px;
}

.badge {
  padding: 6px 10px;
  border-radius: 999px;
  background: var(--chip);
  border: 1px solid var(--border);
  color: var(--muted);
  font-size: 13px;
}

.badgeOk {
  padding: 6px 10px;
  border-radius: 999px;
  background: rgba(71, 230, 161, 0.15);
  border: 1px solid rgba(71, 230, 161, 0.4);
  color: var(--ok);
  font-size: 13px;
}

.btn {
  background: var(--panel-2);
  border: 1px solid var(--border);
  color: var(--text);
  height: 32px;
  padding: 0 12px;
  border-radius: 10px;
  cursor: pointer;
  font-size: 13px;
  font-family: inherit;
}

.btnPrimary {
  background: linear-gradient(180deg, var(--brand-2), var(--brand));
  color: white;
  border: none;
  height: 32px;
  padding: 0 16px;
  border-radius: 10px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  font-family: inherit;
}

/* Main - 3 colunas */
.main {
  display: grid;
  grid-template-columns: 280px 1fr 360px;
  gap: 14px;
  padding: 14px;
  overflow: hidden;
}

.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.panelLeft {
  /* Sidebar */
}

.panelCenter {
  /* Workspace */
}

.panelRight {
  /* Discovery Notes */
}

/* Footer */
.footer {
  border-top: 1px solid var(--border);
  background: var(--panel);
  padding: 10px 14px;
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 10px;
  align-items: center;
}

.chatInput {
  width: 100%;
  min-height: 84px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--panel-2);
  color: var(--text);
  padding: 10px;
  resize: none;
  outline: none;
  font-family: inherit;
  font-size: 14px;
}

.chatInput:focus {
  border-color: var(--brand);
}

.footerActions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

@media (max-width: 1200px) {
  .main {
    grid-template-columns: 240px 1fr 300px;
  }
}

@media (max-width: 900px) {
  .main {
    grid-template-columns: 1fr;
    grid-template-rows: auto 1fr auto;
  }

  .panelLeft,
  .panelRight {
    max-height: 200px;
  }
}
EOF

echo "  ✓ App.module.css atualizado"

# ═══════════════════════════════════════════════════════════════
# 6. REMOVER componentes obsoletos (abas Explore/Design/Execute)
# ═══════════════════════════════════════════════════════════════

echo "[6/8] Removendo componentes obsoletos (TabsNavigation antigo)..."

# Mover para backup ao invés de deletar
mkdir -p packages/ui/src/components/deprecated
mv packages/ui/src/components/TabsNavigation.tsx packages/ui/src/components/deprecated/ 2>/dev/null || true
mv packages/ui/src/components/TabsNavigation.module.css packages/ui/src/components/deprecated/ 2>/dev/null || true
mv packages/ui/src/components/TabsNavigation.spec.tsx packages/ui/src/components/deprecated/ 2>/dev/null || true
mv packages/ui/src/components/tabs packages/ui/src/components/deprecated/ 2>/dev/null || true

echo "  ✓ Componentes antigos movidos para /deprecated"

# ═══════════════════════════════════════════════════════════════
# 7. ATUALIZAR App.spec.tsx (testes do layout 3 colunas)
# ═══════════════════════════════════════════════════════════════

echo "[7/8] Atualizando App.spec.tsx (testes do wireframe)..."

cat <<'EOF' > packages/ui/test/App.spec.tsx
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import App from '../src/App.js';

describe('App - Layout Wireframe MiniIDE-Explore.html', () => {
  beforeEach(() => {
    globalThis.fetch = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Header', () => {
    it('deve renderizar título "Mini IDE"', () => {
      render(<App />);
      expect(screen.getByText('Mini IDE')).toBeInTheDocument();
    });

    it('deve renderizar badges "Analysis Agent" e "Explorando"', () => {
      render(<App />);
      expect(screen.getByText('Analysis Agent')).toBeInTheDocument();
      expect(screen.getByText('Explorando')).toBeInTheDocument();
    });

    it('deve renderizar botões de ação', () => {
      render(<App />);
      expect(screen.getByText('Provisionar')).toBeInTheDocument();
      expect(screen.getByText('Executar')).toBeInTheDocument();
      expect(screen.getByText('Quick Start')).toBeInTheDocument();
    });
  });

  describe('Layout 3 Colunas', () => {
    it('deve renderizar sidebar esquerda com "Projeto Atual"', () => {
      render(<App />);
      expect(screen.getByText('Projeto Atual')).toBeInTheDocument();
    });

    it('deve renderizar árvore do projeto na sidebar', () => {
      render(<App />);
      expect(screen.getByPlaceholderText(/filtrar árvore/i)).toBeInTheDocument();
      expect(screen.getByText('apps/')).toBeInTheDocument();
      expect(screen.getByText('packages/')).toBeInTheDocument();
    });

    it('deve renderizar painel central com abas internas', () => {
      render(<App />);
      expect(screen.getByText('Overview')).toBeInTheDocument();
      expect(screen.getByText('HUs')).toBeInTheDocument();
      expect(screen.getByText('Analyze')).toBeInTheDocument();
    });

    it('deve renderizar Discovery Notes no painel direito', () => {
      render(<App />);
      expect(screen.getByText('Discovery Notes')).toBeInTheDocument();
      expect(screen.getByText('Intenção')).toBeInTheDocument();
      expect(screen.getByText('Requisitos')).toBeInTheDocument();
      expect(screen.getByText('Restrições')).toBeInTheDocument();
    });
  });

  describe('Abas Internas do Workspace', () => {
    it('deve iniciar com aba Overview ativa', () => {
      render(<App />);
      expect(screen.getByText(/Bem-vindo à Mini IDE/i)).toBeInTheDocument();
    });

    it('deve trocar para aba Analyze ao clicar', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      expect(screen.getByText('Analyze Endpoint')).toBeInTheDocument();
    });

    it('deve mostrar todas as 10 abas', () => {
      render(<App />);
      
      expect(screen.getByRole('tab', { name: 'Overview' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'HUs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Docs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Testes' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Analyze' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: /Personas & Plano/i })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Timeline' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Runs' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Métricas' })).toBeInTheDocument();
      expect(screen.getByRole('tab', { name: 'Outputs' })).toBeInTheDocument();
    });
  });

  describe('Footer com Chat', () => {
    it('deve renderizar textarea de chat', () => {
      render(<App />);
      expect(screen.getByPlaceholderText(/digite em linguagem natural/i)).toBeInTheDocument();
    });

    it('deve renderizar botões Anexar e Enviar', () => {
      render(<App />);
      const buttons = screen.getAllByText('Anexar');
      expect(buttons.length).toBeGreaterThan(0);
      
      const sendButtons = screen.getAllByText('Enviar');
      expect(sendButtons.length).toBeGreaterThan(0);
    });
  });

  describe('Integração com componentes existentes', () => {
    it('deve integrar ServerStatus na aba Analyze', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      // ServerStatus renderiza "Verificando..." inicialmente
      expect(screen.getByText(/verificando/i) || screen.getByText(/servidor/i)).toBeInTheDocument();
    });

    it('deve integrar AnalyzePlayground na aba Analyze', () => {
      render(<App />);
      
      const analyzeTab = screen.getByRole('tab', { name: 'Analyze' });
      fireEvent.click(analyzeTab);

      expect(screen.getByPlaceholderText(/digite o texto/i)).toBeInTheDocument();
    });
  });
});
EOF

echo "  ✓ App.spec.tsx atualizado"

# ═══════════════════════════════════════════════════════════════
# 8. VALIDAÇÃO: Rodar pipeline
# ═══════════════════════════════════════════════════════════════

echo "[8/8] Executando validação (lint + test + typecheck + build)..."
echo ""

# Lint
echo "→ pnpm lint..."
if ! pnpm lint; then
  echo "❌ LINT FALHOU"
  exit 1
fi
echo "✅ Lint passou"
echo ""

# Test
echo "→ pnpm test..."
if ! pnpm test; then
  echo "❌ TESTES FALHARAM"
  exit 1
fi
echo "✅ Testes passaram"
echo ""

# TypeCheck
echo "→ pnpm typecheck..."
if ! pnpm typecheck; then
  echo "❌ TYPECHECK FALHOU"
  exit 1
fi
echo "✅ TypeCheck passou"
echo ""

# Build
echo "→ pnpm build..."
if ! pnpm build; then
  echo "❌ BUILD FALHOU"
  exit 1
fi
echo "✅ Build passou"
echo ""

# ═══════════════════════════════════════════════════════════════
# RESUMO
# ═══════════════════════════════════════════════════════════════

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    CORREÇÃO CONCLUÍDA ✓                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ WIREFRAME RESTAURADO - MiniIDE-Explore.html"
echo ""
echo "Estrutura implementada:"
echo "  ├─ Header: Mini IDE | Analysis Agent | Explorando"
echo "  ├─ Main (3 colunas):"
echo "  │   ├─ Sidebar esquerda: Projeto Atual + árvore"
echo "  │   ├─ Painel central: 10 abas internas (Overview, HUs, Docs, Analyze...)"
echo "  │   └─ Painel direito: Discovery Notes"
echo "  └─ Footer: Chat (textarea + botões)"
echo ""
echo "Componentes criados/atualizados:"
echo "  ✓ Sidebar.tsx + Sidebar.module.css"
echo "  ✓ DiscoveryNotes.tsx + DiscoveryNotes.module.css"
echo "  ✓ WorkspaceTabs.tsx + WorkspaceTabs.module.css"
echo "  ✓ App.tsx (layout 3 colunas)"
echo "  ✓ App.module.css (estilos do wireframe)"
echo "  ✓ App.spec.tsx (14 testes do wireframe)"
echo ""
echo "Funcionalidades preservadas:"
echo "  ✓ ServerStatus (na aba Analyze)"
echo "  ✓ AnalyzePlayground (na aba Analyze)"
echo "  ✓ Todos os testes passando"
echo ""
echo "Pipeline: ✅ lint | ✅ test | ✅ typecheck | ✅ build"
echo ""
echo "[info] Correção HU-UI-Fix-Align-Wireframe-Explore concluída!"
