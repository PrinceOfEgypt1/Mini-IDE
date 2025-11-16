/**
 * @fileoverview Contrato oficial de resposta do endpoint POST /analyze
 * @module @mini-ide/shared/types/analyze-response
 *
 * Este arquivo define o shape oficial da resposta retornada pelo endpoint
 * POST /analyze do servidor Mini-IDE.
 *
 * Versão do contrato: 1.0.0
 * Data: 2024-11-16
 * HU: HU-Server-Analyze-Shape-Contract
 */

/**
 * Resposta oficial do endpoint POST /analyze
 *
 * Todos os campos marcados como obrigatórios DEVEM estar presentes em toda
 * resposta 2xx do endpoint. Campos opcionais podem ou não estar presentes.
 *
 * @interface AnalyzeResponse
 * @version 1.0.0
 */
export interface AnalyzeResponse {
  /**
   * Resumo/saída principal da análise.
   * Comprimento respeita o parâmetro maxLen da requisição.
   *
   * @required
   * @type {string}
   */
  summary: string;

  /**
   * Número de caracteres do texto de entrada (input).
   *
   * @required
   * @type {number}
   * @minimum 0
   */
  inputLength: number;

  /**
   * Número de caracteres do resumo gerado (output).
   *
   * @required
   * @type {number}
   * @minimum 0
   */
  outputLength: number;

  /**
   * Identificador único da requisição (UUID v4).
   * Usado para correlação de logs e troubleshooting.
   *
   * @required
   * @type {string}
   * @pattern ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
   */
  requestId: string;

  /**
   * Timestamp ISO 8601 da geração da resposta.
   *
   * @required
   * @type {string}
   * @format date-time
   * @example "2024-11-16T14:30:00.000Z"
   */
  timestamp: string;

  /**
   * Quantidade de orçamento consumida nesta requisição (em unidades monetárias).
   *
   * @optional
   * @type {number}
   * @minimum 0
   */
  budgetUsed?: number;

  /**
   * Quantidade de orçamento restante após esta requisição (em unidades monetárias).
   *
   * @optional
   * @type {number}
   * @minimum 0
   */
  budgetRemaining?: number;
}

/**
 * Valida se um objeto corresponde ao contrato AnalyzeResponse.
 *
 * Esta função verifica apenas os campos obrigatórios. Campos opcionais
 * são validados se presentes.
 *
 * NOTA: Usa notação de colchetes para compatibilidade com TypeScript strict mode.
 *
 * @param obj - Objeto a ser validado
 * @returns true se o objeto é uma AnalyzeResponse válida
 */
export function isAnalyzeResponse(obj: unknown): obj is AnalyzeResponse {
  if (typeof obj !== 'object' || obj === null) {
    return false;
  }

  const response = obj as Record<string, unknown>;

  // Validar campos obrigatórios (usando notação de colchetes para strict mode)
  const hasSummary = typeof response['summary'] === 'string';
  const hasInputLength =
    typeof response['inputLength'] === 'number' && response['inputLength'] >= 0;
  const hasOutputLength =
    typeof response['outputLength'] === 'number' && response['outputLength'] >= 0;
  const hasRequestId =
    typeof response['requestId'] === 'string' && response['requestId'].length > 0;
  const hasTimestamp =
    typeof response['timestamp'] === 'string' && response['timestamp'].length > 0;

  if (!hasSummary || !hasInputLength || !hasOutputLength || !hasRequestId || !hasTimestamp) {
    return false;
  }

  // Validar campos opcionais (se presentes)
  if ('budgetUsed' in response) {
    if (typeof response['budgetUsed'] !== 'number' || response['budgetUsed'] < 0) {
      return false;
    }
  }

  if ('budgetRemaining' in response) {
    if (typeof response['budgetRemaining'] !== 'number' || response['budgetRemaining'] < 0) {
      return false;
    }
  }

  return true;
}

/**
 * Retorna lista de campos obrigatórios do contrato.
 * Útil para mensagens de erro e debugging.
 */
export const REQUIRED_FIELDS = [
  'summary',
  'inputLength',
  'outputLength',
  'requestId',
  'timestamp',
] as const;

/**
 * Retorna lista de campos opcionais do contrato.
 */
export const OPTIONAL_FIELDS = ['budgetUsed', 'budgetRemaining'] as const;
