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
