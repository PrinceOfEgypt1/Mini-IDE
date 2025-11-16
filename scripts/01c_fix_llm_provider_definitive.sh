#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 01c_fix_llm_provider_definitive.sh
# Objetivo: Correção DEFINITIVA dos erros TypeScript (reescrita completa)
# Versão: 1.0.17-patch2
# Data: 2024-11-15
#
# Este script REESCREVE os 3 arquivos completamente com as correções aplicadas.
# Abordagem definitiva ao invés de sed que pode duplicar conteúdo.
#
# Arquivos afetados:
# - packages/shared/src/llm/LLMProviderFactory.ts (REESCRITO)
# - packages/shared/src/llm/MockLLMProvider.ts (REESCRITO)
# - packages/shared/test/llm-provider.spec.ts (REESCRITO)
#
# Premissas:
# - Script 01 já foi executado
# - Arquivos .bak podem existir de tentativa anterior
#
# Riscos:
# - Sobrescreve arquivos existentes (cria backup antes)
#
# Como reverter:
# - Backups em .bak: mv arquivo.ts.bak arquivo.ts
###############################################################################

echo "[info] Iniciando correção DEFINITIVA de erros TypeScript"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Restaurar backups se existirem (de tentativa anterior)
echo "[info] Verificando backups de tentativa anterior..."
if [[ -f "packages/shared/src/llm/MockLLMProvider.ts.bak" ]]; then
  echo "[info] Restaurando arquivos originais dos backups..."
  mv packages/shared/src/llm/LLMProviderFactory.ts.bak packages/shared/src/llm/LLMProviderFactory.ts
  mv packages/shared/src/llm/MockLLMProvider.ts.bak packages/shared/src/llm/MockLLMProvider.ts
  mv packages/shared/test/llm-provider.spec.ts.bak packages/shared/test/llm-provider.spec.ts
  echo "[ok] Arquivos originais restaurados"
fi

# Criar novos backups
echo "[info] Criando novos backups (.bak)..."
cp packages/shared/src/llm/LLMProviderFactory.ts packages/shared/src/llm/LLMProviderFactory.ts.bak
cp packages/shared/src/llm/MockLLMProvider.ts packages/shared/src/llm/MockLLMProvider.ts.bak
cp packages/shared/test/llm-provider.spec.ts packages/shared/test/llm-provider.spec.ts.bak
echo "[ok] Backups criados"

###############################################################################
# ARQUIVO 1/3: MockLLMProvider.ts (REESCRITO COMPLETO)
###############################################################################
echo ""
echo "[info] Reescrevendo MockLLMProvider.ts (correção linha 64)..."

cat > packages/shared/src/llm/MockLLMProvider.ts << 'ENDOFFILE'
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

  async analyze(prompt: string, options?: LLMAnalyzeOptions): Promise<LLMResponse> {
    const startTime = Date.now();

    // Simular delay se configurado - CORRIGIDO: garantir que não é undefined
    if (this.options.simulateDelayMs > 0) {
      await new Promise(resolve => setTimeout(resolve, this.options.simulateDelayMs));
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
    const content = this.options.customResponse 
      || `[MOCK] Análise do prompt: "${prompt.substring(0, 50)}${prompt.length > 50 ? '...' : ''}"`;

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

  async isHealthy(): Promise<boolean> {
    // Mock sempre está "saudável" a menos que configurado para falhar
    if (this.options.simulateFailure) {
      throw new Error('MockLLMProvider: Health check falhou (simulado)');
    }
    return true;
  }
}
ENDOFFILE

echo "[ok] MockLLMProvider.ts reescrito (118 linhas)"

###############################################################################
# ARQUIVO 2/3: LLMProviderFactory.ts (REESCRITO COMPLETO)
###############################################################################
echo "[info] Reescrevendo LLMProviderFactory.ts (7 correções process.env)..."

cat > packages/shared/src/llm/LLMProviderFactory.ts << 'ENDOFFILE'
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
          throw new Error(
            'LLMProviderFactory: deepseekConfig é obrigatória para type="deepseek"'
          );
        }
        return new DeepSeekProvider(config.deepseekConfig);
      }

      default: {
        const exhaustive: never = config.type;
        throw new Error(`LLMProviderFactory: Tipo de provider desconhecido: ${exhaustive}`);
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
    // CORRIGIDO: usar bracket notation para process.env
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
            'Defina a variável ou use LLM_PROVIDER_TYPE=mock para testes.'
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

      default:
        throw new Error(
          `LLMProviderFactory: LLM_PROVIDER_TYPE inválido: "${providerType}". ` +
          'Valores aceitos: "mock", "deepseek"'
        );
    }
  }
}
ENDOFFILE

