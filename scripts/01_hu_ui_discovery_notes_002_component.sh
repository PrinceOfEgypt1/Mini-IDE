#!/usr/bin/env bash
# ==============================================================================
# Script: 01_hu_ui_discovery_notes_002_component.sh
# HU: HU-UI-Discovery-Notes-002 – Discovery Notes Evoluídas
# ==============================================================================
# Objetivo:
#   Implementar Discovery Notes evoluídas no painel direito (~360px) da UI
#   Explore, com campos editáveis e persistência em localStorage.
#
# Arquivos afetados:
#   - packages/ui/src/components/discovery/DiscoveryNotes.tsx (reescrito completo)
#   - packages/ui/src/components/discovery/DiscoveryNotes.module.css (reescrito completo)
#
# Premissas:
#   - Layout de 3 colunas permanece intacto
#   - Painel direito continua em ~360px
#   - Persistência via localStorage com chave específica
#   - TypeScript strict mode
#
# Riscos:
#   - Nenhum risco de quebra de layout (painel direito já existe)
#   - localStorage pode estar desabilitado em alguns navegadores (tratado com try/catch)
#
# Como reverter:
#   git checkout HEAD -- packages/ui/src/components/discovery/DiscoveryNotes.tsx
#   git checkout HEAD -- packages/ui/src/components/discovery/DiscoveryNotes.module.css
# ==============================================================================

set -euo pipefail

echo "[info] Iniciando implementação da HU-UI-Discovery-Notes-002..."

# ------------------------------------------------------------------------------  
# 0. Garantir que o diretório de destino exista
# ------------------------------------------------------------------------------  
TARGET_DIR="packages/ui/src/components/discovery"
mkdir -p "$TARGET_DIR"

# ------------------------------------------------------------------------------  
# 1. DiscoveryNotes.tsx - Componente evoluído com edição e persistência
# ------------------------------------------------------------------------------  
cat > "$TARGET_DIR/DiscoveryNotes.tsx" << 'EOF'
/**
 * @file DiscoveryNotes.tsx
 * @description Discovery Notes evoluídas - Editor assistido com persistência local
 * @module @mini-ide/ui/components/discovery
 */

import { useState, useEffect, useCallback } from 'react';
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
 * Chave de persistência no localStorage
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
 * Carrega notas do localStorage com tratamento de erros
 */
function loadNotesFromStorage(): DiscoveryNotesData {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return DEFAULT_NOTES;
    
    const parsed = JSON.parse(stored) as DiscoveryNotesData;
    return {
      intention: parsed.intention || '',
      requirements: parsed.requirements || '',
      constraints: parsed.constraints || '',
      examples: parsed.examples || '',
    };
  } catch (error) {
    console.warn('[DiscoveryNotes] Erro ao carregar do localStorage:', error);
    return DEFAULT_NOTES;
  }
}

/**
 * Salva notas no localStorage com tratamento de erros
 */
function saveNotesToStorage(notes: DiscoveryNotesData): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(notes));
  } catch (error) {
    console.error('[DiscoveryNotes] Erro ao salvar no localStorage:', error);
  }
}

/**
 * Componente DiscoveryNotes - Painel direito da UI Explore
 * 
 * Funcionalidades:
 * - Edição em tempo real de 4 campos (Intenção, Requisitos, Restrições, Exemplos)
 * - Persistência automática em localStorage
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

  // Carrega notas do localStorage na montagem
  useEffect(() => {
    const loaded = loadNotesFromStorage();
    setNotes(loaded);
  }, []);

  // Salva notas automaticamente quando mudam (debounce implícito via useEffect)
  useEffect(() => {
    if (lastSaved !== null) {
      saveNotesToStorage(notes);
    }
  }, [notes, lastSaved]);

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
EOF

echo "[ok] DiscoveryNotes.tsx criado com sucesso"

# ------------------------------------------------------------------------------  
# 2. DiscoveryNotes.module.css - Estilos do componente
# ------------------------------------------------------------------------------  
cat > "$TARGET_DIR/DiscoveryNotes.module.css" << 'EOF'
/**
 * @file DiscoveryNotes.module.css
 * @description Estilos para o componente DiscoveryNotes (painel direito)
 */

.discoveryNotes {
  display: flex;
  flex-direction: column;
  gap: 12px;
  height: 100%;
}

.header {
  margin-bottom: 4px;
}

.title {
  margin: 0 0 4px 0;
  font-size: 16px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.subtitle {
  margin: 0;
  font-size: 13px;
  color: var(--muted, #9fb0d3);
  line-height: 1.4;
}

.notesContainer {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 10px;
  overflow-y: auto;
  padding-right: 4px;
}

.noteField {
  background: var(--panel-2, #101727);
  border: 1px solid var(--border, #24304a);
  border-radius: 10px;
  padding: 10px;
  transition: border-color 0.2s ease;
}

.noteField:focus-within {
  border-color: var(--brand, #4ba3ff);
}

.noteTitle {
  margin: 0 0 8px 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--text, #e6ecff);
}

.noteTextarea {
  width: 100%;
  min-height: 80px;
  padding: 8px;
  background: var(--panel-3, #0c1323);
  border: 1px solid var(--border, #24304a);
  border-radius: 8px;
  color: var(--text, #e6ecff);
  font-family: inherit;
  font-size: 13px;
  line-height: 1.5;
  resize: vertical;
  outline: none;
  transition: border-color 0.2s ease, background-color 0.2s ease;
}

.noteTextarea:focus {
  border-color: var(--brand, #4ba3ff);
  background: var(--panel-2, #101727);
}

.noteTextarea::placeholder {
  color: var(--muted, #9fb0d3);
  opacity: 0.6;
}

.footer {
  padding-top: 8px;
  border-top: 1px solid var(--border, #24304a);
}

.savedIndicator {
  font-size: 12px;
  color: var(--ok, #47e6a1);
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Scrollbar customizada (apenas para navegadores Webkit) */
.notesContainer::-webkit-scrollbar {
  width: 6px;
}

.notesContainer::-webkit-scrollbar-track {
  background: transparent;
}

.notesContainer::-webkit-scrollbar-thumb {
  background: var(--border, #24304a);
  border-radius: 3px;
}

.notesContainer::-webkit-scrollbar-thumb:hover {
  background: var(--muted, #9fb0d3);
}

/* Responsividade para telas menores */
@media (max-width: 900px) {
  .noteTextarea {
    min-height: 60px;
  }
}
EOF

echo "[ok] DiscoveryNotes.module.css criado com sucesso"

# ------------------------------------------------------------------------------  
# Sumário
# ------------------------------------------------------------------------------  
echo ""
echo "========================================="
echo "✅ HU-UI-Discovery-Notes-002 implementada"
echo "========================================="
echo "Arquivos criados/modificados:"
echo "  - $TARGET_DIR/DiscoveryNotes.tsx"
echo "  - $TARGET_DIR/DiscoveryNotes.module.css"
echo ""
echo "Funcionalidades:"
echo "  ✓ Campos editáveis (Intenção, Requisitos, Restrições, Exemplos)"
echo "  ✓ Persistência automática em localStorage"
echo "  ✓ Recuperação de notas ao recarregar página"
echo "  ✓ Indicador de salvamento automático"
echo "  ✓ Layout preservado (painel direito ~360px)"
echo ""
echo "Próximos passos:"
echo "  1. Execute o script de testes: 02_hu_ui_discovery_notes_002_test.sh"
echo "  2. Rode pnpm lint e pnpm test"
echo "========================================="
