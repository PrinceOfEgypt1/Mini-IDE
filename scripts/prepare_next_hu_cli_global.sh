#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: prepare_next_hu_cli_global.sh
# Objetivo: Preparar HU "CLI-Global: Instalação e Validação do CLI Global"
#           (apenas preparação, não habilita por padrão)
# ==============================================================================
# Affected files:
#   - docs/HU-CLI-Global.md (novo arquivo com especificação da HU)
#   - .github/ISSUE_TEMPLATE/hu-cli-global.md (template de issue, se aplicável)
# ==============================================================================
# Assumptions:
#   - Diretório docs/ existe
#   - REQUIRE_GLOBAL_CLI já implementado no checklist
# ==============================================================================
# Risks:
#   - Nenhum (apenas documentação)
# ==============================================================================
# How to revert:
#   - git restore docs/HU-CLI-Global.md
# ==============================================================================

echo "[info] Iniciando preparação da HU-CLI-Global"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[info]${NC} $*"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

# ==============================================================================
# 1) Criar diretório docs se não existir
# ==============================================================================
mkdir -p docs

# ==============================================================================
# 2) Gerar especificação completa da HU
# ==============================================================================
HU_FILE="docs/HU-CLI-Global.md"

log_info "Gerando especificação da HU em $HU_FILE..."

cat > "$HU_FILE" << 'EOF_HU'
# HU-CLI-Global-100

**História de Usuário: Instalação e Validação do CLI Global**

---

## 1) Identificação

- **ID**: HU-CLI-Global-100
- **Área**: CLI
- **Tópico**: Global Installation
- **Prioridade**: P1 (Médio prazo)
- **Status**: 📋 Preparada (não implementada)

---

## 2) História

**Como** desenvolvedor do Mini-IDE  
**Quero** instalar o CLI globalmente via npm/pnpm  
**Para** utilizar o comando `mini-ide` de qualquer diretório do sistema, sem precisar especificar o caminho completo do executável

---

## 3) Contexto e Motivação

Atualmente, o CLI do Mini-IDE precisa ser executado via:
```bash
node packages/cli/dist/index.js analyze "texto" --maxLen N --url http://127.0.0.1:3200
```

Isso é:
- **Verboso** e pouco prático para uso diário
- **Dependente** de estar no diretório raiz do monorepo
- **Não intuitivo** para usuários finais

A instalação global permitirá:
```bash
mini-ide analyze "texto" --maxLen N
# Automaticamente usa http://127.0.0.1:3200 por padrão
```

**Impacto esperado**:
- ✅ Melhor experiência de usuário (DX)
- ✅ Compatibilidade com workflows de CI/CD
- ✅ Facilita adoção e testes por terceiros
- ✅ Validação automática no pipeline (opcional via `REQUIRE_GLOBAL_CLI=1`)

---

## 4) Critérios de Aceite (Gherkin)

### CA-1: Instalação global via npm

**Dado** que o pacote @mini-ide/cli está publicado no npm/registry local  
**Quando** executo `npm install -g @mini-ide/cli`  
**Então** o comando `mini-ide` deve estar disponível globalmente  
**E** `mini-ide --version` deve retornar a versão correta do CLI  

### CA-2: Instalação global via pnpm

**Dado** que estou no monorepo Mini-IDE  
**Quando** executo `pnpm install -g .` no diretório do pacote CLI  
**Então** o comando `mini-ide` deve estar disponível globalmente  
**E** `mini-ide analyze --help` deve mostrar a ajuda do comando  

### CA-3: Execução do CLI global

**Dado** que o CLI está instalado globalmente  
**E** o servidor está rodando em `http://127.0.0.1:3200`  
**Quando** executo `mini-ide analyze "Teste global" --maxLen 20`  
**Então** o CLI deve fazer requisição ao servidor padrão `:3200`  
**E** deve salvar o bundle em `bundles/v1.0.12/*.json`  
**E** deve exibir mensagem de sucesso  

