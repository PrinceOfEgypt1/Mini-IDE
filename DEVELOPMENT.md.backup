# Guia de Desenvolvimento – Mini-IDE

> **Versão do documento:** v1.0.17  
> **Última atualização:** (ajustar ao atualizar o repo)  
> **Escopo:** este arquivo consolida as regras de desenvolvimento, comandos principais e decisões técnicas **para humanos**.
>
> O comportamento dos agentes de IA (Analysis Agent, Claude, DeepSeek etc.) é definido no **Prompt-Mestre Mini-IDE** e no **backlog de HUs**.

Este guia segue três princípios:

1. **Mínimo necessário:** nada de documentação inflada.
2. **Vivo:** sempre que o estado real do projeto mudar, este arquivo deve ser atualizado no mesmo PR.
3. **Aderente ao código:** o que está escrito aqui precisa bater com o que o repositório realmente faz.

---

## 1. Visão geral do projeto

O **Mini-IDE** é um monorepo TypeScript que orquestra um fluxo de desenvolvimento “industrializado” apoiado por agentes de IA.

### 1.1 Monorepo e pacotes

O projeto usa **pnpm workspaces**. Os pacotes principais são:

- `@mini-ide/shared` – Tipos e utilitários compartilhados.
- `@mini-ide/analysis-agent` – Lógica do Analysis Agent (entrada única).
- `@mini-ide/server` – API HTTP (Fastify) para `/healthz` e `/analyze`.
- `@mini-ide/ui` – Interface de usuário (futuro painel Mini-IDE).
- `@mini-ide/cli` – CLI local para disparar análises e consumir o servidor.

Porta padrão do servidor: **`http://127.0.0.1:3200`**.

### 1.2 O que este documento **não** cobre

- Detalhes de negócio de projetos que o Mini-IDE venha a orquestrar.
- Padrão completo de Histórias de Usuário (HU) – isso está no **Backlog de HUs**.
- Fluxo detalhado das 8 personas de IA – isso está no **Prompt-Mestre Mini-IDE**.

Aqui o foco é: **como desenvolver com segurança dentro deste repositório**.

---

## 2. Ambiente de desenvolvimento

### 2.1 Pré-requisitos

- **Node.js 20+**
- **pnpm** (gerenciador de pacotes)
- **git**

Ferramentas recomendadas:

- VS Code (ou outro editor com suporte a TypeScript/ESLint/Prettier)
- `curl`/`wget` para chamadas HTTP de teste

### 2.2 Instalação

Na raiz do projeto:

```bash
pnpm install
```

Sempre rode os comandos a partir da raiz do monorepo, a menos que indicado o contrário.

---

## 3. Qualidade e código

### 3.1 TypeScript + NodeNext

Projeto configurado para ESM/NodeNext.

- Imports no código-fonte usam paths TypeScript.
- No transpilado, terminam em `.js`.

O objetivo é manter código fortemente tipado:

- Evitar `any` desnecessário.
- Evitar `// @ts-ignore` e `// @ts-expect-error` (usar apenas em último caso e com comentário claro).

### 3.2 ESLint + Prettier + EditorConfig

Estilo de código é padronizado por:

- **ESLint** (linting)
- **Prettier** (formatação)
- **.editorconfig** (indentação, fim de linha, charset etc.)

Comandos principais:

```bash
# Lint em todos os pacotes
pnpm lint

# Lint em um pacote específico
pnpm --filter @mini-ide/server lint
```

Commits que quebram o lint **não devem** ser enviados. Husky + lint-staged ajudam a impedir isso.

---

## 4. Testes automatizados

### 4.1 Framework de testes

Testes em TypeScript usam **Vitest**.

Cada pacote possui seus próprios testes, geralmente em `packages/<nome>/test`.

Comando geral:

```bash
# Todos os pacotes
pnpm test

# Pacote específico
pnpm --filter @mini-ide/server test
```

### 4.2 Convenções

Arquivos de teste: `*.spec.ts`.

Testes devem cobrir:

- Caminho feliz (happy path)
- Erros e validações
- Limites (boundary conditions)

Sempre que criar ou alterar código “de verdade”:

- Crie/atualize os testes correspondentes.
- Garanta que o conjunto completo de testes siga verde.

Quando scripts Bash forem suficientemente complexos, pode-se adotar Bats para testá-los, mas isso ainda não é obrigatório.

### 4.3 Cobertura de testes (Coverage)

O projeto Mini-IDE utiliza **thresholds mínimos de cobertura** configurados no Vitest para garantir qualidade do código. Esses thresholds são **realistas, baseados na cobertura atual**, e serão elevados gradualmente em iterações futuras.

#### 4.3.1 Thresholds configurados (baseline v1.0.17)

Os thresholds são definidos por pacote nos respectivos `vitest.config.ts`.

- **@mini-ide/shared**
  - `lines / functions / statements / branches`: **80%**

- **@mini-ide/ui**
  - `lines / functions / statements / branches`: **80%**

- **@mini-ide/server** (código crítico)
  - `lines / functions / statements`: **80%**
  - `branches`: **75%**

- **@mini-ide/cli**
  - `lines / functions / statements / branches`: **50%**

- **@mini-ide/analysis-agent**
  - `lines / functions / statements / branches`: **10%**

Esses valores são o **baseline atual**. O plano é **aumentar progressivamente** até atingir patamares mais altos (por exemplo, server ≥ 90%, cli/analysis-agent ≥ 80%) por meio de HUs específicas de melhoria de cobertura.

#### 4.3.2 Comandos para executar testes com cobertura

```bash
# Executar testes com cobertura em todos os pacotes
pnpm test -- --coverage

# Executar cobertura em um pacote específico
pnpm --filter @mini-ide/server test -- --coverage

# Gerar relatório HTML e abrir no browser
bash scripts/coverage-report.sh
```

#### 4.3.3 Comportamento dos thresholds

- Se a cobertura ficar **abaixo do threshold configurado**, o comando `pnpm test -- --coverage` **falha**.
- Isso impede que commits reduzam a qualidade sem ação consciente.

Quando a cobertura estiver abaixo do valor desejado, o fluxo recomendado é:

1. **Passo 1 (preferencial):** adicionar/ajustar testes até atingir o threshold.
2. **Passo 2 (exceção):** ajustar temporariamente o threshold no `vitest.config.ts` do pacote, registrando a justificativa na HU correspondente.

#### 4.3.4 Localização dos relatórios HTML de coverage

Após executar testes com coverage, os relatórios HTML são gerados em:

- `packages/shared/coverage/index.html`
- `packages/server/coverage/index.html`
- `packages/analysis-agent/coverage/index.html`
- `packages/cli/coverage/index.html`
- `packages/ui/coverage/index.html`

#### 4.3.5 Status atual da cobertura (v1.0.17, pós HU-Quality-Coverage-Thresholds)

Com base na última execução completa de coverage em v1.0.17:

- ✅ **shared:** 100% (acima do threshold de 80%)
- ✅ **ui:** 100% (acima do threshold de 80%)
- ✅ **server:** ~82.27% lines / ~75.6% branches (threshold 80% / 75%)
- ✅ **cli:** ~55% (acima do threshold de 50%)
- ✅ **analysis-agent:** ~12.5% (acima do threshold de 10%)

A partir deste baseline, novas HUs irão **elevar gradualmente** os thresholds por pacote até os valores-alvo definidos no backlog de qualidade.

---

## 5. Execução local (server + CLI)

### 5.1 Build do servidor

```bash
pnpm --filter @mini-ide/server build
```

### 5.2 Subir o servidor (porta 3200)

```bash
PORT=3200 node packages/server/dist/index.js
```

Health check disponível em:  
`http://127.0.0.1:3200/healthz`

Endpoint principal:  
`POST http://127.0.0.1:3200/analyze`

### 5.3 Build da CLI

```bash
pnpm --filter @mini-ide/cli build
```

### 5.4 Rodar a CLI apontando para o servidor local

Exemplo:

