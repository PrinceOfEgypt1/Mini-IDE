// packages/ui/src/App.tsx
import type React from 'react';
import { useCallback, useState } from 'react';
import { Sidebar } from './components/Sidebar.js';
import { WorkspaceTabs } from './components/WorkspaceTabs.js';
import { DiscoveryNotes } from './components/DiscoveryNotes.js';
import { ToastProvider } from './contexts/ToastProvider.js';
import { useToast } from './hooks/useToast.js';
import { Button } from './components/common/Button.js';
import styles from './App.module.css';

/**
 * AppLayout - Conteúdo principal da Mini-IDE UI.
 *
 * Este componente assume que está sendo renderizado DENTRO de um ToastProvider.
 */
function AppLayout() {
  const { showSuccess, showError, showInfo } = useToast();
  const [chatMessage, setChatMessage] = useState('');

  const handleProvision = useCallback(() => {
    showInfo('Provisionamento de workspace ainda será implementado.');
  }, [showInfo]);

  const handleExecute = useCallback(() => {
    showSuccess('Execução disparada (mock). Pipeline de agentes será conectado futuramente.');
  }, [showSuccess]);

  const handleQuickStart = useCallback(() => {
    showSuccess('Quick Start: carregando fluxo guiado (mock).');
  }, [showSuccess]);

  const handleAttach = useCallback(() => {
    showInfo('Funcionalidade de anexar arquivos ainda será conectada.');
  }, [showInfo]);

  const handleSend = useCallback(() => {
    const trimmed = chatMessage.trim();

    if (!trimmed) {
      showError('Digite uma mensagem antes de enviar.');
      return;
    }

    showSuccess('Mensagem enviada ao Analysis Agent (mock).');
    setChatMessage('');
  }, [chatMessage, showError, showSuccess]);

  const handleChatKeyDown: React.KeyboardEventHandler<HTMLTextAreaElement> = useCallback(
    (event) => {
      if (event.key === 'Enter' && (event.ctrlKey || event.metaKey)) {
        event.preventDefault();
        handleSend();
      }
    },
    [handleSend],
  );

  return (
    <div className={styles.app}>
      <header className={styles.header}>
        <div className={styles.headerLeft}>
          <h1 className={styles.title}>Mini IDE</h1>
          <span className={styles.badge}>Analysis Agent</span>
          <span className={styles.badgeOk}>Explorando</span>
        </div>
        <div className={styles.headerRight}>
          <Button variant="secondary" onClick={handleProvision}>
            Provisionar
          </Button>
          <Button variant="primary" onClick={handleExecute}>
            Executar
          </Button>
          <Button variant="secondary" onClick={handleQuickStart}>
            Quick Start
          </Button>
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
          value={chatMessage}
          onChange={(event) => setChatMessage(event.target.value)}
          onKeyDown={handleChatKeyDown}
        />
        <div className={styles.footerActions}>
          <Button variant="secondary" onClick={handleAttach}>
            Anexar
          </Button>
          <Button variant="primary" onClick={handleSend}>
            Enviar
          </Button>
        </div>
      </footer>
    </div>
  );
}

/**
 * App - Entry point da UI, encapsulada pelo ToastProvider.
 */
function App() {
  return (
    <ToastProvider>
      <AppLayout />
    </ToastProvider>
  );
}

export default App;
