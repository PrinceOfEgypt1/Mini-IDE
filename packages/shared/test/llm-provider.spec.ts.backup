/**
 * @file llm-provider.spec.ts
 * @description Testes completos para LLM Provider abstraction
 *
 * Cobertura de testes:
 * - MockLLMProvider: analyze, getModelInfo, isHealthy, delay, failure
 * - DeepSeekProvider: constructor, analyze, model info
 * - LLMProviderFactory: create, createFromEnv, error handling
 * - Interface compliance: validação de implementação de ILLMProvider
 *
 * Meta de cobertura: ≥90%
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  MockLLMProvider,
  DeepSeekProvider,
  LLMProviderFactory,
  type ILLMProvider,
  type MockProviderOptions,
  type DeepSeekConfig,
} from '../src/llm/index.js';

describe('MockLLMProvider', () => {
  describe('Construção', () => {
    it('deve criar provider com opções padrão', () => {
      const provider = new MockLLMProvider();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar provider com opções customizadas', () => {
      const options: MockProviderOptions = {
        simulateDelayMs: 100,
        simulateFailure: false,
        customResponse: 'Resposta customizada',
      };
      const provider = new MockLLMProvider(options);
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });
  });

  describe('analyze()', () => {
    let provider: MockLLMProvider;

    beforeEach(() => {
      provider = new MockLLMProvider();
    });

    it('deve processar prompt válido', async () => {
      const response = await provider.analyze('teste de prompt');

      expect(response.content).toContain('teste de prompt');
      expect(response.usage.promptTokens).toBeGreaterThan(0);
      expect(response.usage.completionTokens).toBeGreaterThan(0);
      expect(response.usage.totalTokens).toBe(
        response.usage.promptTokens + response.usage.completionTokens,
      );
      expect(response.model).toBe('mock-llm-v1');
      expect(response.processingTimeMs).toBeGreaterThanOrEqual(0);
      expect(response.requestId).toMatch(/^mock_/u);
    });

    it('deve rejeitar prompt vazio', async () => {
      await expect(provider.analyze('')).rejects.toThrow('não pode estar vazio');
    });

    it('deve rejeitar prompt apenas com espaços', async () => {
      await expect(provider.analyze('   ')).rejects.toThrow('não pode estar vazio');
    });

    it('deve usar resposta customizada quando configurada', async () => {
      const customProvider = new MockLLMProvider({
        customResponse: 'CUSTOM RESPONSE',
      });

      const response = await customProvider.analyze('qualquer coisa');
      expect(response.content).toBe('CUSTOM RESPONSE');
    });

    it('deve simular delay quando configurado', async () => {
      const delayMs = 50;
      const delayProvider = new MockLLMProvider({ simulateDelayMs: delayMs });

      const startTime = Date.now();
      await delayProvider.analyze('teste');
      const elapsed = Date.now() - startTime;

      expect(elapsed).toBeGreaterThanOrEqual(delayMs);
    });

    it('deve simular falha quando configurada', async () => {
      const failProvider = new MockLLMProvider({ simulateFailure: true });

      await expect(failProvider.analyze('teste')).rejects.toThrow('Falha simulada');
    });

    it('deve calcular tokens corretamente (aproximação)', async () => {
      const prompt = 'a'.repeat(400); // ~100 tokens
      const response = await provider.analyze(prompt);

      expect(response.usage.promptTokens).toBeCloseTo(100, -1); // ±10%
    });
  });

  describe('getModelInfo()', () => {
    it('deve retornar informações corretas do modelo', () => {
      const provider = new MockLLMProvider();
      const info = provider.getModelInfo();

      expect(info.name).toBe('mock-llm');
      expect(info.provider).toBe('MockProvider');
      expect(info.version).toBe('v1.0');
      expect(info.maxContextTokens).toBe(4096);
      expect(info.supportsStreaming).toBe(false);
    });
  });

  describe('isHealthy()', () => {
    it('deve retornar true quando saudável', async () => {
      const provider = new MockLLMProvider();
      expect(await provider.isHealthy()).toBe(true);
    });

    it('deve lançar erro quando simulateFailure está ativo', async () => {
      const provider = new MockLLMProvider({ simulateFailure: true });
      await expect(provider.isHealthy()).rejects.toThrow('Health check falhou');
    });
  });
});

describe('DeepSeekProvider', () => {
  const validConfig: DeepSeekConfig = {
    apiKey: 'sk-test-key-12345',
  };

  describe('Construção', () => {
    it('deve criar provider com config mínima', () => {
      const provider = new DeepSeekProvider(validConfig);
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve criar provider com config completa', () => {
      const fullConfig: DeepSeekConfig = {
        apiKey: 'sk-test-key',
        baseUrl: 'https://custom.api.com',
        model: 'deepseek-custom',
        defaultTimeoutMs: 60000,
      };
      const provider = new DeepSeekProvider(fullConfig);
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar API key vazia', () => {
      expect(() => new DeepSeekProvider({ apiKey: '' })).toThrow('apiKey é obrigatória');
    });

    it('deve rejeitar API key apenas com espaços', () => {
      expect(() => new DeepSeekProvider({ apiKey: '   ' })).toThrow('apiKey é obrigatória');
    });
  });

  describe('analyze() - preparatório', () => {
    let provider: DeepSeekProvider;

    beforeEach(() => {
      provider = new DeepSeekProvider(validConfig);
    });

    it('deve retornar resposta preparatória', async () => {
      const response = await provider.analyze('teste');

      expect(response.content).toContain('PREPARATÓRIO');
      expect(response.content).toContain('teste');
      expect(response.model).toBe('deepseek-chat'); // default
      expect(response.usage.totalTokens).toBeGreaterThan(0);
      expect(response.processingTimeMs).toBeGreaterThanOrEqual(0);
    });

    it('deve rejeitar prompt vazio', async () => {
      await expect(provider.analyze('')).rejects.toThrow('não pode estar vazio');
    });

    it('deve usar modelo customizado quando configurado', async () => {
      const customProvider = new DeepSeekProvider({
        apiKey: 'sk-test',
        model: 'deepseek-custom-model',
      });

      const response = await customProvider.analyze('teste');
      expect(response.model).toBe('deepseek-custom-model');
    });
  });

  describe('getModelInfo()', () => {
    it('deve retornar informações corretas do DeepSeek', () => {
      const provider = new DeepSeekProvider(validConfig);
      const info = provider.getModelInfo();

      expect(info.name).toBe('deepseek-chat');
      expect(info.provider).toBe('DeepSeek');
      expect(info.version).toBe('v3');
      expect(info.maxContextTokens).toBe(64000);
      expect(info.supportsStreaming).toBe(true);
    });

    it('deve refletir modelo customizado', () => {
      const provider = new DeepSeekProvider({
        apiKey: 'sk-test',
        model: 'deepseek-turbo',
      });

      const info = provider.getModelInfo();
      expect(info.name).toBe('deepseek-turbo');
    });
  });

  describe('isHealthy() - preparatório', () => {
    it('deve retornar true (preparatório)', async () => {
      const provider = new DeepSeekProvider(validConfig);
      expect(await provider.isHealthy()).toBe(true);
    });
  });
});

describe('LLMProviderFactory', () => {
  describe('create()', () => {
    it('deve criar MockLLMProvider', () => {
      const provider = LLMProviderFactory.create({ type: 'mock' });
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar MockLLMProvider com opções', () => {
      const provider = LLMProviderFactory.create({
        type: 'mock',
        mockOptions: { simulateDelayMs: 100 },
      });
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar DeepSeekProvider', () => {
      const provider = LLMProviderFactory.create({
        type: 'deepseek',
        deepseekConfig: { apiKey: 'sk-test' },
      });
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar deepseek sem config', () => {
      expect(() => LLMProviderFactory.create({ type: 'deepseek' })).toThrow(
        'deepseekConfig é obrigatória',
      );
    });

    it('deve rejeitar tipo desconhecido', () => {
      // Aqui usamos um cast via unknown -> never para evitar "any" e ainda assim
      // exercitar o caminho de erro com valor em runtime inválido.
      expect(() => LLMProviderFactory.create({ type: 'invalid' as unknown as never })).toThrow(
        'Tipo de provider desconhecido',
      );
    });
  });

  describe('createFromEnv()', () => {
    let originalEnv: NodeJS.ProcessEnv;

    beforeEach(() => {
      originalEnv = { ...process.env };
    });

    afterEach(() => {
      process.env = originalEnv;
    });

    it('deve criar MockProvider por padrão', () => {
      delete process.env['LLM_PROVIDER_TYPE'];
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar MockProvider quando explicitamente configurado', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'mock';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve aplicar MOCK_DELAY_MS', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'mock';
      process.env['MOCK_DELAY_MS'] = '200';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar DeepSeekProvider quando configurado', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'deepseek';
      process.env['DEEPSEEK_API_KEY'] = 'sk-test-from-env';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar deepseek sem API key', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'deepseek';
      delete process.env['DEEPSEEK_API_KEY'];

      expect(() => LLMProviderFactory.createFromEnv()).toThrow('DEEPSEEK_API_KEY não definida');
    });

    it('deve aplicar variáveis opcionais do DeepSeek', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'deepseek';
      process.env['DEEPSEEK_API_KEY'] = 'sk-test';
      process.env['DEEPSEEK_MODEL'] = 'custom-model';
      process.env['DEEPSEEK_BASE_URL'] = 'https://custom.url';
      process.env['DEEPSEEK_TIMEOUT_MS'] = '60000';

      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar LLM_PROVIDER_TYPE inválido', () => {
      process.env['LLM_PROVIDER_TYPE'] = 'invalid';
      expect(() => LLMProviderFactory.createFromEnv()).toThrow('LLM_PROVIDER_TYPE inválido');
    });
  });
});

describe('Interface Compliance', () => {
  describe('Providers implementam ILLMProvider corretamente', () => {
    const testProviders: Array<{ name: string; provider: ILLMProvider }> = [
      { name: 'MockLLMProvider', provider: new MockLLMProvider() },
      { name: 'DeepSeekProvider', provider: new DeepSeekProvider({ apiKey: 'sk-test' }) },
    ];

    testProviders.forEach(({ name, provider }) => {
      describe(name, () => {
        it('deve ter método analyze', () => {
          expect(typeof provider.analyze).toBe('function');
        });

        it('deve ter método getModelInfo', () => {
          expect(typeof provider.getModelInfo).toBe('function');
        });

        it('deve ter método isHealthy', () => {
          expect(typeof provider.isHealthy).toBe('function');
        });

        it('analyze deve retornar Promise<LLMResponse>', async () => {
          const response = await provider.analyze('teste');

          expect(response).toHaveProperty('content');
          expect(response).toHaveProperty('usage');
          expect(response).toHaveProperty('model');
          expect(response).toHaveProperty('processingTimeMs');

          expect(response.usage).toHaveProperty('promptTokens');
          expect(response.usage).toHaveProperty('completionTokens');
          expect(response.usage).toHaveProperty('totalTokens');
        });

        it('getModelInfo deve retornar ModelInfo', () => {
          const info = provider.getModelInfo();

          expect(info).toHaveProperty('name');
          expect(info).toHaveProperty('provider');
          expect(info).toHaveProperty('version');
          expect(info).toHaveProperty('maxContextTokens');
          expect(info).toHaveProperty('supportsStreaming');
        });

        it('isHealthy deve retornar Promise<boolean>', async () => {
          const healthy = await provider.isHealthy();
          expect(typeof healthy).toBe('boolean');
        });
      });
    });
  });
});
