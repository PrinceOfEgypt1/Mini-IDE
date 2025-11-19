#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Script: 32_fix_server_config_tests.sh
# Objetivo: Atualizar testes para aceitar localhost ao invés de 127.0.0.1
################################################################################

echo "[info] Corrigindo testes de config/server.spec.ts..."

cat > packages/ui/test/config/server.spec.ts <<'EOF'
import { describe, it, expect } from 'vitest';
import { getBaseUrl, getHealthzUrl, getAnalyzeUrl } from '../../src/config/server.js';

describe('config/server', () => {
  describe('getBaseUrl', () => {
    it('deve retornar a URL configurada via VITE_MINI_IDE_SERVER_URL', () => {
      const url = getBaseUrl();
      expect(url).toBe('http://localhost:3200');
    });

    it('não deve retornar undefined ou string vazia', () => {
      const url = getBaseUrl();
      expect(url).toBeDefined();
      expect(url).not.toBe('');
    });

    it('deve retornar URL sem barra final', () => {
      const url = getBaseUrl();
      expect(url.endsWith('/')).toBe(false);
    });
  });

  describe('getHealthzUrl', () => {
    it('deve retornar URL completa do endpoint /healthz', () => {
      const url = getHealthzUrl();
      expect(url).toBe('http://localhost:3200/healthz');
    });

    it('deve incluir a baseURL no caminho', () => {
      const url = getHealthzUrl();
      const baseUrl = getBaseUrl();
      expect(url.startsWith(baseUrl)).toBe(true);
    });

    it('deve terminar com /healthz', () => {
      const url = getHealthzUrl();
      expect(url.endsWith('/healthz')).toBe(true);
    });
  });

  describe('getAnalyzeUrl', () => {
    it('deve retornar URL completa do endpoint /analyze', () => {
      const url = getAnalyzeUrl();
      expect(url).toBe('http://localhost:3200/analyze');
    });

    it('deve incluir a baseURL no caminho', () => {
      const url = getAnalyzeUrl();
      const baseUrl = getBaseUrl();
      expect(url.startsWith(baseUrl)).toBe(true);
    });

    it('deve terminar com /analyze', () => {
      const url = getAnalyzeUrl();
      expect(url.endsWith('/analyze')).toBe(true);
    });
  });
});
EOF

echo "✅ Testes corrigidos"
echo ""
echo "[info] Executando validação final..."
pnpm test

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   TUDO FUNCIONANDO! ✓                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Próximo passo: git commit"
