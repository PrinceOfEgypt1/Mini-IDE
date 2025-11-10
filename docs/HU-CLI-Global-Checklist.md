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
