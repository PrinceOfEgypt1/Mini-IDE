#!/usr/bin/env bash
set -euo pipefail

##
# MINI-IDE :: Fix Lint Lote 1 (shared + server tests)
#
# Objetivo:
#   - Eliminar todos os erros de ESLint relatados no pre-commit:
#     * no-unsafe-assignment / no-unsafe-member-access (tests /analyze-400, /analyze-500)
#     * no-unnecessary-type-assertion (analyze.spec.ts)
#     * no-unused-vars (test-utils.ts)
#     * no-explicit-any / no-unsafe-assignment (llm-provider.spec.ts)
#
# Arquivos afetados:
#   - packages/server/test/analyze-400.spec.ts
#   - packages/server/test/analyze-500.spec.ts
#   - packages/server/test/analyze.spec.ts
#   - packages/server/test/test-utils.ts
#   - packages/shared/test/llm-provider.spec.ts
#
# Como usar:
#   chmod +x scripts/04_fix_lint_lote1.sh
#   scripts/04_fix_lint_lote1.sh
#
# Depois:
#   pnpm lint
#   pnpm test
#   pnpm typecheck
#   pnpm build
##

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[info] Diretório raiz detectado: $ROOT_DIR"
echo "[info] Iniciando correções de lint do Lote 1..."

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local backup="${file}.bak.lint_fix_lote1"
    cp "$file" "$backup"
    echo "[ok] Backup criado: $backup"
  else
    echo "[warn] Arquivo não encontrado para backup: $file"
  fi
}

###############################################################################
# 1) packages/server/test/analyze-400.spec.ts
###############################################################################

TARGET_400="packages/server/test/analyze-400.spec.ts"
backup_file "$TARGET_400"