### CA-4: Fallback quando servidor não está disponível

**Dado** que o CLI está instalado globalmente  
**E** o servidor **não está** rodando  
**Quando** executo `mini-ide analyze "Teste offline"`  
**Então** o CLI deve exibir mensagem clara de erro: "Servidor não disponível em http://127.0.0.1:3200"  
**E** deve sugerir: "Execute 'mini-ide server start' ou verifique se o servidor está rodando"  
**E** deve retornar código de saída `3` (erro de rede)  

### CA-5: Validação no pipeline (opcional)

**Dado** que `REQUIRE_GLOBAL_CLI=1` está definido  
**Quando** executo `./42_pipeline_checklist.sh`  
**Então** o checklist deve validar a existência do comando `mini-ide`  
**E** deve verificar `mini-ide --version`  
**E** deve executar `mini-ide analyze "Pipeline test" --maxLen 10`  
**E** deve FALHAR se o CLI global não estiver instalado  

**Dado** que `REQUIRE_GLOBAL_CLI=0` ou não definido  
**Quando** executo `./42_pipeline_checklist.sh`  
**Então** a validação do CLI global deve ser **pulada** ou exibir apenas warning  

---

## 5) Escopo

### ✅ Dentro do Escopo

- Adicionar campo `"bin"` no `packages/cli/package.json` apontando para o executável
- Criar shebang `#!/usr/bin/env node` no entry point do CLI
- Garantir que imports ESM funcionem quando instalado globalmente
- Atualizar README com instruções de instalação global
- Adicionar validação opcional no `42_pipeline_checklist.sh` (toggle `REQUIRE_GLOBAL_CLI`)
- Criar smoke test específico para instalação global
- Documentar fallback amigável quando servidor não estiver disponível

### ❌ Fora do Escopo

- Publicação no npm público (apenas validação local/privada por enquanto)
- Criação de comando `mini-ide server start` (pode ser HU futura)
- Auto-update do CLI global
- Telemetria de uso do CLI

---

## 6) Notas de Teste

### Comandos de validação manual:

```bash
# 1) Build do CLI
pnpm --filter @mini-ide/cli build

# 2) Instalação global (link local para desenvolvimento)
pnpm --filter @mini-ide/cli exec npm link

# 3) Verificar instalação
which mini-ide
mini-ide --version

# 4) Subir servidor
PORT=3200 node packages/server/dist/index.js &

# 5) Testar CLI global
mini-ide analyze "Teste de instalação global" --maxLen 25

# 6) Testar fallback (sem servidor)
killall node
mini-ide analyze "Teste offline"
# Deve exibir mensagem amigável de erro

# 7) Validação no pipeline
REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh
# Deve validar CLI global

REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
# Deve pular validação do CLI global

# 8) Desinstalar (cleanup)
npm uninstall -g @mini-ide/cli
```

### Dados de teste:

- Texto curto: `"Hello CLI"`
- Texto médio: `"Testing global CLI installation with some longer text"`
- Texto longo: `"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua..."`
- maxLen: 10, 50, 200

### Expectativas:

- CLI global deve funcionar independente do diretório atual
- Saída deve ser idêntica à execução local via `node packages/cli/dist/index.js`
- Códigos de saída: `0` (sucesso), `2` (validação), `3` (rede)
- Bundles devem ser salvos em `bundles/v1.0.12/` com timestamp

---

## 7) Impactos

### Código

- `packages/cli/package.json`: adicionar campo `"bin": { "mini-ide": "./dist/index.js" }`
- `packages/cli/src/index.ts`: garantir shebang e compatibilidade ESM
- `packages/cli/README.md`: documentar instalação global

### Scripts

- `42_pipeline_checklist.sh`: adicionar etapa opcional de validação do CLI global
- `scripts/smoke.sh`: novo smoke test para CLI global

### Documentação

- `README.md` (raiz): atualizar seção de instalação
- `docs/CLI_GLOBAL.md`: novo guia de instalação e troubleshooting
- `CHANGELOG.md`: registrar nova funcionalidade

