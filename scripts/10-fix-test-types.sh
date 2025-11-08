#!/usr/bin/env bash
# scripts/10-fix-test-types.sh
#
# Descrição: Corrige tipagem do analyze.spec.ts (erro TS2347)
# Uso: bash scripts/10-fix-test-types.sh
# Pré-requisitos: bash
# Efeitos colaterais: Corrige analyze.spec.ts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

TARGET_FILE="packages/server/test/analyze.spec.ts"

echo "========================================="
echo "CORREÇÃO - analyze.spec.ts (TS2347)"
echo "========================================="
echo ""
echo "[info] Corrigindo ${TARGET_FILE}..."

# Backup
cp "${TARGET_FILE}" "${TARGET_FILE}.bak-ts2347"

# Criar analyze.spec.ts com tipagem correta
cat > "${TARGET_FILE}" << 'TYPESCRIPT_CODE'
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

    const body = response.json() as AnalyzeResponse;

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

    const body = response.json() as AnalyzeResponse;

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

    const body = response.json() as AnalyzeResponse;

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

    const body = response.json() as AnalyzeResponse;
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

    const body = response.json() as AnalyzeResponse;
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

    const body = response.json() as AnalyzeResponse;
    expect(body.summary.length).toBe(1000);
  });
});
TYPESCRIPT_CODE

echo "[ok] Arquivo corrigido (usa 'as AnalyzeResponse' em vez de generic)"
echo ""

# Rodar typecheck
echo "[info] Running typecheck..."
if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] Typecheck passed!"
else
  echo "[erro] Typecheck failed"
  exit 1
fi

echo ""
echo "========================================="
echo "[ok] CORREÇÃO COMPLETA"
echo "========================================="
echo ""
echo "Mudança aplicada:"
echo "  response.json<AnalyzeResponse>()  →  response.json() as AnalyzeResponse"
echo ""
echo "Próximo: REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh"
