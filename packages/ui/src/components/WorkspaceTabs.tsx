import { useState } from 'react';
import styles from './WorkspaceTabs.module.css';

export type TabId =
  | 'overview'
  | 'hus'
  | 'docs'
  | 'tests'
  | 'analyze'
  | 'plan'
  | 'timeline'
  | 'runs'
  | 'metrics'
  | 'outputs';

export interface Tab {
  id: TabId;
  label: string;
}

const tabs: Tab[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'hus', label: 'HUs' },
  { id: 'docs', label: 'Docs' },
  { id: 'tests', label: 'Testes' },
  { id: 'analyze', label: 'Analyze' },
  { id: 'plan', label: 'Personas & Plano' },
  { id: 'timeline', label: 'Timeline' },
  { id: 'runs', label: 'Runs' },
  { id: 'metrics', label: 'Métricas' },
  { id: 'outputs', label: 'Outputs' },
];

export interface WorkspaceTabsProps {
  activeTab?: TabId;
  onTabChange?: (tabId: TabId) => void;
}

/**
 * Componente de abas do workspace.
 * Pode funcionar de forma controlada (com activeTab e onTabChange externos)
 * ou de forma não-controlada (gerencia próprio estado interno).
 */
export function WorkspaceTabs({
  activeTab: externalActiveTab,
  onTabChange: externalOnTabChange,
}: WorkspaceTabsProps = {}) {
  const [internalActiveTab, setInternalActiveTab] = useState<TabId>('overview');

  // Se activeTab externo for fornecido, usa ele; senão usa interno
  const activeTab = externalActiveTab ?? internalActiveTab;

  const handleTabChange = (tabId: TabId) => {
    // Se há handler externo, usa ele
    if (externalOnTabChange) {
      externalOnTabChange(tabId);
    } else {
      // Senão, atualiza estado interno
      setInternalActiveTab(tabId);
    }
  };

  return (
    <div className={styles.tabs}>
      {tabs.map((tab) => (
        <button
          key={tab.id}
          className={`${styles.tab} ${activeTab === tab.id ? styles.active : ''}`}
          onClick={() => handleTabChange(tab.id)}
          aria-current={activeTab === tab.id ? 'page' : undefined}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}
