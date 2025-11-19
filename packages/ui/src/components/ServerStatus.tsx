import { useState, useEffect } from 'react';
import { getServerConfig } from '../config/server.js';
import styles from './ServerStatus.module.css';

type ServerState = 'checking' | 'online' | 'offline' | 'error';

interface ServerStatusProps {
  pollInterval?: number;
}

/**
 * ServerStatus - Indicador visual do status do servidor
 *
 * Verifica periodicamente o endpoint /healthz e exibe o status.
 */
export function ServerStatus({ pollInterval = 30000 }: ServerStatusProps) {
  const [status, setStatus] = useState<ServerState>('checking');

  useEffect(() => {
    const checkHealth = async (): Promise<void> => {
      try {
        const config = getServerConfig();
        const response = await fetch(`${config.baseUrl}/healthz`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        if (response.ok) {
          setStatus('online');
        } else {
          setStatus('offline');
        }
      } catch (error) {
        console.error('[ServerStatus] Erro ao verificar /healthz:', error);
        setStatus('error');
      }
    };

    // Primeira verificação imediata
    void checkHealth();

    // Configurar polling
    const intervalId = setInterval(() => {
      void checkHealth();
    }, pollInterval);

    return () => clearInterval(intervalId);
  }, [pollInterval]);

  const getStatusText = (): string => {
    switch (status) {
      case 'checking':
        return 'Verificando servidor...';
      case 'online':
        return 'Servidor disponível';
      case 'offline':
        return 'Servidor offline';
      case 'error':
        return 'Servidor indisponível';
      default:
        return 'Status desconhecido';
    }
  };

  const getStatusClass = (): string => {
    return `${styles.status} ${styles[status]}`;
  };

  return (
    <div className={getStatusClass()} role="status" aria-live="polite" data-testid="server-status">
      <span className={styles.indicator} />
      <span className={styles.text}>{getStatusText()}</span>
    </div>
  );
}
