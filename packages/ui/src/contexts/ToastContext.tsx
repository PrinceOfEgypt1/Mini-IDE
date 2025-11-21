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
