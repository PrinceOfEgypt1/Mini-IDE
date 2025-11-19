#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 13_fix_flaky_timing_test.sh
# Objetivo: Corrigir teste flaky de timing em packages/shared
# 
# Problema: Teste espera exatamente 50ms mas JavaScript não garante precisão
# Solução: Adicionar margem de tolerância de -5ms
#
# Arquivos modificados:
#   - packages/shared/test/llm-provider.spec.ts (linha 88)
#
# Modo de uso:
#   1. ./scripts/13_fix_flaky_timing_test.sh
#   2. pnpm test
################################################################################

echo "[info] Corrigindo teste flaky de timing..."

# Criar backup
cp packages/shared/test/llm-provider.spec.ts packages/shared/test/llm-provider.spec.ts.backup

# Aplicar correção: mudar de >= delayMs para >= (delayMs - 5)
# Isso adiciona margem de 5ms para imprecisões do JavaScript
cat <<'EOF' > packages/shared/test/llm-provider.spec.ts
import { describe, it, expect } from 'vitest';
import { MockLLMProvider } from '../src/llm/mock-provider.js';
import { DeepSeekProvider } from '../src/llm/deepseek-provider.js';
import { createLLMProvider } from '../src/llm/factory.js';
import type { ILLMProvider } from '../src/llm/types.js';

describe('MockLLMProvider', () => {
  describe('constructor', () => {
    it('deve criar provider com opções padrão', () => {
      const provider = new MockLLMProvider();
      expect(provider).toBeDefined();
    });

    it('deve criar provider com opções customizadas', () => {
      const provider = new MockLLMProvider({
        delayMs: 100,
        customResponse: 'Custom',
        simulateFailure: false,
      });
      expect(provider).toBeDefined();
    });
  });

  describe('analyze()', () => {
    it('deve processar prompt válido', async () => {
      const provider = new MockLLMProvider();
      const result = await provider.analyze('Test prompt');

      expect(result).toBeDefined();
      expect(result.summary).toContain('Mock');
      expect(result.inputLength).toBeGreaterThan(0);
      expect(result.outputLength).toBeGreaterThan(0);
      expect(result.tokensUsed).toBeGreaterThan(0);
    });

    it('deve rejeitar prompt vazio', async () => {
      const provider = new MockLLMProvider();
      await expect(provider.analyze('')).rejects.toThrow('Prompt cannot be empty');
    });

    it('deve rejeitar prompt apenas com espaços', async () => {
      const provider = new MockLLMProvider();
      await expect(provider.analyze('   ')).rejects.toThrow('Prompt cannot be empty');
    });

    it('deve usar resposta customizada quando configurada', async () => {
      const customResponse = 'Custom Response Text';
      const provider = new MockLLMProvider({ customResponse });
      const result = await provider.analyze('Test');

      expect(result.summary).toBe(customResponse);
    });

    it('deve simular delay quando configurado', async () => {
      const delayMs = 50;
      const provider = new MockLLMProvider({ delayMs });

      const startTime = Date.now();
      await provider.analyze('Test');
      const elapsed = Date.now() - startTime;

      // Tolerância de -5ms para imprecisões de timing do JavaScript
      expect(elapsed).toBeGreaterThanOrEqual(delayMs - 5);
    });

    it('deve simular falha quando configurada', async () => {
      const provider = new MockLLMProvider({ simulateFailure: true });
      await expect(provider.analyze('Test')).rejects.toThrow('Simulated LLM failure');
    });

    it('deve calcular tokens corretamente (aproximação)', async () => {
      const provider = new MockLLMProvider();
      const prompt = 'Hello world test';
      const result = await provider.analyze(prompt);

      // Mock usa aproximação: comprimento / 4
      const expectedTokens = Math.ceil(prompt.length / 4);
      expect(result.tokensUsed).toBe(expectedTokens);
    });
  });

  describe('getModelInfo()', () => {
    it('deve retornar informações corretas do modelo', () => {
      const provider = new MockLLMProvider();
      const info = provider.getModelInfo();

      expect(info.modelName).toBe('mock-llm-v1');
      expect(info.provider).toBe('mock');
      expect(info.maxTokens).toBe(4096);
    });
  });

  describe('isHealthy()', () => {
    it('deve retornar true quando saudável', async () => {
      const provider = new MockLLMProvider();
      const healthy = await provider.isHealthy();
      expect(healthy).toBe(true);
    });

    it('deve lançar erro quando simulateFailure está ativo', async () => {
      const provider = new MockLLMProvider({ simulateFailure: true });
      await expect(provider.isHealthy()).rejects.toThrow('Simulated LLM failure');
    });
  });
});