echo "[ok] LLMProviderFactory.ts reescrito (138 linhas)"

###############################################################################
# ARQUIVO 3/3: llm-provider.spec.ts (REESCRITO COMPLETO - primeira parte)
###############################################################################
echo "[info] Reescrevendo llm-provider.spec.ts (14 correções process.env)..."

cat > packages/shared/test/llm-provider.spec.ts << 'ENDOFFILE'
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
        response.usage.promptTokens + response.usage.completionTokens
      );
      expect(response.model).toBe('mock-llm-v1');
      expect(response.processingTimeMs).toBeGreaterThanOrEqual(0);
      expect(response.requestId).toMatch(/^mock_/);
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
      expect(() => 
        LLMProviderFactory.create({ type: 'deepseek' })
      ).toThrow('deepseekConfig é obrigatória');
    });

    it('deve rejeitar tipo desconhecido', () => {
      expect(() =>
        LLMProviderFactory.create({ type: 'invalid' as any })
      ).toThrow('Tipo de provider desconhecido');
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
      // CORRIGIDO: usar bracket notation
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
ENDOFFILE

echo "[ok] llm-provider.spec.ts reescrito (374 linhas)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando typecheck para validar correções..."

if pnpm --filter @mini-ide/shared typecheck; then
  echo "[ok] ✅ Typecheck passou! Todos os erros foram corrigidos."
else
  echo "[erro] ❌ Ainda há erros de TypeScript."
  echo "[info] Restaurar backups: mv arquivo.ts.bak arquivo.ts"
  exit 1
fi

echo ""
echo "[info] Executando testes para garantir que nada quebrou..."

if pnpm --filter @mini-ide/shared test llm-provider; then
  echo "[ok] ✅ Todos os 46 testes ainda estão passando!"
else
  echo "[erro] ❌ Alguns testes quebraram. Revise as correções."
  exit 1
fi

# Remover backups se tudo passou
echo ""
echo "[info] Removendo backups (.bak)..."
rm -f packages/shared/src/llm/LLMProviderFactory.ts.bak
rm -f packages/shared/src/llm/MockLLMProvider.ts.bak
rm -f packages/shared/test/llm-provider.spec.ts.bak
echo "[ok] Backups removidos"

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 01c executado com sucesso!"
echo "=========================================="
echo ""
echo "🔧 Arquivos reescritos:"
echo "   - MockLLMProvider.ts: 118 linhas (linha 64 corrigida)"
echo "   - LLMProviderFactory.ts: 138 linhas (7 process.env corrigidos)"
echo "   - llm-provider.spec.ts: 374 linhas (14 process.env corrigidos)"
echo ""
echo "📊 Total: 22 erros de TypeScript corrigidos"
echo ""
echo "✅ Validações:"
echo "   - Typecheck: PASSOU"
echo "   - Testes (46): TODOS PASSANDO"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Verificar diff: git diff packages/shared/"
echo "   2. Commit: git add packages/shared/"
echo "   3. Commit: git commit -m 'fix(shared): corrigir erros strict TypeScript em LLM Provider'"
echo "   4. Prosseguir para Script 2 (HU-Server-Budget-Per-Context)"
echo ""
echo "[ok] Script finalizado em $(date)"
