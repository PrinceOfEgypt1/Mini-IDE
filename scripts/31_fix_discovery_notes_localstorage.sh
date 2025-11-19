#!/usr/bin/env bash
# ==============================================================================
# Script: 31_fix_discovery_notes_localstorage.sh
# Objetivo:
#   - Reescrever DiscoveryNotes.tsx para não usar o global "localStorage" cru,
#     evitando erro ESLint "no-undef" e deixando o código seguro para ambientes
#     sem DOM (SSR, testes, etc.).
#   - Validar a UI (@mini-ide/ui) com lint, test, typecheck e build.
# ==============================================================================

set -euo pipefail

echo "============================================="
echo " MINI-IDE :: Fix DiscoveryNotes (localStorage)"
echo "============================================="
echo ""

# 1) Garantir que estamos na raiz
if [ ! -f "42_pipeline_checklist.sh" ] || [ ! -d "packages/ui" ]; then
  echo "[erro] Este script deve ser executado na raiz do projeto Mini-IDE."
  echo "       Exemplo: cd ~/workspace/Mini-IDE"
  exit 1
fi

DISCOVERY_FILE="packages/ui/src/components/discovery/DiscoveryNotes.tsx"

echo "[info] Reescrevendo $DISCOVERY_FILE com acesso seguro ao storage..."

cat > "$DISCOVERY_FILE" << 'EOF'
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
 * Obtém uma referência segura a localStorage (quando disponível).
 *
 * - Usa globalThis para evitar depender diretamente de "window" ou "localStorage"
 * - Retorna null em ambientes sem DOM (Node, SSR, etc.)
 */
function getSafeStorage(): Storage | null {
  try {
    if (typeof globalThis === 'undefined') {
      return null;
    }

    const maybeStorage = (globalThis as unknown as { localStorage?: Storage }).localStorage;

    if (!maybeStorage) {
      return null;
    }

    // Opcionalmente poderíamos testar permissões aqui (setItem/removeItem), mas
    // para o cenário da Mini-IDE isso é suficiente.
    return maybeStorage;
  } catch {
    return null;
  }
}

/**
 * Carrega notas do storage com tratamento de erros
 */
function loadNotesFromStorage(storage: Storage | null): DiscoveryNotesData {
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
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn('[DiscoveryNotes] Erro ao carregar do storage:', error);
    return DEFAULT_NOTES;
  }
}

/**
 * Salva notas no storage com tratamento de erros
 */
function saveNotesToStorage(storage: Storage | null, notes: DiscoveryNotesData): void {
  if (!storage) {
    return;
  }

  try {
    storage.setItem(STORAGE_KEY, JSON.stringify(notes));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[DiscoveryNotes] Erro ao salvar no storage:', error);
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
  const [storage] = useState<Storage | null>(() => getSafeStorage());

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
  const handleFieldChange = useCallback(
    (field: keyof DiscoveryNotesData, value: string) => {
      setNotes((prev) => ({
        ...prev,
        [field]: value,
      }));
      setLastSaved(new Date());
    },
    [],
  );

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
EOF

echo "[ok] DiscoveryNotes.tsx reescrito com acesso seguro ao storage"
echo ""

# 2) Rodar pipeline da UI
echo "-----------------------------------------"
echo "[info] Rodando lint da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui lint
echo "[ok] Lint da UI passou"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando testes da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui test
echo "[ok] Testes da UI passaram"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando typecheck da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui typecheck
echo "[ok] Typecheck da UI passou"
echo ""

echo "-----------------------------------------"
echo "[info] Rodando build da UI (@mini-ide/ui)..."
pnpm --filter @mini-ide/ui build
echo "[ok] Build da UI passou"
echo ""

echo "============================================="
echo " ✅ Script concluído com sucesso"
echo " - DiscoveryNotes.tsx sem 'localStorage' no-undef"
echo " - UI: lint / test / typecheck / build OK"
echo "============================================="
