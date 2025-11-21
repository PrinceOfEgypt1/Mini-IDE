#!/usr/bin/env bash
# ==============================================================================
# HU-UI-Explore-Interactions-012
# Cria/atualiza componentes de Button + Toast + Provider + hook + testes,
# integrando feedback visual real na interface do Explore Workspace.
#
# ATENÇÃO:
# - Este script SOBRESCREVE os arquivos abaixo em packages/ui:
#   - src/App.tsx
#   - src/components/common/Button.tsx
#   - src/components/common/Button.module.css
#   - src/components/common/Toast.tsx
#   - src/components/common/Toast.module.css
#   - src/components/common/ToastContainer.tsx
#   - src/components/common/ToastContainer.module.css
#   - src/contexts/ToastContext.tsx
#   - src/contexts/ToastProvider.tsx
#   - src/hooks/useToast.ts
#   - test/components/Button.test.tsx
#   - test/components/Toast.test.tsx
#   - test/hooks/useToast.test.tsx
# ==============================================================================

set -euo pipefail

REPO_ROOT="${HOME}/workspace/Mini-IDE"
UI_ROOT="${REPO_ROOT}/packages/ui"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[info]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[warn]${NC} $1"; }
log_error() { echo -e "${RED}[erro]${NC} $1"; }

# ------------------------------------------------------------------------------
# 1) Verificações iniciais
# ------------------------------------------------------------------------------

if [[ ! -d "${REPO_ROOT}" ]]; then
  log_error "Repositório Mini-IDE não encontrado em ${REPO_ROOT}"
  exit 1
fi

if [[ ! -d "${UI_ROOT}" ]]; then
  log_error "Pacote UI não encontrado em ${UI_ROOT}"
  exit 1
fi

log_info "Repositório encontrado em ${REPO_ROOT}"
log_info "Pacote UI encontrado em ${UI_ROOT}"

# ------------------------------------------------------------------------------
# 2) Criar diretórios necessários
# ------------------------------------------------------------------------------

log_info "Criando estrutura de diretórios da UI (se necessário)..."

mkdir -p \
  "${UI_ROOT}/src/components/common" \
  "${UI_ROOT}/src/contexts" \
  "${UI_ROOT}/src/hooks" \
  "${UI_ROOT}/test/components" \
  "${UI_ROOT}/test/hooks"

# ------------------------------------------------------------------------------
# 3) Gerar arquivos de contexto de Toast
# ------------------------------------------------------------------------------

log_info "Escrevendo src/contexts/ToastContext.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/contexts/ToastContext.tsx"
// packages/ui/src/contexts/ToastContext.tsx
import type { ReactNode } from 'react';
import { createContext } from 'react';

export type ToastKind = 'success' | 'error' | 'warning' | 'info';

export interface ToastData {
  id: number;
  type: ToastKind;
  message: string;
}

export interface ToastContextValue {
  toasts: ToastData[];
  showToast: (type: ToastKind, message: string, autoDismissMs?: number) => void;
  showSuccess: (message: string) => void;
  showError: (message: string) => void;
  showInfo: (message: string) => void;
  showWarning: (message: string) => void;
  removeToast: (id: number) => void;
}

export const ToastContext = createContext<ToastContextValue | undefined>(undefined);

export interface ToastProviderBaseProps {
  children: ReactNode;
}
EOF

log_info "Escrevendo src/contexts/ToastProvider.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/contexts/ToastProvider.tsx"
// packages/ui/src/contexts/ToastProvider.tsx
import type { ReactNode } from 'react';
import { useCallback, useMemo, useRef, useState } from 'react';
import { ToastContainer } from '../components/common/ToastContainer.js';
import {
  ToastContext,
  type ToastContextValue,
  type ToastData,
  type ToastKind,
} from './ToastContext.js';

export interface ToastProviderProps {
  children: ReactNode;
}

