# Mini-IDE — DEVELOPMENT.md (v1.0.18 – Lote 3 UI Explore Workspace)

> **Estado de referência deste documento**  
> Versão lógica: v1.0.18 (Lote 3 de UI – Explore Workspace)  
> Pipeline: `42_pipeline_checklist.sh` passando (lint, test, typecheck, build, smoke /healthz e /analyze).

---

## 1. Visão geral do projeto

O **Mini-IDE** é um monorepo TypeScript baseado em **pnpm workspaces**, cujo objetivo é fornecer um ambiente de análise e orquestração de código, apoiado por múltiplos agentes de IA (Analysis Agent, etc.) e por um usuário humano que atua como supervisor.

A UI principal expõe um **Explore Workspace** em três colunas, alinhado ao wireframe oficial `MiniIDE-Explore.html`, funcionando como cockpit para:

- **Explorar contexto** (projeto atual, HUs, docs, timeline);
- **Acionar o backend** via `/healthz` e `/analyze`;
- **Registrar intenção, requisitos, restrições e referências** (Discovery Notes);
- **Visualizar eventos** da sessão (Timeline de Exploração).

Este documento foca nos aspectos de desenvolvimento e integração, especialmente da camada **@mini-ide/ui** com **@mini-ide/server**.

---

## 2. Estrutura de workspaces (monorepo)

Monorepo gerido por **pnpm** com os workspaces principais:

- `packages/analysis-agent`  
  Orquestração de análise e integração com LLMs, responsável por coordenar chamadas ao servidor e interpretar respostas.

- `packages/server` (`@mini-ide/server`)  
  Servidor HTTP (Fastify) com endpoints principais:
  - `GET /healthz` — health check;
  - `POST /analyze` — endpoint de análise, contrato tipado em `@mini-ide/shared`.

- `packages/shared` (`@mini-ide/shared`)  
  Tipos compartilhados, incluindo:
  - Contrato da resposta de `/analyze`;
  - Tipos utilitários de provider LLM e configuração.

- `packages/ui` (`@mini-ide/ui`)  
  Frontend em React + Vite, responsável por renderizar o **Explore Workspace** e integrar-se aos endpoints do servidor.

- `packages/cli` (`@mini-ide/cli`)  
  Ferramentas de linha de comando para interação com o Mini-IDE via terminal.

Scripts globais relevantes na raiz:

- `42_pipeline_checklist.sh` — pipeline completa (lint, typecheck, test, build, smoke /healthz e /analyze);
- Scripts numerados (`0x_*.sh`, `1x_*.sh`, etc.) — automações de diagnóstico e correção incremental.

---

## 3. Tooling e padrões de qualidade

- **Gerenciador de pacotes:** `pnpm`  
- **Lint:** `eslint` com configuração por pacote (incluindo `packages/ui/eslint.config.js`).  
- **Testes:** `vitest` com `jsdom` para testes de UI.  
- **Build UI:** `vite build` via script `@mini-ide/ui: build`.  
- **Type-check:** `tsc --noEmit` por pacote.  
- **Husky / pre-commit:** hooks garantindo que commits passem pelos checks mínimos (lint, typecheck filtrado).

O pipeline de validação recomendado:

```bash
REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh
```

Que executa, nesta ordem:

1. `pnpm lint`
2. `pnpm typecheck`
3. `pnpm test`
4. `pnpm build`
5. Smoke test `GET /healthz`
6. Smoke test `POST /analyze` com validação de contrato.

---

## 4. Backend HTTP — @mini-ide/server (resumo)

### 4.1 Endpoint GET /healthz

- Retorna 200 quando o servidor está saudável.  
- Usado pela UI (ServerStatus) para exibir estado:  
  - ⏳ verificando;  
  - 🟢 servidor online;  
  - 🔴 servidor indisponível.

### 4.2 Endpoint POST /analyze

- Contrato tipado em `@mini-ide/shared/types/analyze-response.ts`.
- Campos **obrigatórios** na resposta:
  - `summary: string`
  - `inputLength: number`
  - `outputLength: number`
  - `requestId: string`
  - `timestamp: string` (ISO 8601)
