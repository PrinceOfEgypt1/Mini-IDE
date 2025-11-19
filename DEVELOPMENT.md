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