### CI/CD

- Nenhum impacto imediato (validação opcional via `REQUIRE_GLOBAL_CLI`)

---

## 8) Definition of Done (DoD)

- [ ] ✅ Campo `"bin"` adicionado em `packages/cli/package.json`
- [ ] ✅ Shebang `#!/usr/bin/env node` adicionado no entry point
- [ ] ✅ `npm link` funciona localmente e instala comando `mini-ide`
- [ ] ✅ `mini-ide --version` retorna versão correta
- [ ] ✅ `mini-ide analyze` funciona de qualquer diretório
- [ ] ✅ Fallback amigável quando servidor não está disponível (erro de rede com dicas)
- [ ] ✅ Validação no checklist com toggle `REQUIRE_GLOBAL_CLI` (0/1)
- [ ] ✅ Smoke test para CLI global criado em `scripts/smoke_global.sh`
- [ ] ✅ README atualizado com instruções de instalação global
- [ ] ✅ Testes unitários para validação de instalação (mocks de `which`, `npm`)
- [ ] ✅ Checklist e smoke passando 100% verde (ambos modos: local e global)
- [ ] ✅ Commit com mensagem Conventional Commits (ex.: `feat(cli): instalação global via npm/pnpm`)
- [ ] ✅ Pull Request aberto e aprovado
- [ ] ✅ Sem regressões nos testes existentes

---

## 9) Riscos e Mitigações

### Risco 1: Conflito de PATH
**Descrição**: CLI pode não ser encontrado após instalação global  
**Probabilidade**: Média  
**Impacto**: Alto  
**Mitigação**:
- Documentar verificação de `which mini-ide`
- Adicionar troubleshooting no README
- Validar PATH em diferentes shells (bash, zsh, fish)

### Risco 2: Incompatibilidade ESM em instalação global
**Descrição**: Imports com `.js` podem falhar quando instalado globalmente  
**Probabilidade**: Baixa  
**Impacto**: Crítico  
**Mitigação**:
- Testar instalação global antes de merge
- Garantir que `tsconfig.build.json` está com NodeNext
- Smoke test deve validar execução real (não apenas build)

### Risco 3: Servidor não disponível (UX ruim)
**Descrição**: CLI falha com erro genérico quando servidor está off  
**Probabilidade**: Alta  
**Impacto**: Médio  
**Mitigação**:
- Implementar retry com backoff exponencial (3 tentativas)
- Mensagem clara: "Servidor não disponível em :3200. Execute 'node packages/server/dist/index.js'"
- Código de saída `3` (rede) distinto de `2` (validação)

---

## 10) Rollback

Se a instalação global causar problemas:

```bash
# 1) Desinstalar CLI global
npm uninstall -g @mini-ide/cli

# 2) Reverter mudanças no package.json
git restore packages/cli/package.json

# 3) Voltar para execução local
node packages/cli/dist/index.js analyze "text" --maxLen N

# 4) Desabilitar validação no checklist
export REQUIRE_GLOBAL_CLI=0
```

---

## 11) Próximos Passos (após implementação)

- **HU-CLI-Server-Start**: Comando `mini-ide server start` para subir servidor em background
- **HU-CLI-Config**: Arquivo de configuração `~/.mini-ide/config.json` para customizar URL, porta, etc.
- **HU-CLI-Publish**: Publicação oficial no npm público (após testes internos)
- **HU-CLI-Telemetry**: Coleta anônima de métricas de uso (opt-in)

---

## 12) Referências

- ADR: `docs/ADR-CLI-GLOBAL.md` (decisão de tornar validação opcional)
- Checklist: `42_pipeline_checklist.sh` (variável `REQUIRE_GLOBAL_CLI`)
- Smoke test: `scripts/smoke.sh` (template para smoke global)
- npm docs: https://docs.npmjs.com/cli/v9/configuring-npm/package-json#bin

---

