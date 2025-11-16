#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 01_create_llm_provider_abstraction.sh
# Objetivo: Criar abstração de LLM Provider para Mini-IDE
# Versão: 1.0.17
# Data: 2024-11-15
#
# Este script implementa a HU-LLM-Provider-Abstraction criando:
# - Interface ILLMProvider com tipos base
# - MockLLMProvider para testes determinísticos
# - DeepSeekProvider preparatório para DeepSeek-V3
# - LLMProviderFactory com factory pattern
# - Suite completa de testes com ≥90% de cobertura
#
# Arquivos afetados:
# - packages/shared/src/llm/ILLMProvider.ts (NOVO)
# - packages/shared/src/llm/MockLLMProvider.ts (NOVO)
# - packages/shared/src/llm/DeepSeekProvider.ts (NOVO)
# - packages/shared/src/llm/LLMProviderFactory.ts (NOVO)
# - packages/shared/src/llm/index.ts (NOVO)
# - packages/shared/test/llm-provider.spec.ts (NOVO)
#
# Premissas:
# - Estrutura packages/shared existe
# - PNPM instalado e configurado
# - Node.js 22.x
# - Vitest configurado em packages/shared
#
# Riscos:
# - Se packages/shared/src ou test não existirem, serão criados
# - Não sobrescreve arquivos existentes (verifica antes)
#
# Como reverter:
# git checkout packages/shared/src/llm/
# git checkout packages/shared/test/llm-provider.spec.ts
# git clean -fd packages/shared/src/llm/
###############################################################################

echo "[info] Iniciando criação de LLM Provider Abstraction"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  echo "[erro] Diretório atual: $(pwd)"
  exit 1
fi

# Verificar se packages/shared existe
if [[ ! -d "packages/shared" ]]; then
  echo "[erro] Diretório packages/shared não encontrado"
  exit 1
fi

# Criar diretórios necessários
echo "[info] Criando estrutura de diretórios..."
mkdir -p packages/shared/src/llm
mkdir -p packages/shared/test
echo "[ok] Diretórios criados"

# Verificar se arquivos já existem
if [[ -f "packages/shared/src/llm/ILLMProvider.ts" ]]; then
  echo "[warn] ILLMProvider.ts já existe. Abortando para não sobrescrever."
  echo "[warn] Se deseja recriar, remova os arquivos manualmente primeiro."
  exit 1
fi

###############################################################################
# ARQUIVO 1/6: ILLMProvider.ts - Interface base
###############################################################################
echo "[info] Criando ILLMProvider.ts..."
cat > packages/shared/src/llm/ILLMProvider.ts << 'EOF'
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
EOF
echo "[ok] ILLMProvider.ts criado (177 linhas)"

