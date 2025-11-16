/**
 * @file MockLLMProvider.ts
 * @description Provider mock para testes determinísticos
 *
 * Este provider simula comportamento de um LLM real mas com respostas
 * previsíveis e controladas, ideal para testes unitários e integração.
 *
 * @version 1.0.17
 * @since 2024-11-15
 */

import type { ILLMProvider, LLMAnalyzeOptions, LLMResponse, ModelInfo } from './ILLMProvider.js';

/**
 * Opções de configuração do MockLLMProvider
 */
export interface MockProviderOptions {
  /**
   * Delay artificial em ms para simular latência de rede
   * @default 0
   */
  simulateDelayMs?: number;

  /**
   * Se true, simula falha aleatória (útil para testar error handling)
   * @default false
   */
  simulateFailure?: boolean;

  /**
   * Resposta customizada ao invés do echo padrão
   */
  customResponse?: string;
}

/**
 * Provider mock que simula comportamento de LLM para testes
 *
 * Por padrão, retorna um "echo" do prompt com metadados simulados.
 * Pode ser configurado para simular delays, falhas e respostas customizadas.
 *
 * @example
 * ```typescript
 * const mock = new MockLLMProvider({ simulateDelayMs: 100 });
 * const response = await mock.analyze("teste");
 * expect(response.content).toContain("teste");
 * ```
 */
export class MockLLMProvider implements ILLMProvider {
  private options: Required<MockProviderOptions>;

  constructor(options: MockProviderOptions = {}) {
    this.options = {
      simulateDelayMs: options.simulateDelayMs ?? 0,
      simulateFailure: options.simulateFailure ?? false,
      customResponse: options.customResponse ?? '',
    };
  }

  async analyze(prompt: string, _options?: LLMAnalyzeOptions): Promise<LLMResponse> {
    const startTime = Date.now();

    // Simular delay se configurado
    if (this.options.simulateDelayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, this.options.simulateDelayMs));
    }

    // Simular falha se configurado
    if (this.options.simulateFailure) {
      throw new Error('MockLLMProvider: Falha simulada para testes');
    }

    // Validação básica
    if (!prompt || prompt.trim() === '') {
      throw new Error('MockLLMProvider: Prompt não pode estar vazio');
    }

    // Gerar resposta mock
    const content =
      this.options.customResponse ||
      `[MOCK] Análise do prompt: "${prompt.substring(0, 50)}${prompt.length > 50 ? '...' : ''}"`;

    // Simular contagem de tokens (aproximação simples)
    const promptTokens = Math.ceil(prompt.length / 4);
    const completionTokens = Math.ceil(content.length / 4);

    const processingTimeMs = Date.now() - startTime;

    return {
      content,
      usage: {
        promptTokens,
        completionTokens,
        totalTokens: promptTokens + completionTokens,
      },
      model: 'mock-llm-v1',
      processingTimeMs,
      requestId: `mock_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
    };
  }

  getModelInfo(): ModelInfo {
    return {
      name: 'mock-llm',
      provider: 'MockProvider',
      version: 'v1.0',
      maxContextTokens: 4096,
      supportsStreaming: false,
    };
  }

  isHealthy(): Promise<boolean> {
    // Mock sempre está "saudável" a menos que configurado para falhar
    if (this.options.simulateFailure) {
      return Promise.reject(new Error('MockLLMProvider: Health check falhou (simulado)'));
    }
    return Promise.resolve(true);
  }
}
