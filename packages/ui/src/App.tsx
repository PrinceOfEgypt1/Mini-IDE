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