**Status da HU**: 📋 Preparada (aguardando implementação)  
**Criado em**: 2025-11-09  
**Última atualização**: 2025-11-09  
EOF_HU

log_ok "Especificação da HU criada em $HU_FILE"

# ==============================================================================
# 3) Criar template de issue para GitHub (opcional)
# ==============================================================================
ISSUE_TEMPLATE_DIR=".github/ISSUE_TEMPLATE"

if [ -d ".github" ]; then
  mkdir -p "$ISSUE_TEMPLATE_DIR"
  
  ISSUE_TEMPLATE_FILE="$ISSUE_TEMPLATE_DIR/hu-cli-global.md"
  
  log_info "Gerando template de issue para GitHub..."
  
  cat > "$ISSUE_TEMPLATE_FILE" << 'EOF_ISSUE'
---
name: HU-CLI-Global-100
about: Instalação e validação do CLI global
title: '[HU-CLI-Global] Instalação e validação do CLI global via npm/pnpm'
labels: enhancement, cli, P1
assignees: ''
---

## História de Usuário

**Como** desenvolvedor do Mini-IDE  
**Quero** instalar o CLI globalmente via npm/pnpm  
**Para** utilizar o comando `mini-ide` de qualquer diretório do sistema

## Contexto

Ver especificação completa em: `docs/HU-CLI-Global.md`

## Critérios de Aceite

- [ ] Campo `"bin"` adicionado em `packages/cli/package.json`
- [ ] `npm install -g @mini-ide/cli` funciona
- [ ] `mini-ide --version` retorna versão correta
- [ ] `mini-ide analyze` funciona de qualquer diretório
- [ ] Fallback amigável quando servidor não está disponível
- [ ] Validação no checklist com toggle `REQUIRE_GLOBAL_CLI`

## DoD

- [ ] Testes unitários criados e passando
- [ ] Smoke test para CLI global
- [ ] README atualizado
- [ ] Checklist 100% verde
- [ ] PR aberto e aprovado

## Notas

- Prioridade: **P1** (médio prazo)
- Não bloqueia release atual (opcional via `REQUIRE_GLOBAL_CLI=0`)
EOF_ISSUE
  
  log_ok "Template de issue criado em $ISSUE_TEMPLATE_FILE"
else
  log_warn "Diretório .github não existe, pulando criação de template de issue"
fi

# ==============================================================================
# 4) Gerar checklist de validação da HU
# ==============================================================================
CHECKLIST_FILE="docs/HU-CLI-Global-Checklist.md"

log_info "Gerando checklist de validação em $CHECKLIST_FILE..."

cat > "$CHECKLIST_FILE" << 'EOF_CHECKLIST'
# Checklist de Validação: HU-CLI-Global-100

## Pré-requisitos

- [ ] Servidor Mini-IDE rodando em `:3200`
- [ ] Repositório atualizado (`git pull --ff-only`)
- [ ] PNPM instalado e atualizado

---

## Desenvolvimento

- [ ] 1. Adicionar campo `"bin"` em `packages/cli/package.json`
  ```json
  "bin": {
    "mini-ide": "./dist/index.js"
  }
  ```

- [ ] 2. Adicionar shebang no entry point (`packages/cli/src/index.ts`)
  ```typescript
  #!/usr/bin/env node
  ```

- [ ] 3. Garantir permissão de execução após build
  ```bash
  chmod +x packages/cli/dist/index.js
  ```

- [ ] 4. Testar instalação local via link
  ```bash
  pnpm --filter @mini-ide/cli build
  pnpm --filter @mini-ide/cli exec npm link
  ```

- [ ] 5. Verificar comando global disponível
  ```bash
  which mini-ide
  mini-ide --version
  ```

- [ ] 6. Testar execução básica
  ```bash
  mini-ide analyze "Test" --maxLen 10
  ```

- [ ] 7. Implementar fallback para servidor offline
  - Detectar `ECONNREFUSED`
  - Exibir mensagem amigável
  - Retornar código de saída `3`