export function ToastProvider({ children }: ToastProviderProps) {
  const [toasts, setToasts] = useState<ToastData[]>([]);
  const nextIdRef = useRef(1);

  const removeToast = useCallback((id: number) => {
    setToasts((current) => current.filter((toast) => toast.id !== id));
  }, []);

  const showToastBase = useCallback(
    (type: ToastKind, message: string, autoDismissMs?: number) => {
      const id = nextIdRef.current;
      nextIdRef.current += 1;

      setToasts((current) => {
        const next = [...current, { id, type, message }];
        // Limite de 3 toasts simultâneos
        if (next.length > 3) {
          return next.slice(next.length - 3);
        }
        return next;
      });

      if (autoDismissMs && autoDismissMs > 0) {
        window.setTimeout(() => {
          removeToast(id);
        }, autoDismissMs);
      }
    },
    [removeToast],
  );

  const contextValue: ToastContextValue = useMemo(
    () => ({
      toasts,
      showToast: showToastBase,
      showSuccess: (message: string) => showToastBase('success', message, 3000),
      showError: (message: string) => showToastBase('error', message, 5000),
      showInfo: (message: string) => showToastBase('info', message, 4000),
      showWarning: (message: string) => showToastBase('warning', message, 4000),
      removeToast,
    }),
    [removeToast, showToastBase, toasts],
  );

  return (
    <ToastContext.Provider value={contextValue}>
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
      {children}
    </ToastContext.Provider>
  );
}
EOF

log_info "Escrevendo src/hooks/useToast.ts..."

cat <<'EOF' > "${UI_ROOT}/src/hooks/useToast.ts"
// packages/ui/src/hooks/useToast.ts
import { useContext } from 'react';
import { ToastContext, type ToastContextValue } from '../contexts/ToastContext.js';

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);

  if (!ctx) {
    throw new Error('useToast must be used within a ToastProvider');
  }

  return ctx;
}
EOF

# ------------------------------------------------------------------------------
# 4) Componentes de Toast + Container
# ------------------------------------------------------------------------------

log_info "Escrevendo src/components/common/Toast.module.css..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/Toast.module.css"
/* packages/ui/src/components/common/Toast.module.css */

.toast {
  min-width: 260px;
  max-width: 360px;
  margin-bottom: 8px;
  padding: 10px 14px;
  border-radius: 6px;
  font-size: 0.9rem;
  color: #f9fafb;
  display: flex;
  align-items: center;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.35);
  border: 1px solid rgba(0, 0, 0, 0.6);
}

.icon {
  margin-right: 8px;
  font-size: 1.1rem;
}

.message {
  flex: 1;
  line-height: 1.3;
}

/* Tipos */

