/**
 * @file DiscoveryNotes.tsx
 * @description Discovery Notes evoluídas - Editor assistido com persistência local
 * @module @mini-ide/ui/components/discovery
 */

import { useCallback, useEffect, useState } from 'react';
import styles from './DiscoveryNotes.module.css';

/**
 * Estrutura das notas de descoberta
 */
export interface DiscoveryNotesData {
  intention: string;
  requirements: string;
  constraints: string;
  examples: string;
}

/**
 * Tipo mínimo de storage que precisamos (getItem/setItem)
 * Não dependemos do tipo global "Storage" para evitar no-undef no ESLint.
 */
type SafeStorage = {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
} | null;

/**
 * Chave de persistência no storage
 */
const STORAGE_KEY = 'mini-ide:discovery-notes:v1';

/**
 * Valor padrão para notas vazias
 */
const DEFAULT_NOTES: DiscoveryNotesData = {
  intention: '',
  requirements: '',
  constraints: '',
  examples: '',
};

/**
 * Obtém uma referência segura a um storage estilo localStorage (quando disponível).
 *
 * - Usa globalThis para não depender diretamente de "window" ou "localStorage"
 * - Retorna null em ambientes sem DOM (Node, SSR, etc.)
 */
function getSafeStorage(): SafeStorage {
  try {
    if (typeof globalThis === 'undefined') {
      return null;
    }

    const maybeStorage = (globalThis as unknown as { localStorage?: unknown }).localStorage;

    if (!maybeStorage) {
      return null;
    }

    const storage = maybeStorage as { getItem?: unknown; setItem?: unknown };

    if (typeof storage.getItem !== 'function' || typeof storage.setItem !== 'function') {
      return null;
    }

    return storage as SafeStorage;
  } catch {
    return null;
  }
}

/**
 * Carrega notas do storage com tratamento de erros
 */
function loadNotesFromStorage(storage: SafeStorage): DiscoveryNotesData {
  if (!storage) {
    return DEFAULT_NOTES;
  }

  try {
    const stored = storage.getItem(STORAGE_KEY);
    if (!stored) {
      return DEFAULT_NOTES;
    }

    const parsed = JSON.parse(stored) as Partial<DiscoveryNotesData>;

    return {
      intention: parsed.intention ?? '',
      requirements: parsed.requirements ?? '',
      constraints: parsed.constraints ?? '',
      examples: parsed.examples ?? '',
    };
  } catch {
    return DEFAULT_NOTES;
  }
}

/**
 * Salva notas no storage com tratamento de erros
 */
function saveNotesToStorage(storage: SafeStorage, notes: DiscoveryNotesData): void {
  if (!storage) {
    return;
  }

  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(notes));
  } catch {
    // Silenciosamente ignora erro de storage (quota, permissões, etc.)
  }
}

/**
 * Componente DiscoveryNotes - Painel direito da UI Explore
 *
 * Funcionalidades:
 * - Edição em tempo real de 4 campos (Intenção, Requisitos, Restrições, Exemplos)
 * - Persistência automática em localStorage (quando disponível)
 * - Recuperação de notas ao recarregar página
 * - Tratamento de erros de storage
 *
 * Layout:
 * - Permanece no painel direito (~360px) conforme wireframe
 * - Respeita estrutura de 3 colunas
 */
export function DiscoveryNotes() {
  const [notes, setNotes] = useState<DiscoveryNotesData>(DEFAULT_NOTES);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);

  // Referência de storage segura (globalThis.localStorage quando existir)
  const [storage] = useState<SafeStorage>(() => getSafeStorage());

  // Carrega notas do storage na montagem
  useEffect(() => {
    const loaded = loadNotesFromStorage(storage);
    setNotes(loaded);
  }, [storage]);

  // Salva notas automaticamente quando mudam e já houve pelo menos um save
  useEffect(() => {
    if (lastSaved !== null) {
      saveNotesToStorage(storage, notes);
    }
  }, [notes, storage, lastSaved]);

  /**
   * Handler genérico para atualização de campo
   */
  const handleFieldChange = useCallback((field: keyof DiscoveryNotesData, value: string) => {
    setNotes((prev) => ({
      ...prev,
      [field]: value,
    }));
    setLastSaved(new Date());
  }, []);

  return (
    <div className={styles.discoveryNotes}>
      <div className={styles.header}>
        <h3 className={styles.title}>Discovery Notes</h3>
        <p className={styles.subtitle}>
          Coleta automática do que surge no chat (intenção, requisitos, restrições, exemplos).
        </p>
      </div>

      <div className={styles.notesContainer}>
        {/* Campo: Intenção */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Intenção</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.intention}
            onChange={(e) => handleFieldChange('intention', e.target.value)}
            placeholder="Descreva a intenção principal do que você está explorando..."
            rows={4}
            aria-label="Campo de intenção"
          />
        </div>

        {/* Campo: Requisitos */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Requisitos</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.requirements}
            onChange={(e) => handleFieldChange('requirements', e.target.value)}
            placeholder="Liste requisitos funcionais e não funcionais..."
            rows={4}
            aria-label="Campo de requisitos"
          />
        </div>

        {/* Campo: Restrições */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Restrições</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.constraints}
            onChange={(e) => handleFieldChange('constraints', e.target.value)}
            placeholder="Descreva limitações, bloqueios ou restrições técnicas..."
            rows={4}
            aria-label="Campo de restrições"
          />
        </div>

        {/* Campo: Exemplos & Referências */}
        <div className={styles.noteField}>
          <h4 className={styles.noteTitle}>Exemplos & Referências</h4>
          <textarea
            className={styles.noteTextarea}
            value={notes.examples}
            onChange={(e) => handleFieldChange('examples', e.target.value)}
            placeholder="Adicione links, exemplos de código, referências externas..."
            rows={4}
            aria-label="Campo de exemplos e referências"
          />
        </div>
      </div>

      {lastSaved && (
        <div className={styles.footer}>
          <span className={styles.savedIndicator}>
            ✓ Salvo automaticamente às {lastSaved.toLocaleTimeString()}
          </span>
        </div>
      )}
    </div>
  );
}