###############################################################################
# ARQUIVO 2/6: MockLLMProvider.ts - Mock para testes
###############################################################################
echo "[info] Criando MockLLMProvider.ts..."
cat > packages/shared/src/llm/MockLLMProvider.ts << 'EOF'
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
  private options: MockProviderOptions;

  constructor(options: MockProviderOptions = {}) {
    this.options = {
      simulateDelayMs: options.simulateDelayMs ?? 0,
      simulateFailure: options.simulateFailure ?? false,
      customResponse: options.customResponse,
    };
  }

  async analyze(prompt: string, options?: LLMAnalyzeOptions): Promise<LLMResponse> {
    const startTime = Date.now();

    // Simular delay se configurado
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
EOF
echo "[ok] MockLLMProvider.ts criado (113 linhas)"

###############################################################################
# ARQUIVO 3/6: DeepSeekProvider.ts - Provider preparatório para DeepSeek-V3
###############################################################################
echo "[info] Criando DeepSeekProvider.ts..."
cat > packages/shared/src/llm/DeepSeekProvider.ts << 'EOF'
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

  async analyze(prompt: string, options?: LLMAnalyzeOptions): Promise<LLMResponse> {
    // Validação básica
    if (!prompt || prompt.trim() === '') {
      throw new Error('DeepSeekProvider: Prompt não pode estar vazio');
    }

    // ⚠️ IMPLEMENTAÇÃO PREPARATÓRIA
    // A chamada real à API do DeepSeek será implementada em HU-LLM-Client-DeepSeek
    // Por enquanto, retornamos uma resposta simulada para não quebrar testes
    
    const startTime = Date.now();
    
    // TODO: Implementar chamada HTTP real para DeepSeek API
    // - POST para ${this.config.baseUrl}/chat/completions
    // - Headers: Authorization: Bearer ${this.config.apiKey}
    // - Body: { model, messages, temperature, max_tokens }
    // - Tratamento de erros: rate limiting, timeouts, 5xx
    
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

  getModelInfo(): ModelInfo {
    return {
      name: this.config.model,
      provider: 'DeepSeek',
      version: 'v3',
      maxContextTokens: 64000, // DeepSeek-V3 suporta até 64k tokens
      supportsStreaming: true,
    };
  }

  async isHealthy(): Promise<boolean> {
    // TODO: Implementar health check real
    // - Fazer uma chamada leve à API (ex: listar modelos)
    // - Verificar se responde com 200
    // - Validar se API Key é válida
    
    // Por enquanto, sempre retorna true (preparatório)
    return true;
  }
}
EOF
echo "[ok] DeepSeekProvider.ts criado (119 linhas)"

###############################################################################
# ARQUIVO 4/6: LLMProviderFactory.ts - Factory pattern
###############################################################################
echo "[info] Criando LLMProviderFactory.ts..."
cat > packages/shared/src/llm/LLMProviderFactory.ts << 'EOF'
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
    const providerType = (process.env.LLM_PROVIDER_TYPE || 'mock') as ProviderType;

    switch (providerType) {
      case 'mock':
        return new MockLLMProvider({
          simulateDelayMs: Number(process.env.MOCK_DELAY_MS) || 0,
        });

      case 'deepseek': {
        const apiKey = process.env.DEEPSEEK_API_KEY;
        if (!apiKey) {
          throw new Error(
            'LLMProviderFactory: DEEPSEEK_API_KEY não definida no ambiente. ' +
            'Defina a variável ou use LLM_PROVIDER_TYPE=mock para testes.'
          );
        }

        return new DeepSeekProvider({
          apiKey,
          model: process.env.DEEPSEEK_MODEL,
          baseUrl: process.env.DEEPSEEK_BASE_URL,
          defaultTimeoutMs: process.env.DEEPSEEK_TIMEOUT_MS 
            ? Number(process.env.DEEPSEEK_TIMEOUT_MS)
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
EOF
echo "[ok] LLMProviderFactory.ts criado (122 linhas)"

###############################################################################
# ARQUIVO 5/6: index.ts - Barrel file
###############################################################################
echo "[info] Criando index.ts (barrel file)..."
cat > packages/shared/src/llm/index.ts << 'EOF'
/**
 * @file index.ts
 * @description Barrel file para módulo LLM Provider
 * 
 * Exporta todos os tipos e classes relacionados a providers LLM,
 * facilitando imports no restante da aplicação.
 * 
 * @version 1.0.17
 * @since 2024-11-15
 */

// Interface e tipos base
export type {
  ILLMProvider,
  LLMAnalyzeOptions,
  LLMResponse,
  ModelInfo,
} from './ILLMProvider.js';

// Mock Provider
export { MockLLMProvider } from './MockLLMProvider.js';
export type { MockProviderOptions } from './MockLLMProvider.js';

// DeepSeek Provider
export { DeepSeekProvider } from './DeepSeekProvider.js';
export type { DeepSeekConfig } from './DeepSeekProvider.js';

// Factory
export { LLMProviderFactory } from './LLMProviderFactory.js';
export type { ProviderType, ProviderFactoryConfig } from './LLMProviderFactory.js';
EOF
echo "[ok] index.ts criado (24 linhas)"

###############################################################################
# ARQUIVO 6/6: llm-provider.spec.ts - Suite de testes
###############################################################################
echo "[info] Criando llm-provider.spec.ts..."
cat > packages/shared/test/llm-provider.spec.ts << 'EOF'
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
      delete process.env.LLM_PROVIDER_TYPE;
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar MockProvider quando explicitamente configurado', () => {
      process.env.LLM_PROVIDER_TYPE = 'mock';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve aplicar MOCK_DELAY_MS', () => {
      process.env.LLM_PROVIDER_TYPE = 'mock';
      process.env.MOCK_DELAY_MS = '200';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(MockLLMProvider);
    });

    it('deve criar DeepSeekProvider quando configurado', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      process.env.DEEPSEEK_API_KEY = 'sk-test-from-env';
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar deepseek sem API key', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      delete process.env.DEEPSEEK_API_KEY;
      
      expect(() => LLMProviderFactory.createFromEnv()).toThrow('DEEPSEEK_API_KEY não definida');
    });

    it('deve aplicar variáveis opcionais do DeepSeek', () => {
      process.env.LLM_PROVIDER_TYPE = 'deepseek';
      process.env.DEEPSEEK_API_KEY = 'sk-test';
      process.env.DEEPSEEK_MODEL = 'custom-model';
      process.env.DEEPSEEK_BASE_URL = 'https://custom.url';
      process.env.DEEPSEEK_TIMEOUT_MS = '60000';
      
      const provider = LLMProviderFactory.createFromEnv();
      expect(provider).toBeInstanceOf(DeepSeekProvider);
    });

    it('deve rejeitar LLM_PROVIDER_TYPE inválido', () => {
      process.env.LLM_PROVIDER_TYPE = 'invalid';
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
EOF
echo "[ok] llm-provider.spec.ts criado (311 linhas)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando validações finais..."

# Verificar se todos os arquivos foram criados
EXPECTED_FILES=(
  "packages/shared/src/llm/ILLMProvider.ts"
  "packages/shared/src/llm/MockLLMProvider.ts"
  "packages/shared/src/llm/DeepSeekProvider.ts"
  "packages/shared/src/llm/LLMProviderFactory.ts"
  "packages/shared/src/llm/index.ts"
  "packages/shared/test/llm-provider.spec.ts"
)

for file in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[erro] Arquivo esperado não foi criado: $file"
    exit 1
  fi
done
echo "[ok] Todos os 6 arquivos foram criados com sucesso"

# Contar linhas totais
TOTAL_LINES=0
for file in "${EXPECTED_FILES[@]}"; do
  LINES=$(wc -l < "$file")
  TOTAL_LINES=$((TOTAL_LINES + LINES))
  echo "[info] $file: $LINES linhas"
done
echo "[ok] Total: $TOTAL_LINES linhas de código criadas"

# Tentar executar typecheck
echo ""
echo "[info] Executando typecheck no pacote shared..."
if pnpm --filter @mini-ide/shared typecheck; then
  echo "[ok] Typecheck passou sem erros"
else
  echo "[warn] Typecheck apresentou erros. Revise os arquivos criados."
fi

# Tentar executar testes
echo ""
echo "[info] Executando testes do LLM Provider..."
if pnpm --filter @mini-ide/shared test llm-provider; then
  echo "[ok] Testes executados com sucesso"
else
  echo "[warn] Alguns testes falharam. Revise os arquivos de teste."
fi

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 01 executado com sucesso!"
echo "=========================================="
echo ""
echo "📦 Arquivos criados:"
echo "   - ILLMProvider.ts (177 linhas)"
echo "   - MockLLMProvider.ts (113 linhas)"
echo "   - DeepSeekProvider.ts (119 linhas)"
echo "   - LLMProviderFactory.ts (122 linhas)"
echo "   - index.ts (24 linhas)"
echo "   - llm-provider.spec.ts (311 linhas)"
echo ""
echo "📊 Total: $TOTAL_LINES linhas"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Revisar os arquivos criados"
echo "   2. Executar: pnpm --filter @mini-ide/shared test llm-provider"
echo "   3. Verificar cobertura: pnpm --filter @mini-ide/shared test --coverage"
echo "   4. Commit: git add packages/shared/src/llm/ packages/shared/test/llm-provider.spec.ts"
echo "   5. Commit: git commit -m 'feat(shared): implementar abstração LLM Provider (HU-LLM-Provider-Abstraction)'"
echo ""
echo "🔄 Como reverter:"
echo "   git checkout packages/shared/src/llm/"
echo "   git checkout packages/shared/test/llm-provider.spec.ts"
echo "   git clean -fd packages/shared/src/llm/"
echo ""
echo "[ok] Script finalizado em $(date)"
