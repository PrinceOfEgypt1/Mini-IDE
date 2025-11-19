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
        <p className={styles.subtitle}>Coleta automática do que surge no chat</p>
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