- Campos **opcionais**:
  - `budgetUsed?: number`
  - `budgetRemaining?: number`

A UI consome esse contrato via `AnalyzePlayground`, exibindo a resposta de forma estruturada.

---

## 5. UI — @mini-ide/ui

### 5.1 Stack e entrypoint

- React + TypeScript;
- Build com Vite (`packages/ui/vite.config.ts`);
- Entry principal em `packages/ui/src/main.tsx` + `App.tsx`;
- Estilos globais em `packages/ui/src/styles/global.css`.

Configuração do backend na UI:

- Arquivo: `packages/ui/src/config/server.ts`  
- Usa a env `VITE_MINI_IDE_SERVER_URL` como base para:
  - `getBaseUrl()`
  - `getHealthzUrl()`
  - `getAnalyzeUrl()`

### 5.2 Explore Workspace — layout em 3 colunas

O layout do Explore Workspace segue **estritamente** o wireframe oficial `MiniIDE-Explore.html` e as regras estabelecidas na governança da UI:

- **Coluna esquerda (~280px)** — `Sidebar`  
  - Projeto atual (nome, repo, branch);  
  - Árvore de arquivos (placeholder para evolução futura);  
  - Status do projeto / sessão.

- **Coluna central (expansível)** — `WorkspaceTabs`  
  - 10 abas internas:
    1. Overview  
    2. HUs  
    3. Docs  
    4. Testes  
    5. Analyze  
    6. Personas & Plano  
    7. Timeline  
    8. Runs  
    9. Métricas  
    10. Outputs

- **Coluna direita (~360px)** — `DiscoveryNotes`  
  - Intenção;  
  - Requisitos;  
  - Restrições;  
  - Exemplos & Referências.

Header e footer:

- **Header**: título da Mini-IDE, contexto da sessão, badges de agente (ex.: *Analysis Agent*), estado de exploração.  
- **Footer**: área de chat (textarea) + botões de ação (Anexar, Enviar, etc.).

### 5.3 Governança da UI — Explore Workspace (seção 5.6.5 lógica)

Regras imutáveis de governança visual e estrutural:

1. **Layout de 3 colunas é fixo**  
   - Não é permitido substituir o layout por modo “tela cheia” ou “multi-layout” sem HU explícita de redesign.

2. **Wireframe como fonte de verdade visual**  
   - `MiniIDE-Explore.html` é referência obrigatória para espaçamento, proporções e organização dos painéis.  
   - Toda HU de UI deve declarar:
     - O que mantém igual ao wireframe;
     - O que adiciona;
     - Qualquer divergência necessária (com justificativa).

3. **Integração incremental**  
   - Novas features devem ser plugadas em:
     - `Sidebar` (coluna esquerda),  
     - `WorkspaceTabs` (coluna central),  
     - `DiscoveryNotes` (coluna direita),  
     sem destruir a estrutura base.

4. **Integração com backend**  
   - Toda integração com `/healthz` e `/analyze` deve respeitar:
     - Tipagem de `@mini-ide/shared`;  
     - Tratamento de erros amigável na UI;  
     - Não quebrar o pipeline (`pnpm lint`, `pnpm test`, `pnpm typecheck`, `pnpm build`).

---

## 6. Lote 3 – Explore Workspace (v1.0.18)

Este lote implementa e integra 3 HUs principais na UI, além de consolidar a integração no `WorkspaceTabs`:

- **HU-UI-Discovery-Notes-002 – Discovery Notes Evoluídas**  
- **HU-UI-Explore-Mode-001 – Modo Explorar com Coleta Automática (Overview)**  
- **HU-UI-Timeline-003 – Timeline de Exploração (Timeline)**  

### 6.1 HU-UI-Discovery-Notes-002 — Discovery Notes Evoluídas

**Arquivos principais**:

- `packages/ui/src/components/discovery/DiscoveryNotes.tsx`
- `packages/ui/src/components/discovery/DiscoveryNotes.module.css`
- Testes: `packages/ui/test/components/DiscoveryNotes.test.tsx`

**Objetivo**  
Transformar o painel direito em um **editor assistido** de notas de descoberta, com:

