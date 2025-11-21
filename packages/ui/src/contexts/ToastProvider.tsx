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
