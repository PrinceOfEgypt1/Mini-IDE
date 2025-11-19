import { useState } from 'react';
import { getServerConfig } from '../config/server.js';
import styles from './AnalyzePlayground.module.css';

interface AnalyzeResponse {
  summary: string;
  inputLength: number;
  outputLength: number;
  tokensUsed: number;
}

/**
 * AnalyzePlayground - Componente para testar o endpoint /analyze
 *
 * Permite enviar texto para análise e visualizar a resposta.
 */
export function AnalyzePlayground() {
  const [text, setText] = useState('');
  const [maxLen, setMaxLen] = useState(100);
  const [response, setResponse] = useState<AnalyzeResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async (): Promise<void> => {
    if (!text.trim()) {
      setError('Por favor, digite algum texto');
      return;
    }

    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      const config = getServerConfig();
      const res = await fetch(`${config.baseUrl}/analyze`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: text.trim(),
          maxLen,
        }),
      });

      if (!res.ok) {
        let errorMsg = `Erro ${res.status}`;
        try {
          const errorData = (await res.json()) as { error?: string };
          if (errorData.error) {
            errorMsg = errorData.error;
          }
        } catch {
          // Se não conseguir parsear JSON, usa mensagem padrão
        }
        throw new Error(errorMsg);
      }

      const data = (await res.json()) as AnalyzeResponse;
      setResponse(data);
    } catch (err) {
      console.error('[AnalyzePlayground] Erro ao analisar:', err);
      if (err instanceof Error) {
        setError(err.message);
      } else {
        setError('Erro desconhecido ao analisar texto');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.playground}>
      <div className={styles.inputGroup}>
        <label htmlFor="analyze-text" className={styles.label}>
          Texto para análise:
        </label>
        <textarea
          id="analyze-text"
          className={styles.textarea}
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Digite o texto que deseja analisar..."
          rows={6}
          disabled={loading}
        />
      </div>

      <div className={styles.inputGroup}>
        <label htmlFor="analyze-maxlen" className={styles.label}>
          Comprimento máximo da resposta:
        </label>
        <input
          id="analyze-maxlen"
          type="number"
          className={styles.input}
          value={maxLen}
          onChange={(e) => setMaxLen(Number(e.target.value))}
          min={1}
          max={1000}
          disabled={loading}
        />
      </div>

      <button
        className={styles.button}
        onClick={() => {
          void handleAnalyze();
        }}
        disabled={loading || !text.trim()}
      >
        {loading ? 'Analisando...' : 'Analisar'}
      </button>

      {error && (
        <div className={styles.error} role="alert">
          <strong>Erro:</strong> {error}
        </div>
      )}

      {response && (
        <div className={styles.response}>
          <h3 className={styles.responseTitle}>Resultado:</h3>
          <div className={styles.responseContent}>
            <p>
              <strong>Resumo:</strong> {response.summary}
            </p>
            <div className={styles.metrics}>
              <span className={styles.metric}>Entrada: {response.inputLength} chars</span>
              <span className={styles.metric}>Saída: {response.outputLength} chars</span>
              <span className={styles.metric}>Tokens: {response.tokensUsed}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
