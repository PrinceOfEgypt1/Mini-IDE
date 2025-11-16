#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Script: 02g_fix_empty_validation_scientific.sh
# Objetivo: Correção CIENTÍFICA da validação de texto vazio
# Versão: 1.0.17-patch6
# Data: 2024-11-15
#
# MÉTODO CIENTÍFICO APLICADO:
#
# 1. OBSERVAÇÃO:
#    - Teste envia { text: '' } (string vazia)
#    - Esperado: mensagem com "vazio"
#    - Recebido: mensagem com "obrigatório"
#
# 2. HIPÓTESE:
#    - Em JavaScript: !'' === true (string vazia é falsy)
#    - Logo !request.body.text é TRUE para string vazia
#    - Cai no primeiro if e retorna "obrigatório" incorretamente
#
# 3. EXPERIMENTO:
#    - Separar validações em dois ifs sequenciais
#    - Primeiro: verificar ausência (undefined/null)
#    - Segundo: verificar vazio (string vazia ou trim)
#
# 4. VALIDAÇÃO:
#    - Executar testes para confirmar 40/40 passando
#
# Arquivos afetados:
# - packages/server/src/index.ts (CORRIGIDO CIENTIFICAMENTE)
###############################################################################

echo "[info] Aplicando MÉTODO CIENTÍFICO para corrigir validação"
echo "[info] Data: $(date)"
echo ""

# Verificar se estamos na raiz do projeto
if [[ ! -f "package.json" ]] || [[ ! -d "packages" ]]; then
  echo "[erro] Este script deve ser executado da raiz do monorepo Mini-IDE"
  exit 1
fi

# Criar backup
echo "[info] Criando backup (.bak)..."
cp packages/server/src/index.ts packages/server/src/index.ts.bak
echo "[ok] Backup criado"

###############################################################################
# index.ts (CORREÇÃO CIENTÍFICA)
###############################################################################
echo ""
echo "[info] Aplicando correção científica na validação..."

# Usar sed para corrigir APENAS a seção de validação (linhas 121-139)
cat > /tmp/validation_fix.txt << 'ENDOFPATCH'
    // CORREÇÃO CIENTÍFICA v1.0.17-patch6:
    // Separar validações para evitar !'' === true

    // Validação 1: text ausente (undefined ou null)
    if (!request.body || request.body.text === undefined || request.body.text === null) {
      request.log.warn({
        event: 'analyze_validation_error',
        requestId,
        error: 'text_missing',
      });
      return reply.code(400).send({
        error: 'Validação falhou',
        message: 'Campo "text" é obrigatório',
        requestId,
        timestamp,
      });
    }

    // Validação 2: text vazio (string vazia ou apenas espaços)
    if (request.body.text.trim() === '') {
      request.log.warn({
        event: 'analyze_validation_error',
        requestId,
        error: 'text_empty',
      });
      return reply.code(400).send({
        error: 'Validação falhou',
        message: 'Campo "text" não pode estar vazio',
        requestId,
        timestamp,
      });
    }
ENDOFPATCH

# Fazer backup da validação antiga e substituir pela nova
sed -i.tmp '/CORRIGIDO v1.0.17-patch5: Validar trim/,/^    }$/c\'"$(cat /tmp/validation_fix.txt)" packages/server/src/index.ts

rm -f /tmp/validation_fix.txt packages/server/src/index.ts.tmp

echo "[ok] Validação corrigida cientificamente"

###############################################################################
# Validação final
###############################################################################
echo ""
echo "[info] Executando typecheck..."

if pnpm --filter @mini-ide/server typecheck; then
  echo "[ok] ✅ Typecheck passou!"
else
  echo "[erro] ❌ Typecheck falhou."
  exit 1
fi

echo ""
echo "[info] Executando TODOS os testes..."

if NODE_ENV=test pnpm --filter @mini-ide/server test; then
  echo ""
  echo "=========================================="
  echo "✅ SUCESSO TOTAL! 40/40 TESTES PASSANDO!"
  echo "=========================================="
else
  echo "[erro] ❌ Ainda há testes falhando."
  exit 1
fi

# Remover backup
echo ""
echo "[info] Removendo backup (.bak)..."
rm -f packages/server/src/index.ts.bak
echo "[ok] Backup removido"

###############################################################################
# Resumo científico
###############################################################################
echo ""
echo "=========================================="
echo "🔬 MÉTODO CIENTÍFICO APLICADO COM SUCESSO"
echo "=========================================="
echo ""
echo "1️⃣  OBSERVAÇÃO:"
echo "   - Teste enviava { text: '' }"
echo "   - Recebia mensagem errada ('obrigatório' ao invés de 'vazio')"
echo ""
echo "2️⃣  HIPÓTESE:"
echo "   - !'' === true em JavaScript (string vazia é falsy)"
echo "   - Validação combinada causava detecção incorreta"
echo ""
echo "3️⃣  EXPERIMENTO:"
echo "   - Separadas validações em dois ifs sequenciais"
echo "   - Primeiro: ausência (undefined/null)"
echo "   - Segundo: vazio (trim === '')"
echo ""
echo "4️⃣  VALIDAÇÃO:"
echo "   ✅ Typecheck: PASSOU (0 erros)"
echo "   ✅ Testes: 40/40 PASSANDO (100%)"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "   1. Commit: git add packages/server/"
echo "   2. Commit: git commit -m 'fix(server): corrigir validação científica de texto vazio'"
echo "   3. 🚀🚀🚀 FINALMENTE Script 3 (HU-Quality-Coverage-Thresholds)"
echo ""
echo "[ok] Script finalizado em $(date)"
