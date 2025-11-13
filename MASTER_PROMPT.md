# Mini-IDE - Prompt-Mestre

## Visão Geral

**Mini-IDE** é um monorepo TypeScript modular que implementa um sistema de análise de texto com arquitetura cliente-servidor. O projeto demonstra práticas profissionais de engenharia de software, incluindo pipeline de CI/CD rigorosa, testes automatizados abrangentes e ferramentas de qualidade de código.

### Propósito e Filosofia

- **Simplicidade e modularidade**: Arquitetura limpa com separação clara de responsabilidades
- **Qualidade garantida**: Pipeline verde é requisito obrigatório para releases
- **Desenvolvimento sustentável**: Convenções claras, documentação inline e ferramentas automatizadas
- **Tolerância a falhas**: Validações rigorosas no servidor, comportamento defensivo no CLI

---

## Arquitetura do Sistema

### Estrutura de Pacotes (Monorepo)

O projeto utiliza **pnpm workspaces** para gestão de monorepo com 5 pacotes principais:

```
packages/
├── analysis-agent/    # Núcleo: APIs puras de análise (compactPrompt)
├── server/           # Backend HTTP (Fastify) com endpoints /healthz e /analyze
├── cli/              # Interface de linha de comando para interação local
├── shared/           # Tipos e utilitários compartilhados entre pacotes
└── ui/               # [Stub] Interface do usuário (desenvolvimento futuro)
```

### Dependências entre Pacotes

```
server → analysis-agent → shared
cli → analysis-agent → shared
ui → shared
```

### Stack Tecnológica

| Categoria | Tecnologia | Versão |
|-----------|-----------|--------|
| Runtime | Node.js | ≥20 |
| Package Manager | pnpm | 9.12.2 |
| Linguagem | TypeScript | ^5.9.3 |
| Servidor HTTP | Fastify | ^5.6.1 |
| Testes | Vitest | ^4.0.7 |
| Linting | ESLint | ^9.39.1 |
| Formatação | Prettier | ^3.6.2 |
| Git Hooks | Husky | 9.1.7 |
| Documentação | TypeDoc | ^0.28.14 |

---

## Componentes Principais

### 1. Analysis Agent (`@mini-ide/analysis-agent`)

**Responsabilidade**: Lógica pura de processamento de texto.

**Função principal: `compactPrompt`**

```typescript
export function compactPrompt(input: string, opts: CompactOptions = {}): string
```

**Comportamento**:
- Normaliza `\r\n` → `\n`
- Remove espaços duplicados dentro de linhas
- Remove linhas vazias consecutivas (max 2 linebreaks)
- Aplica trim geral
- Opcionalmente limita comprimento com sufixo " …"

**Princípios de design**:
- Zero dependências externas (exceto `@mini-ide/shared`)
- Funções puras (sem side effects)
- Testes unitários completos

### 2. Server (`@mini-ide/server`)

**Responsabilidade**: Backend HTTP com orquestração de análises.

**Endpoints**:

#### `GET /healthz`
```json
{
  "status": "ok",
  "timestamp": "2025-11-13T18:00:00.000Z"
}
```

#### `POST /analyze`

**Request**:
```json
{
  "text": "string (obrigatório, não vazio)",
  "maxLen": "number (opcional, padrão: 100, limite: 1000)"
}
```

**Response (200)**:
```json
{
  "summary": "string (texto processado)",
  "tokensUsed": "number (contagem de palavras)",
  "runId": "string (formato: run-{UUID})",
  "timestamp": "string (ISO 8601)"
}
```

**Validações (400)**:
- `text` ausente/null → `"Missing required field: text"`
- `text` não-string → `"Field 'text' must be a string"`
- `text` vazio (após trim) → `"Field 'text' cannot be empty"`
- `maxLen` não-number → `"Field 'maxLen' must be a number"`
- `maxLen ≤ 0` → `"Field 'maxLen' must be greater than 0"`
- `maxLen > 1000` → `"Field 'maxLen' exceeds maximum limit"`

**Logging**: JSON estruturado (stdout)
```json
{
  "event": "analyze.200",
  "runId": "run-abc123...",
  "ts": "2025-11-13T18:00:00.000Z",
  "textLen": 500,
  "maxLen": 100,
  "summaryLen": 100,
  "tokensUsed": 42
}
```

**Configuração**:
- Porta padrão: **3200** (`PORT` env var)
- Host: `127.0.0.1` (localhost apenas)
- Logger: desativado no Fastify (logs manuais JSON)