```bash
node packages/cli/dist/index.js analyze "Olá Mini-IDE!" --maxLen 10   --url http://127.0.0.1:3200
```

O resultado normalmente é persistido em `bundles/<versão>/...` (dependendo da configuração atual).

---

### 5.5 Contrato oficial do endpoint POST /analyze

**Versão do contrato:** 1.0.0  
**Última atualização:** 2024-11-16  
**HU:** HU-Server-Analyze-Shape-Contract

O endpoint `POST /analyze` retorna um JSON estruturado que segue o contrato oficial definido em `@mini-ide/shared/types/analyze-response.ts`.

#### Campos obrigatórios

Todos os campos abaixo DEVEM estar presentes em toda resposta 2xx do endpoint:

| Campo          | Tipo     | Descrição                                                                                   |
| -------------- | -------- | ------------------------------------------------------------------------------------------- |
| `summary`      | `string` | Resumo/saída principal da análise. Comprimento respeita o parâmetro `maxLen` da requisição. |
| `inputLength`  | `number` | Número de caracteres do texto de entrada (≥ 0).                                             |
| `outputLength` | `number` | Número de caracteres do resumo gerado (≥ 0).                                                |
| `requestId`    | `string` | Identificador único da requisição (UUID v4). Usado para correlação de logs.                 |
| `timestamp`    | `string` | Timestamp ISO 8601 da geração da resposta (ex: `2024-11-16T14:30:00.000Z`).                 |

#### Campos opcionais

Estes campos podem ou não estar presentes:

| Campo             | Tipo     | Descrição                                                    |
| ----------------- | -------- | ------------------------------------------------------------ |
| `budgetUsed`      | `number` | Quantidade de orçamento consumida nesta requisição (≥ 0).    |
| `budgetRemaining` | `number` | Quantidade de orçamento restante após esta requisição (≥ 0). |

#### Exemplo de resposta válida

```json
{
  "summary": "Este é um resumo de teste do sistema Mini-IDE",
  "inputLength": 150,
  "outputLength": 47,
  "requestId": "a1b2c3d4-e5f6-4789-a012-3456789abcde",
  "timestamp": "2024-11-16T14:30:00.000Z",
  "budgetUsed": 0.05,
  "budgetRemaining": 4.95
}
```

#### Validação programática

Para validar se um objeto JavaScript corresponde ao contrato:

```typescript
import { isAnalyzeResponse } from '@mini-ide/shared';

const response = await fetch('http://127.0.0.1:3200/analyze', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text: 'Teste', maxLen: 100 }),
}).then((r) => r.json());

if (isAnalyzeResponse(response)) {
  console.log('Resposta válida:', response.summary);
} else {
  console.error('Resposta inválida - não respeita o contrato');
}
```

#### Resiliência e versionamento

O contrato é **resiliente a campos extras**: respostas que contêm campos adicionais não documentados (ex: `modelUsed`, `processingTime`) continuam válidas. Isso permite evolução futura do endpoint sem quebrar consumidores existentes.

Ao adicionar novos campos obrigatórios no futuro, deve-se incrementar a versão do contrato e manter compatibilidade retroativa por pelo menos 3 releases.

## 6. Pipeline local oficial

Antes de abrir PR (ou de considerar uma feature “pronta”), o fluxo recomendado é:

```bash
pnpm lint
pnpm test
pnpm typecheck
pnpm build
```

Opcionalmente, use o script de checklist (se disponível na raiz):

```bash
# Pipeline completo
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
```

Esse script costuma:

- Rodar lint em todos os pacotes relevantes.
- Executar testes.
- Executar typecheck.
- Fazer build dos pacotes.
- (Opcional) Rodar smoke tests.

A flag `REQUIRE_GLOBAL_CLI=0` indica que o uso de uma CLI global é opcional; a validação deve funcionar com a CLI local do monorepo.

---

## 7. Smoke tests

O repositório pode conter um script de smoke (por exemplo `scripts/smoke.sh`) com o seguinte objetivo:

- Subir o server em `:3200`.
- Testar `/healthz`.
- Executar uma chamada CLI end-to-end.
- Finalizar o servidor, reportando `[ok] smoke passou` ou falha.

Sempre que alterar algo em `@mini-ide/server` ou `@mini-ide/cli`, é recomendável:

```bash
bash ./scripts/smoke.sh
```

(ajustar o nome do script conforme o repo real).

---

## 8. Documentação

### 8.1 TypeDoc

A API em TypeScript é documentada com **TypeDoc**.

Saída esperada em `docs/api/`.

Para gerar a documentação:

```bash
pnpm docs:api   # ou o script equivalente definido no package.json
```

### 8.2 Controle de commits em `docs/api/`

Por padrão, commits em `docs/api/*` devem ser evitados.

Quando for necessário atualizar a documentação gerada, use:

```bash
GIT_ALLOW_DOCS=1 git commit ...
```

O objetivo é manter o repositório limpo e evitar commits massivos apenas de HTML gerado.

### 8.3 Arquivos que devem permanecer vivos

Documentos que precisam acompanhar a evolução do projeto:

- `README.md` – visão geral + Getting Started.
- `CHANGELOG.md` – histórico de releases.
- `docs/HISTORIAS-USUARIO.md` – backlog oficial de HUs.
- `DEVELOPMENT.md` – este documento.
- `packages/server/openapi.yaml` – contrato da API REST.
- `docs/adr/*.md` – decisões arquiteturais relevantes (quando existirem).

Sempre que o comportamento ou a API mudar de forma relevante:

1. Atualize o código.
2. Atualize os testes.
3. Atualize também a documentação relacionada no mesmo PR.

---

## 9. Git, branches e commits

### 9.1 Branches

Branch principal: `main`.

Recomenda-se criar branches de feature/bugfix:

- `feat/<nome-descritivo>`
- `fix/<nome-descritivo>`
- `chore/<nome-descritivo>`

### 9.2 Padrão de mensagens (Conventional Commits)

Use mensagens no padrão **Conventional Commits**, por exemplo:

- `feat(server): implementar tratamento 5xx em /analyze`
- `fix(cli): corrigir parse de argumentos`
- `chore(checklist): ajustar script 42_pipeline_checklist.sh`
- `docs(readme): documentar porta padrão 3200`
- `test(server): adicionar testes para budget`

### 9.3 Husky e lint-staged

Husky é usado para garantir qualidade pré-commit.  
`lint-staged` roda lint e/ou outras verificações somente em arquivos alterados.

Se o pre-commit falhar:

1. Leia a mensagem de erro.
2. Corrija o problema no código/testes.
3. Refaça `git add` e `git commit`.

Não force o commit “por fora” dos hooks – isso vai contra a cultura de qualidade do Mini-IDE.

---

## 10. Scripts Bash e automação

Este projeto depende bastante de scripts Bash para:

- Rodar pipelines locais.
- Padronizar fluxos de build/test.
- Facilitar operações repetitivas.

### 10.1 Quando criar um script Bash

Crie (ou atualize) um `.sh` quando:

- Houver uma sequência de comandos de terminal que:
  - Precise ser repetida com frequência, ou
  - Precise ser reproduzida de forma idêntica em diferentes máquinas, ou
  - For parte de um fluxo oficial (lint/test/typecheck/build, geração de docs, smoke, etc.).

Não há obrigatoriedade de “transformar todo código em script Bash”.  
O objetivo é automatizar fluxos operacionais complexos, não substituir código TypeScript.

### 10.2 Padrão de scripts Bash

Sempre que criar um novo script:

- Use shebang e flags de segurança:

  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```

- Inclua um cabeçalho no início com:
  - Descrição do propósito do script.
  - Modo de uso (exemplos de execução).
  - Pré-requisitos.
  - Variáveis de ambiente relevantes.
  - Efeitos colaterais (arquivos gerados/alterados).

- Padronize logs de saída, por exemplo:

  ```bash
  echo "[info] Iniciando build do server..."
  echo "[ok] Build do server concluída."
  echo "[warn] CLI global não encontrada, usando CLI local."
  echo "[erro] Typecheck falhou, abortando."
  ```

- Salve os scripts em:
  - `scripts/` (scripts gerais)
  - `packages/<nome>/scripts/` (scripts específicos de um pacote)

---

## 11. O que ainda não é exigido (mas está no backlog)

Alguns itens não são obrigatórios neste momento, mas já existem como HUs no backlog (especialmente no épico **E-Hardening**):

- Testes E2E completos do fluxo Mini-IDE.
- **Aprimoramento progressivo** dos thresholds mínimos de cobertura já implementados (HU-Quality-Coverage-Thresholds, v1.0.17), elevando-os até os valores finais desejados por pacote.
- Abstração de provider LLM real (OpenAI, DeepSeek etc.), mantendo o mock para testes.
- Métricas de observabilidade (Prometheus, dashboards etc.).

Até essas HUs serem implementadas:

- Já existe **gate de coverage** com baseline realista; o aumento dos thresholds para níveis mais agressivos ainda não é exigido.
- Não há E2E obrigatório na pipeline de CI.
- O LLM pode continuar simulado no server.
- Logs estruturados já existem, mas sem métricas formais.

Conforme essas HUs forem sendo entregues:

- Este `DEVELOPMENT.md` deve ser atualizado para refletir:
  - Novos comandos necessários.
  - Novas regras de qualidade (ex.: coverage mínimo por pacote em novos patamares).
  - Novos requisitos (ex.: CI obrigatória em PR, execução de E2E na pipeline).

---

## 12. Integração com o Prompt-Mestre e Backlog de HUs

Os agentes de IA (Claude, DeepSeek, Analysis Agent etc.) seguem regras adicionais descritas no:

- **Prompt-Mestre Mini-IDE** (documento separado).
- **Backlog de Histórias de Usuário** (`docs/HISTORIAS-USUARIO.md` ou equivalente).

Este `DEVELOPMENT.md` deve ser entendido como:

- Manual de engenharia para qualquer desenvolvedor humano que queira:
  - Clonar o repositório.
  - Rodar o projeto localmente.
  - Implementar HUs com segurança.
  - Respeitar a cultura de qualidade do Mini-IDE.

Sempre que houver dúvida entre o que está aqui e o que está no Prompt-Mestre:

- Para comportamento de IA → o **Prompt-Mestre** é a fonte oficial.
- Para estado técnico do repositório → este `DEVELOPMENT.md` deve ser mantido em linha com o código.

  5.6 UI – Playground /analyze e status do servidor

A UI da Mini-IDE já está conectada ao Mini-IDE Server, com os seguintes recursos:

- Configuração de servidor
  - A URL base do backend é lida da variável de ambiente `VITE_MINI_IDE_SERVER_URL`.
  - O módulo `@mini-ide/ui/src/config/server.ts` centraliza `getBaseUrl()`, `getHealthzUrl()` e `getAnalyzeUrl()`.

- Indicador de status do servidor
  - O componente `ServerStatus` consulta `GET /healthz`.
  - Estados visuais:
    - 🟢 Servidor online (200 em /healthz)
    - 🔴 Servidor indisponível (erro de rede ou status não-2xx)
    - ⏳ Verificando (requisição em andamento)
  - Integrado ao header da aplicação, seguindo o padrão visual do wireframe da Mini-IDE.

- Playground do endpoint POST /analyze
  - A aba **Analyze** do workspace contém o componente `AnalyzePlayground`.
  - Permite enviar:
    - `text`: texto livre para análise (textarea)
    - `maxLen`: tamanho máximo do resumo (valor numérico, default 100)
  - A chamada é feita para `POST /analyze` usando a baseURL configurada.
  - A resposta é exibida de forma estruturada (summary, inputLength, outputLength, requestId, timestamp) ou como mensagem de erro amigável em caso de falha.

Esses recursos formam o primeiro MVP de UI conectada ao backend, permitindo testar o contrato oficial do /analyze diretamente pelo navegador.
