#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 01b_fix_llm_provider_typescript_errors.sh
# Objetivo: Corrigir 22 erros de TypeScript no Script 1 (strict mode)
# Versão: 1.0.17-patch1
# Data: 2024-11-15
#
# Este script corrige os erros de strict TypeScript encontrados após
# execução do Script 1, relacionados a:
# - TS4111: Acesso a process.env com bracket notation
# - TS2532: Possibilidade de undefined em this.options
#
# Arquivos afetados:
# - packages/shared/src/llm/LLMProviderFactory.ts (7 correções)
# - packages/shared/src/llm/MockLLMProvider.ts (1 correção)
# - packages/shared/test/llm-provider.spec.ts (14 correções)
#
# Premissas:
# - Script 01 já foi executado
# - Arquivos existem em packages/shared/
#
# Riscos:
# - Sobrescreve arquivos existentes (cria backup antes)
#
# Como reverter:
# - Backups em .bak: mv arquivo.ts.bak arquivo.ts
###############################################################################

echo "[info] Iniciando correção de erros TypeScript do Script 1"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Verificar se arquivos existem
FILES_TO_FIX=(
  "packages/shared/src/llm/LLMProviderFactory.ts"
  "packages/shared/src/llm/MockLLMProvider.ts"
  "packages/shared/test/llm-provider.spec.ts"
)

for file in "${FILES_TO_FIX[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "[erro] Arquivo não encontrado: $file"
    echo "[erro] Execute primeiro o script 01_create_llm_provider_abstraction.sh"
    exit 1
  fi
done

# Criar backups
echo "[info] Criando backups (.bak)..."
for file in "${FILES_TO_FIX[@]}"; do
  cp "$file" "$file.bak"
  echo "[ok] Backup criado: $file.bak"
done

###############################################################################
# CORREÇÃO 1/3: LLMProviderFactory.ts (7 erros)
###############################################################################
echo ""
echo "[info] Corrigindo LLMProviderFactory.ts (7 erros)..."

FILE="packages/shared/src/llm/LLMProviderFactory.ts"

# Erro 1: linha 104 - LLM_PROVIDER_TYPE
sed -i "s/process\.env\.LLM_PROVIDER_TYPE/process.env['LLM_PROVIDER_TYPE']/g" "$FILE"

# Erro 2: linha 109 - MOCK_DELAY_MS
sed -i "s/process\.env\.MOCK_DELAY_MS/process.env['MOCK_DELAY_MS']/g" "$FILE"

# Erro 3: linha 113 - DEEPSEEK_API_KEY
sed -i "s/process\.env\.DEEPSEEK_API_KEY/process.env['DEEPSEEK_API_KEY']/g" "$FILE"

# Erro 4: linha 123 - DEEPSEEK_MODEL
sed -i "s/process\.env\.DEEPSEEK_MODEL/process.env['DEEPSEEK_MODEL']/g" "$FILE"

# Erro 5: linha 124 - DEEPSEEK_BASE_URL
sed -i "s/process\.env\.DEEPSEEK_BASE_URL/process.env['DEEPSEEK_BASE_URL']/g" "$FILE"

# Erro 6 e 7: linhas 125-126 - DEEPSEEK_TIMEOUT_MS (2 ocorrências)
sed -i "s/process\.env\.DEEPSEEK_TIMEOUT_MS/process.env['DEEPSEEK_TIMEOUT_MS']/g" "$FILE"

echo "[ok] LLMProviderFactory.ts corrigido (7 erros)"

###############################################################################
# CORREÇÃO 2/3: MockLLMProvider.ts (1 erro)
###############################################################################
echo ""
echo "[info] Corrigindo MockLLMProvider.ts (1 erro)..."

FILE="packages/shared/src/llm/MockLLMProvider.ts"

# Erro: linha 64 - this.options.simulateDelayMs possivelmente undefined
# Solução: usar optional chaining ou garantir inicialização
sed -i 's/if (this\.options\.simulateDelayMs > 0) {/if (this.options.simulateDelayMs && this.options.simulateDelayMs > 0) {/' "$FILE"

echo "[ok] MockLLMProvider.ts corrigido (1 erro)"

###############################################################################
# CORREÇÃO 3/3: llm-provider.spec.ts (14 erros)
###############################################################################
echo ""
echo "[info] Corrigindo llm-provider.spec.ts (14 erros)..."

FILE="packages/shared/test/llm-provider.spec.ts"

# Todas as ocorrências de process.env.* devem usar bracket notation
sed -i "s/process\.env\.LLM_PROVIDER_TYPE/process.env['LLM_PROVIDER_TYPE']/g" "$FILE"
sed -i "s/process\.env\.MOCK_DELAY_MS/process.env['MOCK_DELAY_MS']/g" "$FILE"
sed -i "s/process\.env\.DEEPSEEK_API_KEY/process.env['DEEPSEEK_API_KEY']/g" "$FILE"
sed -i "s/process\.env\.DEEPSEEK_MODEL/process.env['DEEPSEEK_MODEL']/g" "$FILE"
sed -i "s/process\.env\.DEEPSEEK_BASE_URL/process.env['DEEPSEEK_BASE_URL']/g" "$FILE"
sed -i "s/process\.env\.DEEPSEEK_TIMEOUT_MS/process.env['DEEPSEEK_TIMEOUT_MS']/g" "$FILE"

echo "[ok] llm-provider.spec.ts corrigido (14 erros)"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando typecheck para validar correções..."

if pnpm --filter @mini-ide/shared typecheck; then
  echo "[ok] ✅ Typecheck passou! Todos os 22 erros foram corrigidos."
else
  echo "[erro] ❌ Ainda há erros de TypeScript. Revise manualmente."
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
for file in "${FILES_TO_FIX[@]}"; do
  rm -f "$file.bak"
  echo "[ok] Removido: $file.bak"
done

###############################################################################
# Resumo final
###############################################################################
echo ""
echo "=========================================="
echo "✅ Script 01b executado com sucesso!"
echo "=========================================="
echo ""
echo "🔧 Correções aplicadas:"
echo "   - LLMProviderFactory.ts: 7 erros corrigidos"
echo "   - MockLLMProvider.ts: 1 erro corrigido"
echo "   - llm-provider.spec.ts: 14 erros corrigidos"
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
