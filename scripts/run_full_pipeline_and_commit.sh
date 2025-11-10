#!/usr/bin/env bash
[[ "${BASH_SOURCE[0]}" != "$0" ]] && { echo "[erro] não faça source: execute ./scripts/run_full_pipeline_and_commit.sh"; return 1 2>/dev/null || exit 1; }
set -euo pipefail

# ==============================================================================
# Script: run_full_pipeline_and_commit.sh
# Objetivo: Rodar pipeline completo e commitar/push em branch chore
# ==============================================================================
# Affected files:
#   - Todos os arquivos modificados pelos scripts anteriores
#   - Nova branch: chore/checklist-audit-hardening
# ==============================================================================
# Assumptions:
#   - Git configurado e com acesso ao repositório remoto
#   - Scripts anteriores já executados com sucesso
#   - 42_pipeline_checklist.sh está verde
# ==============================================================================
# Risks:
#   - Push pode falhar se branch remota tiver divergências
# ==============================================================================
# How to revert:
#   - git switch main
#   - git branch -D chore/checklist-audit-hardening
#   - git push origin --delete chore/checklist-audit-hardening
# ==============================================================================

echo "[info] Iniciando processo de pipeline e commit/push"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[info]${NC} $*"; }
log_ok() { echo -e "${GREEN}[ok]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
log_fail() { echo -e "${RED}[fail]${NC} $*"; }

# ==============================================================================
# 1) Validar que estamos em um repositório Git
# ==============================================================================
log_info "Verificando repositório Git..."

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  log_fail "Não está em um repositório Git"
  exit 1
fi

log_ok "Repositório Git detectado"

# ==============================================================================
# 2) Sincronizar com main
# ==============================================================================
log_info "Sincronizando com branch main..."

# Salvar branch atual
CURRENT_BRANCH=$(git branch --show-current)
log_info "Branch atual: $CURRENT_BRANCH"

# Verificar se há mudanças não commitadas
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
  log_warn "Há mudanças não commitadas. Elas serão incluídas no commit."
fi

# Switch para main e atualizar
if [ "$CURRENT_BRANCH" != "main" ]; then
  log_info "Salvando trabalho e mudando para main..."
  git stash push -m "Auto-stash antes de pipeline" || true
  
  if ! git switch main; then
    log_fail "Não foi possível mudar para branch main"
    exit 1
  fi
  
  log_info "Atualizando main com --ff-only..."
  if ! git pull --ff-only; then
    log_warn "Pull com --ff-only falhou, tentando pull normal..."
    if ! git pull; then
      log_fail "Não foi possível atualizar branch main"
      exit 1
    fi
  fi
  
  log_ok "Branch main atualizada"
  
  # Restaurar stash se necessário
  if git stash list | grep -q "Auto-stash antes de pipeline"; then
    log_info "Restaurando trabalho salvo..."
    git stash pop || log_warn "Não foi possível restaurar stash automaticamente"
  fi
else
  log_info "Já está em main, apenas atualizando..."
  git pull --ff-only || git pull || log_warn "Pull falhou, prosseguindo..."
fi

# ==============================================================================
# 3) Executar pipeline completo
# ==============================================================================
log_info "Executando pipeline completo (42_pipeline_checklist.sh)..."
log_warn "Isso pode levar alguns minutos..."

if ! REQUIRE_GLOBAL_CLI=0 bash ./42_pipeline_checklist.sh; then
  log_fail "Pipeline falhou. Não é possível prosseguir com commit."
  log_info "Revise os erros acima e corrija antes de continuar"
  exit 1
fi

log_ok "Pipeline passou 100% verde ✅"

# ==============================================================================
# 4) Criar/mudar para branch de chore
# ==============================================================================
BRANCH_NAME="chore/checklist-audit-hardening"

log_info "Preparando branch: $BRANCH_NAME"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  log_info "Branch $BRANCH_NAME já existe, fazendo switch..."
  if ! git switch "$BRANCH_NAME"; then
    log_fail "Não foi possível mudar para branch $BRANCH_NAME"
    exit 1
  fi
  
  # Merge/rebase com main se necessário
  log_info "Sincronizando $BRANCH_NAME com main..."
  git merge main --no-edit || log_warn "Merge automático com main apresentou conflitos"
else
  log_info "Criando nova branch: $BRANCH_NAME"
  if ! git switch -c "$BRANCH_NAME"; then
    log_fail "Não foi possível criar branch $BRANCH_NAME"
    exit 1
  fi
fi

log_ok "Branch $BRANCH_NAME pronta"

# ==============================================================================
# 5) Adicionar arquivos modificados
# ==============================================================================
log_info "Adicionando arquivos modificados ao stage..."

git add -A

# Mostrar status
log_info "Status do Git:"
git status --short

# Verificar se há algo para commitar
if git diff-index --quiet HEAD -- 2>/dev/null; then
  log_warn "Nenhuma mudança para commitar"
  log_info "Possíveis razões:"
  log_info "  - Scripts já foram executados e commitados anteriormente"
  log_info "  - Nenhum arquivo foi modificado"
  echo ""
  log_ok "Pipeline está verde, branch está atualizada"
  exit 0
fi

# ==============================================================================
# 6) Commitar com mensagem estruturada
# ==============================================================================
COMMIT_MESSAGE="chore(checklist): hardening grep e comparações numéricas; fix(server-tests): tipagem forte em test-utils (sem any, sem assertions desnecessárias). Pipeline 100% verde."

log_info "Criando commit..."
log_info "Mensagem: $COMMIT_MESSAGE"

if ! git commit -m "$COMMIT_MESSAGE"; then
  log_fail "Commit falhou"
  exit 1
fi

log_ok "Commit criado com sucesso"

# Mostrar commit
log_info "Detalhes do commit:"
git log -1 --oneline --stat

# ==============================================================================
# 7) Push para repositório remoto
# ==============================================================================
log_info "Fazendo push para origin/$BRANCH_NAME..."

# Verificar se origin existe
if ! git remote get-url origin > /dev/null 2>&1; then
  log_warn "Remote 'origin' não configurado"
  log_info "Configure o remote com: git remote add origin <url>"
  log_info "Ou faça push manual: git push -u origin $BRANCH_NAME"
  exit 0
fi

# Push com upstream tracking
if git push -u origin "$BRANCH_NAME" 2>&1; then
  log_ok "Push realizado com sucesso ✅"
else
  log_fail "Push falhou"
  log_info "Possíveis razões:"
  log_info "  - Sem acesso ao repositório remoto"
  log_info "  - Conflitos com versão remota"
  log_info "  - Autenticação necessária"
  echo ""
  log_info "Tente fazer push manual:"
  log_info "  git push -u origin $BRANCH_NAME"
  exit 1
fi

# ==============================================================================
# RESUMO FINAL
# ==============================================================================
echo ""
log_ok "=========================================="
log_ok "PROCESSO CONCLUÍDO COM SUCESSO ✅"
log_ok "=========================================="
log_ok "✓ Pipeline executado (100% verde)"
log_ok "✓ Branch criada/atualizada: $BRANCH_NAME"
log_ok "✓ Commit realizado"
log_ok "✓ Push para origin/$BRANCH_NAME"
echo ""
log_info "Próximos passos:"
log_info "  1. Abrir Pull Request no GitHub:"
log_info "     gh pr create --base main --head $BRANCH_NAME"
log_info ""
log_info "  2. Ou acessar GitHub e criar PR manualmente"
log_info ""
log_info "  3. Aguardar code review e merge"
echo ""
log_info "Para voltar para main:"
log_info "  git switch main"
echo ""