cat > "$TARGET_400" << 'EOF'
/**
 * @file analyze-400.spec.ts
 * @description Testes de validação 4xx para endpoint /analyze
 *
 * CHANGELOG v1.0.17:
 * - Removido uso de resetBudget (não existe mais - budget agora é por contexto)
 * - Removido tipo ErrorResponse (não exportado)
 * - Usando jsonUnknown<T>() para parse seguro da resposta
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { server } from '../src/index.js';
import { jsonUnknown } from './test-utils.js';

interface ErrorBody {
  error: string;
  message: string;
  requestId: string;
  timestamp: string;
}

describe('POST /analyze - Validações 4xx', () => {
  beforeAll(async () => {
    await server.ready();
  });

  afterAll(async () => {
    await server.close();
  });

  describe('400 - Bad Request', () => {
    it('deve retornar 400 quando text estiver ausente', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          maxLen: 100,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('text');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando text estiver vazio', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: '',
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('vazio');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando text for apenas espaços', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: '   ',
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('vazio');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando maxLen < 1', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste',
          maxLen: 0,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('maxLen');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });

    it('deve retornar 400 quando maxLen > 1000', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste',
          maxLen: 1001,
        },
      });

      expect(response.statusCode).toBe(400);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Validação falhou');
      expect(body.message).toContain('maxLen');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });
  });
});
EOF

echo "[ok] Corrigido: $TARGET_400"

###############################################################################
# 2) packages/server/test/analyze-500.spec.ts
###############################################################################

TARGET_500="packages/server/test/analyze-500.spec.ts"
backup_file "$TARGET_500"

cat > "$TARGET_500" << 'EOF'
/**
 * @file analyze-500.spec.ts
 * @description Testes de erro 5xx para endpoint /analyze
 *
 * CHANGELOG v1.0.17:
 * - Removido uso de resetBudget e recordUsage (não existem mais)
 * - Budget agora é por contexto, cada requisição tem seu próprio budget
 * - Removido tipo ErrorResponse (não exportado)
 *
 * NOTA: Testes de budget excedido agora estão em budget.spec.ts
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { server } from '../src/index.js';
import { jsonUnknown } from './test-utils.js';

interface ErrorBody {
  error: string;
  message: string;
  requestId: string;
  timestamp: string;
}

describe('POST /analyze - Erros 5xx e 402 Budget', () => {
  beforeAll(async () => {
    await server.ready();
  });

  afterAll(async () => {
    await server.close();
  });

  describe('500 - Internal Server Error (estrutura esperada)', () => {
    it('deve processar requisição válida com 200 (estrutura de erro documentada em comentário)', async () => {
      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: 'teste válido',
        },
      });

      // Aqui garantimos que o caminho feliz funciona.
      expect(response.statusCode).toBe(200);

      // Se um dia simulássemos erro 500 real,
      // a estrutura esperada seria:
      // { error, message, requestId, timestamp }
    });
  });

  describe('402 - Budget Exceeded', () => {
    it('deve retornar 402 quando budget for insuficiente', async () => {
      // Criar um texto muito grande para exceder budget de R$ 10.00
      // Budget mock: R$ 0.01 por 1000 chars
      // Para exceder R$ 10.00, precisa > 1.000.000 chars
      const largeText = 'a'.repeat(1_500_000); // R$ 15.00 estimado

      const response = await server.inject({
        method: 'POST',
        url: '/analyze',
        payload: {
          text: largeText,
          maxLen: 100,
        },
      });

      expect(response.statusCode).toBe(402);

      const body = jsonUnknown<ErrorBody>(response);

      expect(body.error).toBe('Orçamento excedido');
      expect(body.message).toContain('Budget');
      expect(body.requestId).toBeDefined();
      expect(body.timestamp).toBeDefined();
    });
  });
});
EOF

echo "[ok] Corrigido: $TARGET_500"

###############################################################################
# 3) packages/server/test/analyze.spec.ts
#    - Remover type assertions desnecessárias ("as string")
###############################################################################

TARGET_ANALYZE="packages/server/test/analyze.spec.ts"
backup_file "$TARGET_ANALYZE"

cat > "$TARGET_ANALYZE" << 'EOF'
/**
 * @file analyze.spec.ts
 * @description Testes do endpoint /analyze
 *
 * CHANGELOG v1.0.17-patch4:
 * - Tipos corrigidos para corresponder a AnalyzeResponse real
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { build, shutdown, inject, status, jsonUnknown } from './test-utils.js';

describe('POST /analyze', () => {
  let server: Awaited<ReturnType<typeof build>>;

  beforeAll(async () => {
    server = await build();
  });

  afterAll(async () => {
    await shutdown(server);
  });

  it('deve processar texto com maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      inputLength: number;
      outputLength: number;
      requestId: string;
      timestamp: string;
      budgetUsed: number;
      budgetRemaining: number;
    }>(response);

    expect(body['summary']).toBeDefined();
    expect(body['summary'].length).toBeLessThanOrEqual(10);
    expect(body['inputLength']).toBeDefined();
    expect(body['outputLength']).toBeDefined();
    expect(body['requestId']).toBeDefined();
    expect(body['timestamp']).toBeDefined();
  });

  it('deve aplicar maxLen padrão quando não especificado', async () => {
    const longText = 'a'.repeat(200);
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: longText },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{ summary: string }>(response);
    expect(body['summary'].length).toBeLessThanOrEqual(100);
  });

  it('deve incluir requestId e timestamp na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test analysis', maxLen: 50 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown<{
      summary: string;
      requestId: string;
      timestamp: string;
    }>(response);
    expect(body['requestId']).toBeDefined();
    expect(String(body['requestId'])).toMatch(/^req_/u);
    expect(body['timestamp']).toBeDefined();
  });

  it('deve incluir informações de budget na resposta', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Test budget tracking', maxLen: 100 },
    });

    expect(status(response)).toBe(200);
    const body = jsonUnknown(response);
    expect(body['budgetUsed']).toBeDefined();
    expect(body['budgetRemaining']).toBeDefined();
    expect(typeof body['budgetUsed']).toBe('number');
    expect(typeof body['budgetRemaining']).toBe('number');
  });
});
EOF

echo "[ok] Corrigido: $TARGET_ANALYZE"

###############################################################################
# 4) packages/server/test/test-utils.ts
#    - Marcar parâmetro não utilizado com prefixo "_"
###############################################################################

TARGET_UTILS="packages/server/test/test-utils.ts"
backup_file "$TARGET_UTILS"

cat > "$TARGET_UTILS" << 'EOF'
/**
 * @file test-utils.ts
 * @description Utilitários para testes do servidor (API retrocompatível)
 *
 * CHANGELOG v1.0.17-patch3:
 * - API retrocompatível: aceita inject(server, opts) OU inject(opts)
 * - API retrocompatível: aceita shutdown(server) OU shutdown()
 * - jsonUnknown com suporte a type generics
 *
 * @version 1.0.17-patch3
 */

