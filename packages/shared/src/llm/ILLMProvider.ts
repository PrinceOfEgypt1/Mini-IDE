/**
 * @file ILLMProvider.ts
 * @description Interface abstrata para providers de Large Language Models
 *
 * Esta interface define o contrato que todos os providers LLM devem implementar,
 * permitindo substituição transparente entre diferentes providers (DeepSeek, OpenAI, etc.)
 * e facilitando testes com mocks.
 *
 * @version 1.0.17
 * @since 2024-11-15
 */

/**
 * Opções para chamada de análise no LLM
 */
export interface LLMAnalyzeOptions {
  /**
   * Temperatura para geração (0.0 a 1.0)
   * Valores mais baixos = mais determinístico
   * Valores mais altos = mais criativo
   * @default 0.7
   */
  temperature?: number;

  /**
   * Número máximo de tokens na resposta
   * @default 4096
   */
  maxTokens?: number;

  /**
   * System prompt (instruções globais para o modelo)
   */
  systemPrompt?: string;

  /**
   * Timeout em milissegundos para a requisição
   * @default 30000
   */
  timeoutMs?: number;
}

/**
 * Resposta estruturada do LLM após processamento
 */
export interface LLMResponse {
  /**
   * Conteúdo textual gerado pelo modelo
   */
  content: string;

  /**
   * Informações de uso de tokens
   */
  usage: {
    /**
     * Tokens no prompt de entrada
     */
    promptTokens: number;

    /**
     * Tokens na resposta gerada
     */
    completionTokens: number;

    /**
     * Total de tokens consumidos (prompt + completion)
     */
    totalTokens: number;
  };

  /**
   * Nome do modelo que gerou a resposta
   */
  model: string;

  /**
   * Tempo de processamento em milissegundos
   */
  processingTimeMs: number;

  /**
   * ID único da requisição (quando fornecido pelo provider)
   */
  requestId?: string;
}

/**
 * Informações sobre o modelo LLM
 */
export interface ModelInfo {
  /**
   * Nome/identificador do modelo
   * @example "deepseek-chat", "gpt-4", "claude-3"
   */
  name: string;

  /**
   * Provedor do modelo
   * @example "DeepSeek", "OpenAI", "Anthropic"
   */
  provider: string;

  /**
   * Versão do modelo
   * @example "v3", "turbo-2024-04"
   */
  version: string;

  /**
   * Limite máximo de tokens de contexto
   */
  maxContextTokens: number;

  /**
   * Se o modelo suporta streaming
   */
  supportsStreaming: boolean;
}

/**
 * Interface principal para providers de LLM
 *
 * Todos os providers (DeepSeek, OpenAI, Mock, etc.) devem implementar esta interface
 * para garantir compatibilidade e permitir substituição transparente.
 *
 * @example
 * ```typescript
 * const provider: ILLMProvider = new DeepSeekProvider(apiKey);
 * const response = await provider.analyze("Explique TypeScript", { temperature: 0.5 });
 * console.log(response.content);
 * ```
 */
export interface ILLMProvider {
  /**
   * Envia um prompt para análise pelo LLM
   *
   * @param prompt - Texto do usuário para ser processado
   * @param options - Opções de configuração da chamada
   * @returns Promise com a resposta estruturada do modelo
   * @throws Error se a chamada falhar ou timeout ocorrer
   */
  analyze(prompt: string, options?: LLMAnalyzeOptions): Promise<LLMResponse>;

  /**
   * Retorna informações sobre o modelo utilizado
   *
   * @returns Metadados do modelo LLM
   */
  getModelInfo(): ModelInfo;

  /**
   * Verifica se o provider está saudável e disponível
   *
   * @returns Promise<true> se o provider está operacional
   * @throws Error se o provider não estiver disponível
   */
  isHealthy(): Promise<boolean>;
}
