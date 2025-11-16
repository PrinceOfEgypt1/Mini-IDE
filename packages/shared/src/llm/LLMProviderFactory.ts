/**
 * @file LLMProviderFactory.ts
 * @description Factory para criação de providers LLM
 *
 * Implementa padrão Factory para instanciar providers baseado em configuração,
 * facilitando testes e permitindo troca de provider via variáveis de ambiente.
 *
 * @version 1.0.17
 * @since 2024-11-15
 */

import type { ILLMProvider } from './ILLMProvider.js';
import { MockLLMProvider, type MockProviderOptions } from './MockLLMProvider.js';
import { DeepSeekProvider, type DeepSeekConfig } from './DeepSeekProvider.js';

/**
 * Tipos de providers suportados
 */
export type ProviderType = 'mock' | 'deepseek';

/**
 * Configuração para criação de provider via factory
 */
export interface ProviderFactoryConfig {
  /**
   * Tipo do provider a ser criado
   */
  type: ProviderType;

  /**
   * Configuração específica para MockProvider
   */
  mockOptions?: MockProviderOptions;

  /**
   * Configuração específica para DeepSeekProvider
   */
  deepseekConfig?: DeepSeekConfig;
}

/**
 * Factory para criação de providers LLM
 *
 * Centraliza a lógica de instanciação de providers, permitindo:
 * - Criação baseada em tipo configurável
 * - Leitura automática de variáveis de ambiente
 * - Facilita testes com mock
 * - Suporta múltiplos providers
 *
 * @example
 * ```typescript
 * // Criar provider a partir de config
 * const provider = LLMProviderFactory.create({
 *   type: 'deepseek',
 *   deepseekConfig: { apiKey: 'sk-...' }
 * });
 *
 * // Criar provider a partir de env vars
 * const provider = LLMProviderFactory.createFromEnv();
 * ```
 */
export class LLMProviderFactory {
  /**
   * Cria um provider baseado em configuração explícita
   *
   * @param config - Configuração do provider
   * @returns Instância do provider configurado
   * @throws Error se configuração inválida ou faltando parâmetros obrigatórios
   */
  static create(config: ProviderFactoryConfig): ILLMProvider {
    switch (config.type) {
      case 'mock':
        return new MockLLMProvider(config.mockOptions);

      case 'deepseek': {
        if (!config.deepseekConfig) {
          throw new Error('LLMProviderFactory: deepseekConfig é obrigatória para type="deepseek"');
        }
        return new DeepSeekProvider(config.deepseekConfig);
      }

      default: {
        throw new Error('LLMProviderFactory: Tipo de provider desconhecido');
      }
    }
  }

  /**
   * Cria um provider baseado em variáveis de ambiente
   *
   * Variáveis lidas:
   * - LLM_PROVIDER_TYPE: 'mock' | 'deepseek' (default: 'mock')
   * - DEEPSEEK_API_KEY: API key do DeepSeek (obrigatória se type=deepseek)
   * - DEEPSEEK_MODEL: Modelo específico (opcional, default: 'deepseek-chat')
   * - DEEPSEEK_BASE_URL: URL customizada (opcional)
   *
   * @returns Instância do provider configurado via env
   * @throws Error se variáveis obrigatórias estiverem faltando
   */
  static createFromEnv(): ILLMProvider {
    const providerType = (process.env['LLM_PROVIDER_TYPE'] || 'mock') as ProviderType;

    switch (providerType) {
      case 'mock':
        return new MockLLMProvider({
          simulateDelayMs: Number(process.env['MOCK_DELAY_MS']) || 0,
        });

      case 'deepseek': {
        const apiKey = process.env['DEEPSEEK_API_KEY'];
        if (!apiKey) {
          throw new Error(
            'LLMProviderFactory: DEEPSEEK_API_KEY não definida no ambiente. ' +
              'Defina a variável ou use LLM_PROVIDER_TYPE=mock para testes.',
          );
        }

        return new DeepSeekProvider({
          apiKey,
          model: process.env['DEEPSEEK_MODEL'],
          baseUrl: process.env['DEEPSEEK_BASE_URL'],
          defaultTimeoutMs: process.env['DEEPSEEK_TIMEOUT_MS']
            ? Number(process.env['DEEPSEEK_TIMEOUT_MS'])
            : undefined,
        });
      }

      default: {
        const invalidType = providerType as unknown as string;
        throw new Error(
          `LLMProviderFactory: LLM_PROVIDER_TYPE inválido: "${invalidType}". ` +
            'Valores aceitos: "mock", "deepseek"',
        );
      }
    }
  }
}