- Campos editáveis:
  - Intenção  
  - Requisitos  
  - Restrições  
  - Exemplos & Referências
- Persistência local no navegador (storage estilo `localStorage`), sem quebrar SSR ou ambientes sem DOM.

**Implementação**

- Utiliza React hooks (`useState`, `useEffect`, `useCallback`) para gerenciar o estado das notas.
- Introduz um tipo seguro de storage:

  ```ts
  type SafeStorage = {
    getItem(key: string): string | null;
    setItem(key: string, value: string): void;
  } | null;
  ```

- Função de descoberta de storage:

  ```ts
  function getSafeStorage(): SafeStorage {
    try {
      if (typeof globalThis === 'undefined') return null;

      const maybeStorage = (globalThis as { localStorage?: unknown }).localStorage;
      if (!maybeStorage) return null;

      const storage = maybeStorage as { getItem?: unknown; setItem?: unknown };
      if (typeof storage.getItem !== 'function' || typeof storage.setItem !== 'function') {
        return null;
      }

      return storage as SafeStorage;
    } catch {
      return null;
    }
  }
  ```

- Carregamento e salvamento com tratamento de erros:

  ```ts
  function loadNotesFromStorage(storage: SafeStorage): DiscoveryNotesData { ... }
  function saveNotesToStorage(storage: SafeStorage, notes: DiscoveryNotesData): void { ... }
  ```

- Na montagem, a UI tenta carregar as notas previamente salvas; sempre que as notas mudam, o componente persiste os dados de forma segura.

**Regras importantes**

- Nenhum uso direto de `window` ou `localStorage` sem checagem;  
- Nenhum `eslint-disable` residual (lint limpo);  
- Layout do painel direito (~360px) preservado, sem impactar as demais colunas.

**Testes**

- Cobrem:
  - Renderização inicial;  
  - Edição de cada campo;  
  - Persistência com storage disponível;  
  - Comportamento sem storage (fallback seguro);  
  - Acessibilidade básica (labels, aria-labels).

---

### 6.2 HU-UI-Explore-Mode-001 — Modo Explorar (Overview)

**Arquivos principais**:

- `packages/ui/src/components/explore/ExploreOverview.tsx`
- `packages/ui/src/components/explore/ExploreOverview.module.css`
- Testes: `packages/ui/test/components/ExploreOverview.test.tsx`

**Objetivo**  
Transformar a aba **Overview** em um painel de estado da sessão, exibindo:

- **Estado da sessão**: `Discovery`, `Execution`, `Review` ou `Idle`;  
- Informações do **projeto atual**:
  - Nome do projeto;  
  - Repositório;  
  - Branch;  
  - Caminho local (quando relevante);  
- **Últimas análises** (mockadas nesta versão):
  - Timestamp da execução;  
  - Resumo curto;  
  - Referência ao `requestId` ou similar.

**Implementação**

- Componente `ExploreOverview` recebe (hoje) dados mockados, com tipagem clara para futura integração real.
- Layout respeita o wireframe, com:

  - Bloco superior de “estado da sessão”;  
  - Bloco de “projeto atual”;  
  - Lista de “últimas análises”.

**Testes**

- Validam:
  - Renderização com valores padrão;  
  - Renderização de cada estado de sessão;  
  - Exibição das informações básicas do projeto;  
  - Exibição da lista de análises;  
  - Estrutura e acessibilidade.

---

### 6.3 HU-UI-Timeline-003 — Timeline de Exploração

**Arquivos principais**:

- `packages/ui/src/components/explore/ExploreTimeline.tsx`
- `packages/ui/src/components/explore/ExploreTimeline.module.css`
- Testes: `packages/ui/test/components/ExploreTimeline.test.tsx`

**Objetivo**  
Criar uma **timeline cronológica de eventos** da sessão, exibida na aba **Timeline** do painel central.

Tipos de eventos suportados (mock inicial):

- `analysis` — chamadas a `/analyze`;  
- `discovery` — atualizações de Discovery Notes;  
- `project` — mudanças de branch / contexto de projeto;  
- `execution` — execuções de pipelines / scripts;  
- `system` — eventos de sistema / housekeeping.