import type { FastifyInstance } from 'fastify';
import type { InjectOptions, Response } from 'light-my-request';
import { server } from '../src/index.js';

/**
 * Instância do servidor para uso nos testes
 */
let testServer: FastifyInstance | null = null;

/**
 * Inicializa o servidor para testes
 *
 * @returns Promise com instância do servidor pronta
 */
export async function build(): Promise<FastifyInstance> {
  if (!testServer) {
    testServer = server;
    await testServer.ready();
  }
  return testServer;
}

/**
 * Fecha o servidor após os testes
 * RETROCOMPATÍVEL: aceita shutdown(server) OU shutdown()
 *
 * @param _serverInstance - (Opcional) instância do servidor (ignorada, mantida por retrocompatibilidade)
 */
export async function shutdown(_serverInstance?: FastifyInstance): Promise<void> {
  // Ignora _serverInstance - mantido apenas para retrocompatibilidade
  if (testServer) {
    await testServer.close();
    testServer = null;
  }
}

/**
 * Helper para fazer requisições de teste
 * RETROCOMPATÍVEL: aceita inject(server, opts) OU inject(opts)
 *
 * @param serverOrOptions - Servidor (ignorado) OU opções da requisição
 * @param optionsIfServerProvided - Opções se primeiro param for servidor
 * @returns Promise com resposta da requisição
 */
export async function inject(
  serverOrOptions: FastifyInstance | InjectOptions,
  optionsIfServerProvided?: InjectOptions
): Promise<Response> {
  if (!testServer) {
    await build();
  }

  // Detectar qual assinatura foi usada
  const options: InjectOptions = optionsIfServerProvided
    ? optionsIfServerProvided // inject(server, options) - API antiga
    : (serverOrOptions as InjectOptions); // inject(options) - API nova

  return testServer!.inject(options);
}

/**
 * Type guard para verificar se objeto é um Record válido
 */
function isRecord(obj: unknown): obj is Record<string, unknown> {
  return typeof obj === 'object' && obj !== null && !Array.isArray(obj);
}

/**
 * Helper para extrair status code de resposta
 */
export function status(response: Response): number {
  return response.statusCode;
}

/**
 * Helper para parsear JSON de resposta com type safety
 * SUPORTA GENERICS: jsonUnknown<Type>(response)
 *
 * @param response - Resposta da requisição
 * @returns Objeto parseado do JSON
 * @throws Error se o body não for JSON válido
 */
export function jsonUnknown<T = Record<string, unknown>>(response: Response): T {
  try {
    const parsed: unknown = JSON.parse(response.body);
    if (isRecord(parsed)) {
      return parsed as T;
    }
    throw new Error('Response body não é um objeto JSON válido');
  } catch (error) {
    throw new Error(
      `Falha ao parsear JSON: ${error instanceof Error ? error.message : 'Unknown error'}`
    );
  }
}
EOF

echo "[ok] Corrigido: $TARGET_UTILS"

###############################################################################
# 5) packages/shared/test/llm-provider.spec.ts
#    - Remover uso de "as any" em teste de tipo inválido
###############################################################################

TARGET_LLM_SPEC="packages/shared/test/llm-provider.spec.ts"
backup_file "$TARGET_LLM_SPEC"

cat > "$TARGET_LLM_SPEC" << 'EOF'
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
      expect(() =>
        LLMProviderFactory.create({ type: 'deepseek' })
      ).toThrow('deepseekConfig é obrigatória');
    });

    it('deve rejeitar tipo desconhecido', () => {
      // Aqui usamos um cast via unknown -> never para evitar "any" e ainda assim
      // exercitar o caminho de erro com valor em runtime inválido.
      expect(() =>
        LLMProviderFactory.create({ type: 'invalid' as unknown as never })
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
EOF

echo "[ok] Corrigido: $TARGET_LLM_SPEC"

echo
echo "==============================================="
echo "[ok] Correções de lint do Lote 1 aplicadas."
echo "Agora rode:"
echo "  pnpm lint"
echo "  pnpm test"
echo "  pnpm typecheck"
echo "  pnpm build"
echo "Se tudo ficar verde, tente o commit novamente."
echo "==============================================="
EOF