- [ ] 8. Adicionar toggle no checklist (`REQUIRE_GLOBAL_CLI`)
  - Valor `1`: valida CLI global (obrigatório)
  - Valor `0`: pula validação (padrão atual)

- [ ] 9. Criar smoke test para CLI global (`scripts/smoke_global.sh`)

---

## Testes

- [ ] 10. Testes unitários para CLI global
  - Mock de `which mini-ide`
  - Mock de `npm list -g`
  - Validação de PATH

- [ ] 11. Smoke test manual
  ```bash
  bash scripts/smoke_global.sh
  ```

- [ ] 12. Pipeline completo
  ```bash
  REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh
  ```

---

## Documentação

- [ ] 13. Atualizar `README.md` (raiz) com instruções de instalação global

- [ ] 14. Criar `docs/CLI_GLOBAL.md` com troubleshooting

- [ ] 15. Atualizar `CHANGELOG.md` com nova funcionalidade

---

## Validação Final

- [ ] 16. Checklist passa 100% verde (modo local e global)

- [ ] 17. Smoke test passa sem erros

- [ ] 18. CLI funciona de qualquer diretório do sistema

- [ ] 19. Fallback amigável quando servidor está offline

- [ ] 20. Nenhuma regressão em testes existentes

---

## Commit e PR

- [ ] 21. Commit com Conventional Commits
  ```
  feat(cli): instalação global via npm/pnpm
  
  - Adiciona campo "bin" no package.json
  - Implementa fallback amigável para servidor offline
  - Adiciona validação opcional no checklist (REQUIRE_GLOBAL_CLI)
  - Cria smoke test para CLI global
  ```

- [ ] 22. Push para branch `feat/cli-global-installation`

- [ ] 23. Abrir PR no GitHub

- [ ] 24. Aguardar code review e aprovação

---

## Rollback (se necessário)

- [ ] Desinstalar CLI global: `npm uninstall -g @mini-ide/cli`
- [ ] Reverter package.json: `git restore packages/cli/package.json`
- [ ] Desabilitar validação: `export REQUIRE_GLOBAL_CLI=0`
EOF_CHECKLIST

log_ok "Checklist de validação criado em $CHECKLIST_FILE"

# ==============================================================================
# 5) Instruções para ativar a HU no futuro
# ==============================================================================
ACTIVATION_GUIDE="docs/HU-CLI-Global-Activation.md"

log_info "Gerando guia de ativação em $ACTIVATION_GUIDE..."

cat > "$ACTIVATION_GUIDE" << 'EOF_ACTIVATION'
# Guia de Ativação: HU-CLI-Global-100

Este documento contém instruções para **ativar** a HU-CLI-Global-100 quando for o momento adequado.

---

## Status Atual

- **Preparação**: ✅ Concluída (especificação, checklist, templates)
- **Implementação**: ⏳ Pendente
- **Validação no checklist**: ❌ Desabilitada por padrão (`REQUIRE_GLOBAL_CLI=0`)

---

## Quando Ativar?

Esta HU deve ser ativada quando:
1. ✅ Pipeline atual está 100% verde e estável
2. ✅ Todos os hardening de checklist/auditoria foram concluídos
3. ✅ Não há HUs de maior prioridade (P0) pendentes
4. ✅ Equipe tem bandwidth para implementar e testar

---

## Como Ativar?

### Passo 1: Criar branch de feature

```bash
git switch main
git pull --ff-only
git switch -c feat/cli-global-installation
```

### Passo 2: Implementar conforme especificação

Seguir o checklist em: `docs/HU-CLI-Global-Checklist.md`

### Passo 3: Ativar validação no checklist (opcional)

Editar `42_pipeline_checklist.sh` e definir padrão:
```bash
REQUIRE_GLOBAL_CLI="${REQUIRE_GLOBAL_CLI:-1}"  # 1 = validar por padrão
```

**⚠️ Cuidado**: Isso tornará a validação do CLI global **obrigatória** no pipeline.

