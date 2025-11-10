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