**Implementação**

- Ordenação dos eventos do mais recente para o mais antigo;
- Filtros por tipo de evento (múltipla seleção);
- Cada evento exibe:
  - Ícone e cor por tipo;  
  - Título curto;  
  - Descrição opcional;  
  - Data/hora absoluta (`HH:MM:SS`);  
  - Tempo relativo (“X min atrás”).

**Testes**

- Validam:
  - Renderização da lista de eventos;  
  - Ordenação correta (mais recente primeiro);  
  - Aplicação de filtros por tipo;  
  - Estado vazio quando não há eventos;  
  - Formatação de timestamp e tempo relativo;  
  - Acessibilidade básica.

---

### 6.4 Integração no WorkspaceTabs

**Arquivos principais**:

- `packages/ui/src/components/WorkspaceTabs.tsx`
- `packages/ui/src/components/WorkspaceTabs.module.css`
- Testes: `packages/ui/test/components/WorkspaceTabs.test.tsx`  
- Integração com `App.tsx` e layout geral.

**Objetivo**  
Conectar as novas funcionalidades às abas internas do painel central, mantendo as **10 abas definidas em governança** e o layout de 3 colunas intacto.

**Mapeamento das abas**

- `overview` → `ExploreOverview`  
- `analyze` → `ServerStatus` + `AnalyzePlayground`  
- `timeline` → `ExploreTimeline`  
- `hus`, `docs`, `tests`, `personas`, `runs`, `metrics`, `outputs` → placeholders amigáveis, preparados para evolução futura.

**Comportamento padrão**

- Aba inicial: `overview`;  
- Clique em uma aba:
  - Atualiza o estado interno `activeTab`;  
  - Aplica classe CSS de aba ativa;  
  - Renderiza apenas o conteúdo da aba selecionada.

**Testes**

- Verificam:
  - Renderização das 10 abas;  
  - Aba Overview ativa por padrão;  
  - Troca para aba Analyze ao clique;  
  - Presença de `ServerStatus` e `AnalyzePlayground` na aba Analyze;  
  - Integração com `App` (layout de 3 colunas + abas).

---

## 7. Qualidade e estado da release v1.0.18 (UI Lote 3)

Para o estado atual descrito neste documento:

- `REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh`  
  - ✅ Lint — passou  
  - ✅ Type-check — passou  
  - ✅ Testes (Vitest) — passaram em todos os pacotes  
  - ✅ Build — passou em todos os pacotes  
  - ✅ Smoke `/healthz` — OK  
  - ✅ Smoke `/analyze` — contrato respeitado

- `pnpm -r test`  
  - `@mini-ide/shared` — 47 testes passando  
  - `@mini-ide/ui` — 50 testes passando  
  - `@mini-ide/analysis-agent` — 1 teste passando  
  - `@mini-ide/cli` — 2 testes passando  
  - `@mini-ide/server` — 65 testes passando  

Este é o **ponto de restauração lógico** da release v1.0.18 com o **Lote 3 do Explore Workspace** implementado e validado.

---

## 8. Próximos passos sugeridos (UI)

Fora do escopo implementado neste lote, ficam como backlog de UI (já discutidos conceitualmente):

- **HU-UI-Export-005 — Exportar Sessão de Exploração**
  - Exportar notas, timeline e último resultado de `/analyze` em Markdown/JSON.

- **HU-UI-Workspace-State-Persistence-006 — Persistência do Workspace**
  - Persistir aba ativa, conteúdo das Discovery Notes (já parcialmente feito) e último input do Analyze.

- **HU-UI-Theme-System-007 — Sistema de Tema Claro/Escuro**
  - Implementar toggle de tema no header, com persistência em storage.

Qualquer implementação futura deve:

1. Respeitar as regras de governança da UI (layout 3 colunas, wireframe, integração incremental);  
2. Manter a pipeline verde (`42_pipeline_checklist.sh`);  
3. Atualizar este `DEVELOPMENT.md` descrevendo:
   - HUs impactadas;  
   - Arquivos principais;  
   - Regras de negócio e de UI;  
   - Estratégia de testes e qualidade.