### Passo 4: Testar localmente

```bash
# Build e link
pnpm --filter @mini-ide/cli build
pnpm --filter @mini-ide/cli exec npm link

# Validar
which mini-ide
mini-ide --version
mini-ide analyze "Test" --maxLen 10

# Pipeline com validação obrigatória
REQUIRE_GLOBAL_CLI=1 bash ./42_pipeline_checklist.sh
```

### Passo 5: Commit e PR

```bash
git add -A
git commit -m "feat(cli): instalação global via npm/pnpm

- Adiciona campo 'bin' no package.json
- Implementa fallback para servidor offline
- Adiciona validação opcional no checklist
- Cria smoke test para CLI global

Closes #<número-da-issue>"

git push -u origin feat/cli-global-installation
```

### Passo 6: Abrir PR e aguardar review

---

## Checklist de Ativação

Antes de ativar, garantir que:

- [ ] ✅ Pipeline atual está 100% verde
- [ ] ✅ Hardening de checklist concluído (grep seguro, comparações robustas)
- [ ] ✅ Tipagem forte em test-utils.ts (sem `any`)
- [ ] ✅ Nenhuma HU P0 pendente
- [ ] ✅ Documentação atual está atualizada
- [ ] ✅ Equipe tem tempo para implementar e revisar
- [ ] ✅ Issue criada no GitHub para tracking

---

## Depois da Implementação

1. **Merge do PR**: após aprovação, fazer merge na `main`
2. **Tag de release**: criar tag `v1.0.13` ou próxima versão
3. **Atualizar CHANGELOG**: registrar nova funcionalidade
4. **Comunicar à equipe**: enviar comunicado sobre novo comando global
5. **Monitorar**: verificar se não houve regressões após merge

---

## Rollback (se necessário)

Se a implementação causar problemas após merge:

```bash
# 1. Reverter merge commit
git revert <commit-hash> -m 1

# 2. Desabilitar validação no checklist
export REQUIRE_GLOBAL_CLI=0

# 3. Desinstalar CLI global dos ambientes
npm uninstall -g @mini-ide/cli

# 4. Push do revert
git push origin main
```

---

## Contato

Em caso de dúvidas sobre a ativação desta HU:
- Consultar: `docs/HU-CLI-Global.md` (especificação completa)
- Consultar: `docs/HU-CLI-Global-Checklist.md` (checklist de implementação)
EOF_ACTIVATION

log_ok "Guia de ativação criado em $ACTIVATION_GUIDE"

# ==============================================================================
# RESUMO FINAL
# ==============================================================================
echo ""
log_ok "=========================================="
log_ok "HU-CLI-Global-100 PREPARADA ✅"
log_ok "=========================================="
log_ok "Arquivos criados:"
log_ok "  ✓ $HU_FILE"
log_ok "  ✓ $CHECKLIST_FILE"
log_ok "  ✓ $ACTIVATION_GUIDE"

if [ -f "$ISSUE_TEMPLATE_FILE" ]; then
  log_ok "  ✓ $ISSUE_TEMPLATE_FILE"
fi

echo ""
log_info "Status: 📋 PREPARADA (não implementada ainda)"
log_info "Prioridade: P1 (médio prazo)"
echo ""
log_info "Próximos passos:"
log_info "  1. Revisar especificação em: $HU_FILE"
log_info "  2. Criar issue no GitHub (se aplicável)"
log_info "  3. Aguardar momento adequado para implementação"
log_info "  4. Seguir guia de ativação: $ACTIVATION_GUIDE"
echo ""
log_info "Para ativar no futuro:"
log_info "  - Ler: $ACTIVATION_GUIDE"
log_info "  - Seguir checklist: $CHECKLIST_FILE"
log_info "  - Implementar conforme: $HU_FILE"
echo ""
log_warn "⚠️  NÃO ativar validação obrigatória (REQUIRE_GLOBAL_CLI=1) antes de implementar"
echo ""