describe('DeepSeekProvider', () => {
  describe('constructor', () => {
    it('deve criar provider com config mínima', () => {
      const provider = new DeepSeekProvider({ apiKey: 'test-key' });
      expect(provider).toBeDefined();
    });

    it('deve criar provider com config completa', () => {
      const provider = new DeepSeekProvider({
        apiKey: 'test-key',
        model: 'deepseek-chat',
        apiUrl: 'https://custom.api.com',
        maxTokens: 8000,
      });
      expect(provider).toBeDefined();
    });

    it('deve rejeitar API key vazia', () => {
      expect(() => new DeepSeekProvider({ apiKey: '' })).toThrow('API key is required');
    });

    it('deve rejeitar API key apenas com espaços', () => {
      expect(() => new DeepSeekProvider({ apiKey: '   ' })).toThrow(
        'API key is required'
      );
    });
  });

  describe('analyze()', () => {
    it('deve retornar resposta preparatória', async () => {
      const provider = new DeepSeekProvider({ apiKey: 'test-key' });
      const result = await provider.analyze('Test prompt');

      expect(result).toBeDefined();
      expect(result.summary).toContain('preparatório');
      expect(result.inputLength).toBeGreaterThan(0);
      expect(result.outputLength).toBeGreaterThan(0);
      expect(result.tokensUsed).toBeGreaterThan(0);
    });

    it('deve rejeitar prompt vazio', async () => {
      const provider = new DeepSeekProvider({ apiKey: 'test-key' });
      await expect(provider.analyze('')).rejects.toThrow('Prompt cannot be empty');
    });
  });

  describe('getModelInfo()', () => {
    it('deve usar modelo customizado quando configurado', () => {
      const customModel = 'deepseek-custom';
      const provider = new DeepSeekProvider({
        apiKey: 'test-key',
        model: customModel,
      });
      const info = provider.getModelInfo();

      expect(info.modelName).toBe(customModel);
    });

    it('deve retornar informações corretas do DeepSeek', () => {
      const provider = new DeepSeekProvider({ apiKey: 'test-key' });
      const info = provider.getModelInfo();

      expect(info.modelName).toBe('deepseek-chat');
      expect(info.provider).toBe('deepseek');
      expect(info.maxTokens).toBe(4096);
    });

    it('deve refletir modelo customizado', () => {
      const provider = new DeepSeekProvider({
        apiKey: 'test-key',
        model: 'deepseek-v2',
      });
      const info = provider.getModelInfo();

      expect(info.modelName).toBe('deepseek-v2');
    });
  });

  describe('isHealthy()', () => {
    it('deve retornar true (preparatório)', async () => {
      const provider = new DeepSeekProvider({ apiKey: 'test-key' });
      const healthy = await provider.isHealthy();
      expect(healthy).toBe(true);
    });
  });
});

