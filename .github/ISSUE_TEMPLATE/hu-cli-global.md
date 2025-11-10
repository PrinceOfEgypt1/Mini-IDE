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