### 3. CLI (`@mini-ide/cli`)

**Responsabilidade**: Interface de linha de comando para análise local.

**Uso**:
```bash
node packages/cli/dist/index.js analyze "Texto" --maxLen 50 --url http://127.0.0.1:3200
```

**Parâmetros**:
- `<text>` (posicional): Texto a analisar
- `--maxLen <number>` (opcional, padrão: 100)
- `--url <string>` (opcional, padrão: `http://127.0.0.1:3200`)

**Comportamento tolerante**:
- Falhas de rede → retorna payload local (summary truncado, campos undefined)
- Resposta não-JSON → fallback para output estável
- Exit code sempre 0 (não bloqueia pipelines)

**Binário global** (opcional):
```bash
pnpm --filter @mini-ide/cli build
# Uso: mini-ide analyze "texto"
```

### 4. Shared (`@mini-ide/shared`)

**Responsabilidade**: Tipos e utilitários compartilhados.

**Conteúdo atual**:
```typescript
export function hello(name = 'world'): string
```

**Propósito futuro**: Interfaces, tipos de domínio, helpers comuns.

### 5. UI (`@mini-ide/ui`)

**Status**: Stub (desenvolvimento futuro)
**Propósito planejado**: Interface web para análise interativa

---

## Pipeline de Desenvolvimento

### Scripts NPM (raiz)

| Script | Comando | Descrição |
|--------|---------|-----------|
| `build` | `pnpm -r run build` | Compila todos os pacotes (TypeScript → dist/) |
| `typecheck` | `pnpm -r run typecheck` | Typecheck sem emissão de arquivos |
| `lint` | `pnpm -r run lint` | ESLint em todos os pacotes |
| `lint:fix` | `pnpm -r run lint:fix` | ESLint com auto-fix |
| `test` | `pnpm -r run test` | Vitest run em todos os pacotes |
| `test:watch` | `pnpm -r run test:watch` | Vitest em modo watch |
| `format` | `prettier -w .` | Formatar todos os arquivos |
| `format:check` | `prettier -c .` | Verificar formatação |
| `ci:all` | Sequencial | Build + typecheck + lint + test |
| `dev:all` | `pnpm -F @mini-ide/server run dev` | Sobe servidor em modo dev |
| `prepare` | `husky` | Instala git hooks |
| `docs` | `typedoc` | Gera documentação API |
| `docs:generate` | `bash scripts/generate_docs_stub.sh` | Gera docs stub |

### Scripts Principais (Shell)

#### `17_dev_all.sh` - Ambiente de Desenvolvimento
```bash
bash 17_dev_all.sh
```
- Configura scripts de dev no server e raiz
- Adiciona `dev:watch` com `tsx watch`

#### `42_pipeline_checklist.sh` - Pipeline Completa
```bash
bash 42_pipeline_checklist.sh
# Opcionalmente: REQUIRE_GLOBAL_CLI=0 bash 42_pipeline_checklist.sh
```

**Etapas**:
1. `pnpm install --frozen-lockfile`
2. `pnpm -r run build`
3. `pnpm -r exec tsc --noEmit` (typecheck)
4. `pnpm -r run lint`
5. `pnpm -r run test`
6. `pnpm run docs:generate` (se disponível)
7. Sobe servidor temporário (porta livre a partir de 3200)
8. Valida `GET /healthz` (status "ok", timestamp válido)
9. Valida `POST /analyze` (shape + normalização)
10. Valida CLI local (reusando servidor)

**Resultado**: Pipeline verde ✅ ou falha com exit code != 0

#### `46_safe_tag_and_push.sh` - Release Segura
```bash
TAG=v1.0.17 BRANCH=main bash 46_safe_tag_and_push.sh --apply
```

**Proteções**:
- Verifica se é repositório Git válido
- Confirma remote `origin` configurado
- Executa pipeline local (build/typecheck/lint/test)
- Dry-run por padrão (mostra plano sem executar)
- Modo `--apply`: cria commit, tag e push

**Fluxo**:
1. Validações Git (repo, origin, branch)
2. Pipeline local silenciosa
3. Plano de ações
4. Commit: `"chore: pipeline green (build/typecheck/lint/test/docs)"`
5. Tag anotada: `Mini-IDE {TAG}`
6. Push branch + tag

---

## Convenções e Padrões

### TypeScript

