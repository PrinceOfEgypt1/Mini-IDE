/**
 * @file DeepSeekProvider.ts
 * @description Provider para DeepSeek-V3 (preparatório)
 *
 * Este provider implementa integração com a API do DeepSeek-V3.
 * Na versão atual (1.0.17), ainda está em modo preparatório.
 * A integração real com a API será implementada em HU-LLM-Client-DeepSeek.
 *
 * @version 1.0.17
 * @since 2024-11-15
 */

import type { ILLMProvider, LLMAnalyzeOptions, LLMResponse, ModelInfo } from './ILLMProvider.js';

/**
 * Configuração do DeepSeekProvider
 */
export interface DeepSeekConfig {
  /**
   * API Key para autenticação no DeepSeek
   */
  apiKey: string;

  /**
   * URL base da API (para testes ou ambientes alternativos)
   * @default "https://api.deepseek.com/v1"
   */
  baseUrl?: string;

  /**
   * Modelo específico do DeepSeek a ser usado
   * @default "deepseek-chat"
   */
  model?: string;

  /**
   * Timeout padrão para requisições em ms
   * @default 30000
   */
  defaultTimeoutMs?: number;
}

/**
 * Provider para integração com DeepSeek-V3
 *
 * ⚠️ NOTA: Este é um provider preparatório. A implementação completa
 * da integração com a API real do DeepSeek será feita na HU-LLM-Client-DeepSeek.
 *
 * Por enquanto, valida configurações e fornece estrutura base.
 *
 * @example
 * ```typescript
 * const provider = new DeepSeekProvider({
 *   apiKey: process.env.DEEPSEEK_API_KEY!,
 *   model: "deepseek-chat"
 * });
 * const response = await provider.analyze("Explique IA");
 * ```
 */
export class DeepSeekProvider implements ILLMProvider {
  private config: Required<DeepSeekConfig>;

  constructor(config: DeepSeekConfig) {
    // Validar API Key
    if (!config.apiKey || config.apiKey.trim() === '') {
      throw new Error('DeepSeekProvider: apiKey é obrigatória');
    }

    this.config = {
      apiKey: config.apiKey,
      baseUrl: config.baseUrl ?? 'https://api.deepseek.com/v1',
      model: config.model ?? 'deepseek-chat',
      defaultTimeoutMs: config.defaultTimeoutMs ?? 30000,
    };
  }

  /**
   * Analisa um prompt usando o modelo DeepSeek-V3.
   *
   * Implementação preparatória: ainda não chama a API real,
   * mas já valida entrada e retorna uma resposta simulada.
   */
  async analyze(prompt: string, _options?: LLMAnalyzeOptions): Promise<LLMResponse> {
    // Validação básica
    if (!prompt || prompt.trim() === '') {
      throw new Error('DeepSeekProvider: Prompt não pode estar vazio');
    }

    const startTime = Date.now();

    // Pequeno await real para satisfazer a regra require-await
    await Promise.resolve();

    // ⚠️ IMPLEMENTAÇÃO PREPARATÓRIA
    // A chamada real à API do DeepSeek será implementada em HU-LLM-Client-DeepSeek
    // Por enquanto, retornamos uma resposta simulada para não quebrar testes

    const content = `[PREPARATÓRIO] DeepSeekProvider recebeu: "${prompt.substring(0, 50)}..."`;
    const processingTimeMs = Date.now() - startTime;

    return {
      content,
      usage: {
        promptTokens: Math.ceil(prompt.length / 4),
        completionTokens: Math.ceil(content.length / 4),
        totalTokens: Math.ceil((prompt.length + content.length) / 4),
      },
      model: this.config.model,
      processingTimeMs,
      requestId: `deepseek_prep_${Date.now()}`,
    };
  }

  /**
   * Retorna informações estáticas sobre o modelo DeepSeek.
   */
  getModelInfo(): ModelInfo {
    return {
      name: this.config.model,
      provider: 'DeepSeek',
      version: 'v3',
      maxContextTokens: 64000, // DeepSeek-V3 suporta até 64k tokens
      supportsStreaming: true,
    };
  }

  /**
   * Verifica se o provider está saudável.
   *
   * Implementação preparatória: assume que está sempre saudável.
   */
  async isHealthy(): Promise<boolean> {
    // TODO: Implementar health check real
    // - Fazer uma chamada leve à API (ex: listar modelos)
    // - Verificar se responde com 200
    // - Validar se API Key é válida

    // Pequeno await real para satisfazer require-await
    await Promise.resolve();

    // Por enquanto, sempre retorna true (preparatório)
    return true;
  }
}