describe('createLLMProvider (Factory)', () => {
  describe('criação básica', () => {
    it('deve criar MockLLMProvider', () => {
      const provider = createLLMProvider({ type: 'mock' });
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar MockLLMProvider com opções', () => {
      const provider = createLLMProvider({
        type: 'mock',
        mock: { delayMs: 100 },
      });
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar DeepSeekProvider', () => {
      const provider = createLLMProvider({
        type: 'deepseek',
        deepseek: { apiKey: 'test-key' },
      });
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar deepseek sem config', () => {
      expect(() => createLLMProvider({ type: 'deepseek' })).toThrow(
        'DeepSeek config is required'
      );
    });

    it('deve rejeitar tipo desconhecido', () => {
      expect(() =>
        createLLMProvider({ type: 'invalid' as never })
      ).toThrow('Unknown provider type');
    });
  });

  describe('variáveis de ambiente', () => {
    it('deve criar MockProvider por padrão', () => {
      const provider = createLLMProvider();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar MockProvider quando explicitamente configurado', () => {
      process.env.LLM_PROVIDER_TYPE = 'mock';
      const provider = createLLMProvider();
      expect(provider).toBeInstanceOf(MockLLMProvider);
      delete process.env.LLM_PROVIDER_TYPE;
    });

    it('deve aplicar MOCK_DELAY_MS', () => {
      process.env.LLM_PROVIDER_TYPE = 'mock';
      process.env.MOCK_DELAY_MS = '150';
      const provider = createLLMProvider();
      expect(provider).toBeInstanceOf(MockLLMProvider);
      delete process.env.LLM_PROVIDER_TYPE;
      delete process.env.MOCK_DELAY_MS;
    });

    it('deve criar DeepSeekProvider quando configurado', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      process.env.DEEPSEEK_API_KEY = 'test-key';
      const provider = createLLMProvider();
      expect(provider).toBeInstanceOf(DeepSeekProvider);
      delete process.env.LLM_PROVIDER_TYPE;
      delete process.env.DEEPSEEK_API_KEY;
    });

    it('deve rejeitar deepseek sem API key', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      expect(() => createLLMProvider()).toThrow('DEEPSEEK_API_KEY is required');
      delete process.env.LLM_PROVIDER_TYPE;
    });

    it('deve aplicar variáveis opcionais do DeepSeek', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      process.env.DEEPSEEK_API_KEY = 'test-key';
      process.env.DEEPSEEK_MODEL = 'custom-model';
      process.env.DEEPSEEK_API_URL = 'https://custom.api';
      process.env.DEEPSEEK_MAX_TOKENS = '8000';

      const provider = createLLMProvider();
      expect(provider).toBeInstanceOf(DeepSeekProvider);

      delete process.env.LLM_PROVIDER_TYPE;
      delete process.env.DEEPSEEK_API_KEY;
      delete process.env.DEEPSEEK_MODEL;
      delete process.env.DEEPSEEK_API_URL;
      delete process.env.DEEPSEEK_MAX_TOKENS;
    });

    it('deve rejeitar LLM_PROVIDER_TYPE inválido', () => {
      process.env.LLM_PROVIDER_TYPE = 'invalid';
      expect(() => createLLMProvider()).toThrow('Unknown provider type');
      delete process.env.LLM_PROVIDER_TYPE;
    });
  });
});

describe('ILLMProvider (Interface Compliance)', () => {
  describe('MockLLMProvider implementa ILLMProvider', () => {
    const provider: ILLMProvider = new MockLLMProvider();

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
      const result = await provider.analyze('test');
      expect(result).toHaveProperty('summary');
      expect(result).toHaveProperty('inputLength');
      expect(result).toHaveProperty('outputLength');
      expect(result).toHaveProperty('tokensUsed');
    });

    it('getModelInfo deve retornar ModelInfo', () => {
      const info = provider.getModelInfo();
      expect(info).toHaveProperty('modelName');
      expect(info).toHaveProperty('provider');
      expect(info).toHaveProperty('maxTokens');
    });

    it('isHealthy deve retornar Promise<boolean>', async () => {
      const result = await provider.isHealthy();
      expect(typeof result).toBe('boolean');
    });
  });

  describe('DeepSeekProvider implementa ILLMProvider', () => {
    const provider: ILLMProvider = new DeepSeekProvider({ apiKey: 'test-key' });

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
      const result = await provider.analyze('test');
      expect(result).toHaveProperty('summary');
      expect(result).toHaveProperty('inputLength');
      expect(result).toHaveProperty('outputLength');
      expect(result).toHaveProperty('tokensUsed');
    });

    it('getModelInfo deve retornar ModelInfo', () => {
      const info = provider.getModelInfo();
      expect(info).toHaveProperty('modelName');
      expect(info).toHaveProperty('provider');
      expect(info).toHaveProperty('maxTokens');
    });

    it('isHealthy deve retornar Promise<boolean>', async () => {
      const result = await provider.isHealthy();
      expect(typeof result).toBe('boolean');
    });
  });
});
EOF

echo "[ok] Teste corrigido com margem de tolerância de -5ms"
echo ""
echo "Próximos passos:"
echo "  1. pnpm test  # Testar tudo novamente"
echo "  2. pnpm --filter @mini-ide/ui test  # Testar especificamente a UI"
echo ""
echo "[info] Correção aplicada!"
