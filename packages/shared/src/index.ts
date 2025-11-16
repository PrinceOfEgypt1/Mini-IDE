export function hello(name = 'world'): string {
  return `hello, ${name}`;
}

// Contrato oficial do endpoint /analyze
export type { AnalyzeResponse } from './types/analyze-response.js';
export { isAnalyzeResponse, REQUIRED_FIELDS, OPTIONAL_FIELDS } from './types/analyze-response.js';
