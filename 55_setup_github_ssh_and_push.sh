#!/usr/bin/env bash
# 55_setup_github_ssh_and_push.sh
# Diretório de execução: ~/workspace/Mini-IDE
# Objetivo: resolver "Permission denied (publickey)" no git@github.com e realizar push seguro
# - Garante remote origin em SSH (ou ajusta)
# - Cria chave SSH (ed25519) se não existir (S/ senha por padrão; ajuste se preferir)
# - Inicia ssh-agent, adiciona a chave e testa conexão
# - Tenta registrar chave no GitHub via `gh` (se disponível); senão, imprime a chave p/ você colar
# - Faz git push -u origin main
#
# OBS: por segurança, você pode editar para usar passphrase na chave:
#      troque `-N ""` por `-N "sua_senha_segura"`

set -euo pipefail

ROOT="$(pwd)"
REPO_SSH="${1:-git@github.com:PrinceOfEgypt1/Mini-IDE.git}"

echo "== 55 :: SETUP GITHUB SSH & PUSH =="
echo "[ctx] ROOT=$ROOT"
echo "[ctx] ORIGIN_TARGET=$REPO_SSH"

# 1) Verificar se .git existe
if [[ ! -d ".git" ]]; then
  echo "[erro] Este diretório não é um repositório Git. Rode: git init && git add -A && git commit -m 'init' " >&2
  exit 1
fi

# 2) Garantir origin em SSH
CURRENT_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [[ -z "$CURRENT_ORIGIN" ]]; then
  git remote add origin "$REPO_SSH"
  echo "[ok] origin adicionado: $REPO_SSH"
else
  if [[ "$CURRENT_ORIGIN" != "$REPO_SSH" ]]; then
    echo "[info] origin atual: $CURRENT_ORIGIN"
    echo "[info] ajustando origin para: $REPO_SSH"
    git remote set-url origin "$REPO_SSH"
  fi
  echo "[ok] origin configurado: $(git remote get-url origin)"
fi

# 3) Gerar chave SSH se não existir
SSH_DIR="$HOME/.ssh"
KEY_PRIV="$SSH_DIR/id_ed25519"
KEY_PUB="$SSH_DIR/id_ed25519.pub"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$KEY_PUB" ]]; then
  COMMENT="${USER}@$(hostname)-mini-ide-$(date +%Y%m%d)"
  echo "[info] Gerando nova chave SSH ed25519 (sem passphrase; ajuste se quiser)…"
  ssh-keygen -t ed25519 -C "$COMMENT" -N "" -f "$KEY_PRIV" <<< y >/dev/null 2>&1 || true
  if [[ ! -f "$KEY_PUB" ]]; then
    echo "[erro] Falha ao gerar chave SSH." >&2
    exit 1
  fi
  echo "[ok] Chave criada: $KEY_PUB"
fi
chmod 600 "$KEY_PRIV"
chmod 644 "$KEY_PUB"

# 4) Iniciar ssh-agent e adicionar chave
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$KEY_PRIV" >/dev/null
echo "[ok] ssh-agent ativo e chave adicionada"

# 5) Tentar registrar chave no GitHub via gh (se disponível)
if command -v gh >/dev/null 2>&1; then
  echo "[info] Detectado GitHub CLI (gh). Tentando adicionar a chave…"
  # nome único p/ a chave
  TITLE="Mini-IDE $(hostname) $(date +%Y-%m-%d)"
  gh ssh-key add "$KEY_PUB" --title "$TITLE" --type authentication || true
else
  echo "---------------------------------------------"
  echo "[ação necessária] Adicione esta chave pública no GitHub (Settings > SSH and GPG keys > New SSH key):"
  echo
  cat "$KEY_PUB"
  echo
  echo "---------------------------------------------"
  echo "[dica] Depois de adicionar, teste a conexão:"
  echo "       ssh -T git@github.com"
fi

# 6) Testar conexão SSH (não falhar se exigir confirmação)
ssh -T git@github.com || true

# 7) Fazer push
echo "[info] Fazendo push para origin (main)…"
git fetch origin || true
git add -A
git commit -m "chore: finalize bundle v1.0.12 (SSH setup & CLI path)" || true
git push -u origin main

echo "== 55 :: OK — Push realizado (ou pronto após adicionar a chave no GitHub) ✅ =="