.success {
  background: linear-gradient(135deg, #16a34a, #22c55e);
}

.error {
  background: linear-gradient(135deg, #b91c1c, #ef4444);
}

.warning {
  background: linear-gradient(135deg, #a16207, #eab308);
}

.info {
  background: linear-gradient(135deg, #0369a1, #0ea5e9);
}

.closeButton {
  margin-left: 8px;
  background: transparent;
  border: none;
  color: inherit;
  cursor: pointer;
  font-size: 0.9rem;
  opacity: 0.8;
}

.closeButton:hover {
  opacity: 1;
}
EOF

log_info "Escrevendo src/components/common/Toast.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/Toast.tsx"
// packages/ui/src/components/common/Toast.tsx
import type { ToastData } from '../../contexts/ToastContext.js';
import styles from './Toast.module.css';

export interface ToastProps {
  toast: ToastData;
  onClose: (id: number) => void;
}

const TYPE_ICONS: Record<ToastData['type'], string> = {
  success: '✔',
  error: '✖',
  warning: '⚠',
  info: 'ℹ',
};

export function Toast({ toast, onClose }: ToastProps) {
  const icon = TYPE_ICONS[toast.type];

  return (
    <div
      className={`${styles.toast} ${styles[toast.type]}`}
      role="status"
      aria-live="polite"
      data-type={toast.type}
    >
      <span className={styles.icon} aria-hidden="true">
        {icon}
      </span>
      <span className={styles.message}>{toast.message}</span>
      <button
        type="button"
        className={styles.closeButton}
        onClick={() => onClose(toast.id)}
        aria-label="Fechar notificação"
      >
        ×
      </button>
    </div>
  );
}
EOF

log_info "Escrevendo src/components/common/ToastContainer.module.css..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/ToastContainer.module.css"
/* packages/ui/src/components/common/ToastContainer.module.css */

.container {
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 40;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  pointer-events: none;
}

.container > * {
  pointer-events: auto;
}
EOF

log_info "Escrevendo src/components/common/ToastContainer.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/ToastContainer.tsx"
// packages/ui/src/components/common/ToastContainer.tsx
import type { ToastData } from '../../contexts/ToastContext.js';
import { Toast } from './Toast.js';
import styles from './ToastContainer.module.css';

export interface ToastContainerProps {
  toasts: ToastData[];
  onDismiss: (id: number) => void;
}

export function ToastContainer({ toasts, onDismiss }: ToastContainerProps) {
  if (toasts.length === 0) {
    return null;
  }

  return (
    <div className={styles.container} aria-live="polite" aria-atomic="true">
      {toasts.map((toast) => (
        <Toast key={toast.id} toast={toast} onClose={onDismiss} />
      ))}
    </div>
  );
}
EOF

# ------------------------------------------------------------------------------
# 5) Componente Button
# ------------------------------------------------------------------------------

log_info "Escrevendo src/components/common/Button.module.css..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/Button.module.css"
/* packages/ui/src/components/common/Button.module.css */

.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  border: 1px solid transparent;
  font-size: 0.9rem;
  padding: 8px 14px;
  cursor: pointer;
  transition:
    background-color 0.18s ease,
    color 0.18s ease,
    border-color 0.18s ease,
    box-shadow 0.18s ease,
    transform 0.05s ease;
  outline: none;
  font-weight: 500;
}

.button:focus-visible {
  box-shadow: 0 0 0 2px #22c55e;
}

.primary {
  background: linear-gradient(135deg, #22c55e, #16a34a);
  color: #0f172a;
  border-color: #16a34a;
}

.primary:hover:not(.disabled):not(.loading) {
  background: linear-gradient(135deg, #4ade80, #16a34a);
  transform: translateY(-1px);
}

.secondary {
  background-color: transparent;
  color: #e5e7eb;
  border-color: #4b5563;
}

.secondary:hover:not(.disabled):not(.loading) {
  background-color: rgba(148, 163, 184, 0.12);
  transform: translateY(-1px);
}

.ghost {
  background-color: transparent;
  color: #e5e7eb;
  border-color: transparent;
}

.ghost:hover:not(.disabled):not(.loading) {
  background-color: rgba(148, 163, 184, 0.1);
  transform: translateY(-1px);
}

.loading {
  cursor: wait;
  opacity: 0.85;
}

.disabled {
  cursor: not-allowed;
  opacity: 0.5;
  transform: none;
}

.spinner {
  margin-right: 6px;
  border-radius: 999px;
  width: 14px;
  height: 14px;
  border: 2px solid rgba(15, 23, 42, 0.2);
  border-top-color: #0f172a;
  animation: spin 0.6s linear infinite;
}

.label {
  white-space: nowrap;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
EOF

log_info "Escrevendo src/components/common/Button.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/components/common/Button.tsx"
// packages/ui/src/components/common/Button.tsx
import type { ButtonHTMLAttributes, ReactNode } from 'react';
import styles from './Button.module.css';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost';

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  isLoading?: boolean;
  children: ReactNode;
}

export function Button({
  variant = 'secondary',
  isLoading = false,
  disabled,
  children,
  className,
  type = 'button',
  ...rest
}: ButtonProps) {
  const isDisabled = disabled ?? false;
  const classes = [
    styles.button,
    styles[variant],
    isLoading ? styles.loading : '',
    isDisabled ? styles.disabled : '',
    className ?? '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <button type={type} className={classes} disabled={isDisabled || isLoading} {...rest}>
      {isLoading ? <span className={styles.spinner} aria-hidden="true" /> : null}
      <span className={styles.label}>{children}</span>
    </button>
  );
}
EOF

# ------------------------------------------------------------------------------
# 6) Atualizar App.tsx integrando Toast + Button
# ------------------------------------------------------------------------------

log_info "Escrevendo src/App.tsx..."

cat <<'EOF' > "${UI_ROOT}/src/App.tsx"
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
EOF

# ------------------------------------------------------------------------------
# 7) Testes: Button, Toast, useToast
# ------------------------------------------------------------------------------

log_info "Escrevendo test/components/Button.test.tsx..."

cat <<'EOF' > "${UI_ROOT}/test/components/Button.test.tsx"
// packages/ui/test/components/Button.test.tsx
import { describe, expect, it, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../../src/components/common/Button.js';

describe('Button', () => {
  it('deve renderizar com o texto fornecido', () => {
    render(<Button>Enviar</Button>);

    const button = screen.getByRole('button', { name: /enviar/i });
    expect(button).toBeInTheDocument();
  });

  it('deve chamar onClick quando clicado', () => {
    const handleClick = vi.fn();

    render(<Button onClick={handleClick}>Executar</Button>);

    const button = screen.getByRole('button', { name: /executar/i });
    fireEvent.click(button);

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('não deve chamar onClick quando desabilitado', () => {
    const handleClick = vi.fn();

    render(
      <Button disabled onClick={handleClick}>
        Provisionar
      </Button>,
    );

    const button = screen.getByRole('button', { name: /provisionar/i });
    fireEvent.click(button);

    expect(handleClick).not.toHaveBeenCalled();
  });
});
EOF

log_info "Escrevendo test/components/Toast.test.tsx..."

cat <<'EOF' > "${UI_ROOT}/test/components/Toast.test.tsx"
// packages/ui/test/components/Toast.test.tsx
import { describe, expect, it, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Toast } from '../../src/components/common/Toast.js';
import type { ToastData } from '../../src/contexts/ToastContext.js';

describe('Toast', () => {
  it('deve renderizar mensagem e tipo', () => {
    const toast: ToastData = {
      id: 1,
      type: 'success',
      message: 'Operação concluída com sucesso',
    };

    const handleClose = vi.fn();

    render(<Toast toast={toast} onClose={handleClose} />);

    expect(screen.getByText(/opera[cç][aã]o conclu[ií]da com sucesso/i)).toBeInTheDocument();
    const container = screen.getByRole('status');
    expect(container).toHaveAttribute('data-type', 'success');
  });

  it('deve chamar onClose ao clicar no botão de fechar', () => {
    const toast: ToastData = {
      id: 2,
      type: 'error',
      message: 'Erro ao processar requisição',
    };

    const handleClose = vi.fn();

    render(<Toast toast={toast} onClose={handleClose} />);

    const closeButton = screen.getByRole('button', { name: /fechar notifica[cç][aã]o/i });
    fireEvent.click(closeButton);

    expect(handleClose).toHaveBeenCalledWith(2);
  });
});
EOF

log_info "Escrevendo test/hooks/useToast.test.tsx..."

cat <<'EOF' > "${UI_ROOT}/test/hooks/useToast.test.tsx"
// packages/ui/test/hooks/useToast.test.tsx
import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { ToastProvider } from '../../src/contexts/ToastProvider.js';
import { useToast } from '../../src/hooks/useToast.js';

function TestComponent() {
  const { showSuccess } = useToast();

  return (
    <button
      type="button"
      onClick={() => showSuccess('Toast de sucesso acionado')}
    >
      Disparar toast
    </button>
  );
}

describe('useToast', () => {
  it('deve exibir toast de sucesso quando showSuccess é chamado', async () => {
    render(
      <ToastProvider>
        <TestComponent />
      </ToastProvider>,
    );

    const button = screen.getByRole('button', { name: /disparar toast/i });
    fireEvent.click(button);

    const toast = await screen.findByText(/toast de sucesso acionado/i);
    expect(toast).toBeInTheDocument();
  });
});
EOF

# ------------------------------------------------------------------------------
# 8) Finalização
# ------------------------------------------------------------------------------

log_info "Arquivos da HU-UI-Explore-Interactions-012 escritos com sucesso."
log_info "Agora rode, a partir de ${REPO_ROOT}:"
echo
echo "  pnpm --filter @mini-ide/ui lint"
echo "  pnpm --filter @mini-ide/ui test"
echo "  pnpm --filter @mini-ide/ui typecheck"
echo "  pnpm --filter @mini-ide/ui build"
echo "  REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
echo
log_info "Depois disso, suba a UI com:"
echo "  pnpm --filter @mini-ide/ui dev"
echo "e abra http://localhost:5173 para validar os toasts e estados visuais."