**tsconfig.base.json**:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "useUnknownInCatchVariables": true,
    // ... paths, declaration, sourceMap
  }
}
```

**Princípios**:
- Modo strict ativado (sem exceções)
- Acesso a índices sempre checado
- Catch variables como `unknown`
- ESM puro (`.js` extensions em imports relativos)

### Linting e Formatação

**ESLint** (`eslint.config.js`):
- `@eslint/js` recommended
- `typescript-eslint` recommendedTypeChecked
- Rules customizadas:
  - `@typescript-eslint/no-unused-vars`: warn (ignore `^_`)
  - `@typescript-eslint/consistent-type-imports`: warn (prefer type imports)

**Prettier** (`.prettierrc.json`):
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100
}
```

**Lint-staged** (`lint-staged.config.mjs`):
- `*.{ts,tsx}`: ESLint (max-warnings=0) + Prettier
- `*.{json,md,yml,yaml}`: Prettier

### Git Hooks (Husky)

**Pre-commit** (`.husky/pre-commit`):
1. Executa `lint-staged` (formata e linta arquivos staged)
2. Typecheck filtrado por workspace modificado
3. Fallback para typecheck completo se filtro falhar

**Filosofia**:
- Commits sempre formatados e validados
- Typecheck evita quebra de tipos antes do push
- Falha rápida (exit 1 bloqueia commit)

### Testes

**Framework**: Vitest com coverage via `@vitest/coverage-v8`

**Estrutura**:
```
packages/{package}/
├── src/
│   └── *.ts
└── test/
    └── *.spec.ts
```

**Padrões**:
- AAA: Arrange, Act, Assert
- Describe/It semânticos
- Helpers em `test-utils.ts` (ex: `build`, `inject`, `shutdown`)
- Coverage não obrigatório, mas encorajado

**Exemplo** (`packages/server/test/analyze.spec.ts`):
```typescript
describe('POST /analyze - Happy Path (200)', () => {
  let server: FastifyInstance;

  beforeAll(async () => { server = await build(); });
  afterAll(async () => { await shutdown(server); });

  it('AC1: should return 200 with valid text and maxLen', async () => {
    const response = await inject(server, {
      method: 'POST',
      url: '/analyze',
      payload: { text: 'Hello, World!', maxLen: 10 },
    });

    expect(status(response)).toBe(200);
    // ... assertions
  });
});
```

### Logging

**Formato**: JSON estruturado (stdout)

**Campos padrão**:
- `event`: Tipo de evento (`server.started`, `analyze.200`, etc.)
- `ts` ou `timestamp`: ISO 8601
- Campos contextuais (runId, textLen, etc.)

**Exemplo**:
```json
{"event":"server.started","port":3200,"ts":"2025-11-13T18:00:00.000Z"}
```

**Princípios**:
- Parseable por ferramentas (jq, Splunk, etc.)
- Sem logs verbosos em produção (LOG_LEVEL não implementado ainda)
- Erros sempre logados antes de exit

### Versionamento e Releases

**Estratégia**:
- Tags semânticas: `v{MAJOR}.{MINOR}.{PATCH}`
- Changelog manual (`CHANGELOG.md`)
- Discussões no GitHub para cada release

