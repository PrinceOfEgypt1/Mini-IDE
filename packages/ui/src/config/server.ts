/**
 * Configuração do servidor backend
 */
export interface ServerConfig {
  baseUrl: string;
  timeout: number;
}

/**
 * Retorna a configuração do servidor
 */
export function getServerConfig(): ServerConfig {
  const port = (import.meta.env.VITE_SERVER_PORT as string | undefined) || '3200';
  const host = (import.meta.env.VITE_SERVER_HOST as string | undefined) || 'localhost';

  return {
    baseUrl: `http://${host}:${port}`,
    timeout: 30000,
  };
}

/**
 * Retorna a URL base do servidor
 */
export function getBaseUrl(): string {
  return getServerConfig().baseUrl;
}

/**
 * Retorna a URL do endpoint /healthz
 */
export function getHealthzUrl(): string {
  return `${getBaseUrl()}/healthz`;
}

/**
 * Retorna a URL do endpoint /analyze
 */
export function getAnalyzeUrl(): string {
  return `${getBaseUrl()}/analyze`;
}
