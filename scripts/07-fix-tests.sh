#!/usr/bin/env bash
# scripts/07-fix-tests.sh
#
# Descrição: Corrige testes de healthz e cria analyze.spec.ts completo
# Uso: bash scripts/07-fix-tests.sh
# Pré-requisitos: bash
# Efeitos colaterais: Sobrescreve arquivos de teste

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

echo "========================================="
echo "CORREÇÃO DE TESTES - healthz + analyze"
echo "========================================="
echo ""

# 1. Corrigir healthz.spec.ts
HEALTHZ_FILE="packages/server/test/healthz.spec.ts"
echo "[1] Corrigindo ${HEALTHZ_FILE}..."

# Backup
cp "${HEALTHZ_FILE}" "${HEALTHZ_FILE}.bak-fix"

# Novo healthz.spec.ts compatível com resposta atual
cat > "${HEALTHZ_FILE}" << 'TYPESCRIPT_CODE'
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import Fastify from "fastify";
import { registerRoutes } from "../src/index.js";

/**
 * Interface da resposta do /healthz
 */
interface HealthzResponse {
  status: string;
  timestamp: string;
}

/**
 * Type guard para HealthzResponse
 */
function isHealthzResponse(x: unknown): x is HealthzResponse {
  return (
    typeof x === "object" &&
    x !== null &&
    "status" in x &&
    typeof x.status === "string" &&
    "timestamp" in x &&
    typeof x.timestamp === "string"
  );
}

/**
 * Assertion helper
 */
function assertHealthzResponse(x: unknown): asserts x is HealthzResponse {
  if (!isHealthzResponse(x)) {
    throw new Error("Invalid HealthzResponse");
  }
}

describe("server :: /healthz", () => {
  let app: ReturnType<typeof Fastify>;

  beforeAll(async () => {
    app = Fastify({ logger: false });
    registerRoutes(app);
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it("retorna status ok e timestamp ISO-8601", async () => {
    const response = await app.inject({
      method: "GET",
      url: "/healthz",
    });

    expect(response.statusCode).toBe(200);

    const body = response.json();
    assertHealthzResponse(body);

    expect(body.status).toBe("ok");
    expect(body.timestamp).toBeTruthy();

    // Valida formato ISO-8601
    expect(() => new Date(body.timestamp)).not.toThrow();
    expect(body.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  });
});
TYPESCRIPT_CODE

echo "[ok] healthz.spec.ts corrigido"
echo ""

# 2. Criar analyze.spec.ts completo
ANALYZE_FILE="packages/server/test/analyze.spec.ts"
echo "[2] Criando ${ANALYZE_FILE}..."

# Backup se existir
if [[ -f "${ANALYZE_FILE}" ]]; then
  cp "${ANALYZE_FILE}" "${ANALYZE_FILE}.bak-fix"
fi

# Novo analyze.spec.ts com testes da HU
cat > "${ANALYZE_FILE}" << 'TYPESCRIPT_CODE'
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import Fastify from "fastify";
import { registerRoutes, type AnalyzeResponse } from "../src/index.js";

describe("POST /analyze - Happy Path (200)", () => {
  let app: ReturnType<typeof Fastify>;

  beforeAll(async () => {
    app = Fastify({ logger: false });
    registerRoutes(app);
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  it("AC1: should return 200 with valid text and maxLen", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: "Olá Mini-IDE!",
        maxLen: 10,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();

    // Verifica campos obrigatórios
    expect(body).toHaveProperty("summary");
    expect(body).toHaveProperty("tokensUsed");
    expect(body).toHaveProperty("runId");
    expect(body).toHaveProperty("ts");

    // Valida tipos
    expect(typeof body.summary).toBe("string");
    expect(typeof body.tokensUsed).toBe("number");
    expect(typeof body.runId).toBe("string");
    expect(typeof body.ts).toBe("string");

    // Valida maxLen aplicado
    expect(body.summary.length).toBeLessThanOrEqual(10);
    expect(body.summary).toBe("Olá Mini-I");

    // Valida tokensUsed (split por espaço)
    expect(body.tokensUsed).toBe(2); // "Olá" e "Mini-IDE!"

    // Valida formato ISO-8601 do timestamp
    expect(() => new Date(body.ts)).not.toThrow();
    expect(body.ts).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);

    // Valida formato do runId
    expect(body.runId).toMatch(/^run-[0-9a-f-]{36}$/);
  });

  it("AC2: should use default maxLen (100) when omitted", async () => {
    const longText = "a".repeat(150); // Texto com 150 caracteres

    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: longText,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();

    // Valida que maxLen padrão (100) foi aplicado
    expect(body.summary.length).toBe(100);
    expect(body.tokensUsed).toBe(1); // Um único "token" sem espaços
  });

  it("AC3: should include all required fields in response", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: "Texto de teste",
        maxLen: 50,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();

    // Validação de presença de todos os campos
    expect(body).toHaveProperty("summary");
    expect(body).toHaveProperty("tokensUsed");
    expect(body).toHaveProperty("runId");
    expect(body).toHaveProperty("ts");

    // Validação de valores não-vazios
    expect(body.summary).toBeTruthy();
    expect(body.tokensUsed).toBeGreaterThan(0);
    expect(body.runId).toBeTruthy();
    expect(body.ts).toBeTruthy();
  });

  it("should handle text with multiple tokens correctly", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: "Um dois três quatro cinco",
        maxLen: 100,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();
    expect(body.tokensUsed).toBe(5); // 5 palavras separadas por espaço
  });

  it("should handle maxLen at minimum boundary (1)", async () => {
    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: "Teste",
        maxLen: 1,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();
    expect(body.summary).toBe("T");
    expect(body.summary.length).toBe(1);
  });

  it("should handle maxLen at maximum boundary (1000)", async () => {
    const longText = "x".repeat(2000);

    const response = await app.inject({
      method: "POST",
      url: "/analyze",
      payload: {
        text: longText,
        maxLen: 1000,
      },
    });

    expect(response.statusCode).toBe(200);

    const body = response.json<AnalyzeResponse>();
    expect(body.summary.length).toBe(1000);
  });
});
TYPESCRIPT_CODE

echo "[ok] analyze.spec.ts criado"
echo ""

# 3. Rodar testes para validar
echo "[3] Running tests..."
if pnpm --filter @mini-ide/server test; then
  echo "[ok] All tests passed!"
else
  echo "[erro] Some tests failed"
  exit 1
fi

echo ""
echo "========================================="
echo "[ok] TESTES CORRIGIDOS - SUCESSO!"
echo "========================================="
echo ""
echo "Arquivos atualizados:"
echo "  ✓ packages/server/test/healthz.spec.ts"
echo "  ✓ packages/server/test/analyze.spec.ts"
echo ""
echo "Próximo: bash scripts/smoke-analyze-200.sh"