**Releases recentes**:
- [v1.0.16](https://github.com/PrinceOfEgypt1/Mini-IDE/releases/tag/v1.0.16) - [Discussão #12](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/12)
- [v1.0.15](https://github.com/PrinceOfEgypt1/Mini-IDE/releases/tag/v1.0.15) - [Discussão #8](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/8)
- [v1.0.14](https://github.com/PrinceOfEgypt1/Mini-IDE/releases/tag/v1.0.14) - [Discussão #5](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions/5)

**Critérios para release**:
1. Pipeline verde (42_pipeline_checklist.sh)
2. Testes 100% passando
3. Endpoints validados (/healthz, /analyze)
4. CLI local funcionando
5. Documentação atualizada

---

## Fluxos de Trabalho

### Desenvolvimento Local

1. **Clone e setup**:
```bash
git clone <repo-url> Mini-IDE
cd Mini-IDE
pnpm install
```

2. **Build inicial**:
```bash
pnpm build
```

3. **Desenvolvimento**:
```bash
# Terminal 1: Servidor em watch mode
pnpm dev:all

# Terminal 2: Testes em watch
pnpm test:watch

# Terminal 3: Typecheck contínuo
pnpm typecheck
```

4. **Validação antes de commit**:
```bash
pnpm ci:all
# Ou: bash 42_pipeline_checklist.sh
```

### Adicionando Novo Pacote

1. Criar diretório em `packages/{nome}`
2. Adicionar `package.json` com:
   - `name`: `@mini-ide/{nome}`
   - `private`: true
   - Scripts padrão: build, typecheck, lint, test
3. Criar `tsconfig.json` estendendo `../../tsconfig.base.json`
4. Adicionar `src/index.ts` com exports públicos
5. Adicionar `test/` com specs Vitest
6. Executar `pnpm install` na raiz

### Criando Release

1. **Desenvolver feature** em branch
2. **Validar pipeline**:
```bash
bash 42_pipeline_checklist.sh
```

3. **Merge para main**
4. **Tag e push**:
```bash
TAG=v1.0.17 BRANCH=main bash 46_safe_tag_and_push.sh --apply
```

5. **Criar Release no GitHub**:
   - Copiar conteúdo do CHANGELOG.md
   - Adicionar binários se aplicável
   - Criar Discussion associada

### Debugging

**Servidor**:
```bash
# Porta customizada
PORT=3300 pnpm dev:all

# Logs estruturados (já habilitado)
node packages/server/dist/index.js | jq .
```

**CLI**:
```bash
# Testar contra servidor local
node packages/cli/dist/index.js analyze "test" --url http://127.0.0.1:3200

# Debug parsing
node -e "
const { parseAnalyze } = require('./packages/cli/dist/index.js');
console.log(parseAnalyze(['texto', '--maxLen', '50']));
"
```

**Testes**:
```bash
# Rodar suite específica
pnpm --filter @mini-ide/server test

# Coverage
pnpm test -- --coverage
```

---

## Estrutura de Arquivos

```
Mini-IDE/
├── .github/
│   ├── workflows/placeholder.yml     # CI/CD (placeholder)
│   └── ISSUE_TEMPLATE/
├── .husky/
│   └── pre-commit                    # Lint-staged + typecheck
├── packages/
│   ├── analysis-agent/               # Análise pura
│   ├── server/                       # Backend Fastify
│   ├── cli/                          # CLI local
│   ├── shared/                       # Utilitários
│   └── ui/                           # UI (stub)
├── scripts/
│   ├── discussions_canonicalize.sh   # Helpers para Discussions
│   ├── verify_release.sh             # Validação pós-release
│   └── verify_release_v1_0_16.sh     # Validação v1.0.16
├── test/                             # Testes de integração (futuro)
├── 17_dev_all.sh                     # Setup dev environment
├── 42_pipeline_checklist.sh          # Pipeline completa
├── 46_safe_tag_and_push.sh           # Release segura
├── 62_relax_global_cli_check.sh      # Flag REQUIRE_GLOBAL_CLI
├── CHANGELOG.md                      # Histórico de releases
├── README.md                         # Documentação principal
├── MASTER_PROMPT.md                  # Este arquivo
├── package.json                      # Root package
├── pnpm-workspace.yaml               # Workspace config
├── tsconfig.base.json                # Base TS config
├── eslint.config.js                  # ESLint flat config
├── lint-staged.config.mjs            # Lint-staged config
├── .prettierrc.json                  # Prettier config
├── .editorconfig                     # EditorConfig
├── .nvmrc                            # Node version (20)
└── typedoc.json                      # TypeDoc config
```

---

## Troubleshooting

### Porta 3200 em uso

**Sintoma**: Servidor falha ao iniciar
**Solução**:
```bash
# Detectar processo
lsof -i :3200
# Ou
ss -ltn | grep 3200

# Usar porta alternativa
PORT=3201 pnpm dev:all
```

**Pipeline automaticamente escolhe porta livre** (3200-3250)

### Typecheck falha no pre-commit

**Sintoma**: Commit bloqueado por erros de tipo
**Solução**:
1. Executar `pnpm typecheck` manualmente
2. Corrigir erros reportados
3. Verificar tsconfig.json de cada pacote estende base
4. Garantir que `noEmit: true` está no typecheck script

### Testes falhando

**Sintoma**: `pnpm test` retorna exit code != 0
**Solução**:
1. Executar `pnpm test:watch` para debugging interativo
2. Verificar se server build está atualizado (`pnpm build`)
3. Confirmar que porta 3200 está livre (testes sobem servidor)
4. Revisar logs estruturados JSON nos testes

### CLI não funciona

**Sintoma**: `mini-ide` command not found
**Solução**:
```bash
# Build CLI
pnpm --filter @mini-ide/cli build

# Usar localmente
node packages/cli/dist/index.js analyze "test"

# Ou instalar globalmente (opcional)
pnpm install -g .
```

### Prettier conflita com ESLint

**Sintoma**: Lint-staged falha com conflitos de formatação
**Solução**:
1. Garantir que `.prettierrc.json` está na raiz
2. Executar `pnpm format` antes de commit
3. Verificar `lint-staged.config.mjs` executa Prettier APÓS ESLint
4. Nunca rodar `eslint --fix` e `prettier --write` em ordens diferentes

---

## Diretrizes de Contribuição

### Code Style

1. **TypeScript strict mode**: Sem `any`, sempre tipar explicitamente
2. **ESM puro**: Usar `import/export`, nunca `require`
3. **Funções puras**: Preferir funções sem side effects
4. **Nomes descritivos**: `processAnalyze` > `process`
5. **Error handling**: Sempre validar inputs no servidor, tolerância no CLI

### Testes

1. **Coverage**: Mínimo 80% em código crítico
2. **Edge cases**: Testar boundaries (0, 1, max)
3. **Erro paths**: Validar todos os 400/500 possíveis
4. **Naming**: `it('should ...')` ou `it('AC{N}: ...')`

### Commits

1. **Formato**: `{type}: {description}`
   - `feat`: Nova funcionalidade
   - `fix`: Correção de bug
   - `chore`: Manutenção (build, deps)
   - `docs`: Documentação
   - `refactor`: Refatoração sem mudança de comportamento
   - `test`: Adição/modificação de testes

2. **Scope**: Opcional `{type}({scope}): {description}`
   - Exemplo: `feat(server): add rate limiting`

3. **Body**: Opcional para contexto adicional

### Pull Requests

1. **Branch naming**: `feat/{feature-name}`, `fix/{bug-name}`
2. **PR title**: Igual ao commit principal
3. **Descrição**: Contexto, motivação, breaking changes
4. **Checklist**:
   - [ ] Pipeline verde (`42_pipeline_checklist.sh`)
   - [ ] Testes adicionados/atualizados
   - [ ] Documentação atualizada
   - [ ] CHANGELOG.md atualizado (se aplicável)

---

## Roadmap

### v1.1.x (Curto Prazo)

- [ ] Implementar UI básica (React + Vite)
- [ ] Adicionar rate limiting no servidor
- [ ] CI/CD no GitHub Actions
- [ ] Documentação TypeDoc completa
- [ ] CLI com opção `--output json|text`

### v1.2.x (Médio Prazo)

- [ ] Suporte a múltiplos formatos de análise
- [ ] WebSocket para análise real-time
- [ ] Plugin system para análises customizadas
- [ ] Metrics e observabilidade (Prometheus)
- [ ] Docker + docker-compose

### v2.0.x (Longo Prazo)

- [ ] Multi-tenancy e autenticação
- [ ] Persistência de histórico de análises
- [ ] API GraphQL
- [ ] Editor integrado (Monaco Editor)
- [ ] Deploy em cloud (AWS/GCP/Azure)

---

## Referências

### Documentação Externa

- [Fastify](https://fastify.dev/)
- [Vitest](https://vitest.dev/)
- [pnpm Workspaces](https://pnpm.io/workspaces)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [ESLint Flat Config](https://eslint.org/docs/latest/use/configure/configuration-files-new)

### Repositório

- **GitHub**: [PrinceOfEgypt1/Mini-IDE](https://github.com/PrinceOfEgypt1/Mini-IDE)
- **Discussões**: [Mini-IDE Discussions](https://github.com/PrinceOfEgypt1/Mini-IDE/discussions)
- **Issues**: [Mini-IDE Issues](https://github.com/PrinceOfEgypt1/Mini-IDE/issues)

### Licença

MIT License (conforme package.json, se aplicável)

---

## Apêndice: Comandos Rápidos

```bash
# Setup inicial
pnpm install && pnpm build

# Desenvolvimento
pnpm dev:all                          # Servidor em watch
pnpm test:watch                       # Testes em watch

# Validação
bash 42_pipeline_checklist.sh         # Pipeline completa
pnpm ci:all                           # Build + typecheck + lint + test

# Release
TAG=v1.0.17 bash 46_safe_tag_and_push.sh --apply

# Limpeza
rm -rf packages/*/dist node_modules   # Rebuild total
pnpm install && pnpm build

# Debugging
PORT=3200 node packages/server/dist/index.js | jq .
node packages/cli/dist/index.js analyze "test" --url http://127.0.0.1:3200
```

---

**Última atualização**: 2025-11-13
**Versão do projeto**: v1.0.16
**Autor do Prompt-Mestre**: Claude (Anthropic) via Mini-IDE Development Workflow
