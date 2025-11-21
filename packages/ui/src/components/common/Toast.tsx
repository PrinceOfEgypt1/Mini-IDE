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
