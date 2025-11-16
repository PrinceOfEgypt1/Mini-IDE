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
export type { ILLMProvider, LLMAnalyzeOptions, LLMResponse, ModelInfo } from './ILLMProvider.js';

// Mock Provider
export { MockLLMProvider } from './MockLLMProvider.js';
export type { MockProviderOptions } from './MockLLMProvider.js';

// DeepSeek Provider
export { DeepSeekProvider } from './DeepSeekProvider.js';
export type { DeepSeekConfig } from './DeepSeekProvider.js';

// Factory
export { LLMProviderFactory } from './LLMProviderFactory.js';
export type { ProviderType, ProviderFactoryConfig } from './LLMProviderFactory.js';
