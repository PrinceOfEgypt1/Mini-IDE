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
