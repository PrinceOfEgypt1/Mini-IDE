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
        <div className={styles.treeItem}> agent-dashboard/</div>
        <div className={styles.treeItem}> src/</div>
        <div className={styles.treeItem}>packages/</div>
        <div className={styles.treeItem}> engine/</div>
        <div className={styles.treeItem}> src/</div>
        <div className={styles.treeItem}>services/</div>
        <div className={styles.treeItem}> analysis-agent/</div>
        <div className={styles.treeItem}> src/</div>
        <div className={styles.treeItem}>docs/</div>
        <div className={styles.treeItem}> HUs/</div>
        <div className={styles.treeItem}> ADRs/</div>
        <div className={styles.treeItem}> SSoT/</div>
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
