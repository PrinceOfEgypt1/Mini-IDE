# 36b_set_origin_and_redoc.sh
# -------------------------------------------------------------------------------------------------
# Diretório de execução: ~/workspace/Mini-IDE   (raiz do projeto)
# Objetivo:
#   - Definir (ou trocar) o git remote "origin" de forma segura.
#   - Aceita origem via argumento ($1) ou variável de ambiente GIT_ORIGIN.
#   - Regera a documentação (TypeDoc) e checa se o aviso de "origin inválido" sumiu.
# Uso:
#   bash 36b_set_origin_and_redoc.sh git@github.com:<user>/Mini-IDE.git
#   # ou
#   GIT_ORIGIN="https://github.com/<user>/Mini-IDE.git" bash 36b_set_origin_and_redoc.sh
# Opções:
#   REPLACE_ORIGIN=1  → se já existir origin, faz set-url (troca) em vez de abortar.
# Requisitos: git, pnpm
# -------------------------------------------------------------------------------------------------
set -euo pipefail

ROOT="$HOME/workspace/Mini-IDE"
cd "$ROOT" || { echo "[erro] não encontrei $ROOT"; exit 1; }

ORIGIN_INPUT="${1:-${GIT_ORIGIN:-}}"
REPLACE="${REPLACE_ORIGIN:-0}"

# 1) Capturar origem (arg/env) ou solicitar interativamente
if [ -z "$ORIGIN_INPUT" ]; then
  echo "[info] GIT_ORIGIN não informado (nem arg nem env)."
  # sugestão baseada no nome do projeto; ajuste se necessário
  read -r -p "Informe a URL do remote origin (ex.: git@github.com:PrinceOfEgypt1/Mini-IDE.git): " ORIGIN_INPUT
fi

# 2) Validação simples da URL
if ! printf "%s" "$ORIGIN_INPUT" | grep -Eq '^(git@|https://).+\.git$'; then
  echo "[erro] URL inválida para origin: $ORIGIN_INPUT"
  echo "       Exemplos válidos:"
  echo "       - git@github.com:PrinceOfEgypt1/Mini-IDE.git"
  echo "       - https://github.com/PrinceOfEgypt1/Mini-IDE.git"
  exit 1
fi

# 3) Garantir repo inicializado e branch main
if [ ! -d ".git" ]; then
  echo "[info] repositório git não inicializado; executando git init"
  git init
fi
# força branch principal para main (idempotente)
git symbolic-ref HEAD refs/heads/main >/dev/null 2>&1 || true
git branch -M main >/dev/null 2>&1 || true

# 4) Configurar origin (novo ou troca)
if git remote get-url origin >/dev/null 2>&1; then
  CURRENT="$(git remote get-url origin || true)"
  if [ "$CURRENT" = "$ORIGIN_INPUT" ]; then
    echo "[ok] origin já configurado para $CURRENT"
  else
    if [ "$REPLACE" = "1" ]; then
      echo "[info] trocando origin:"
      echo "       de: $CURRENT"
      echo "       p/: $ORIGIN_INPUT"
      git remote set-url origin "$ORIGIN_INPUT"
      echo "[ok] origin atualizado"
    else
      echo "[erro] origin já existe apontando para: $CURRENT"
      echo "       Para substituir, rode com REPLACE_ORIGIN=1"
      echo "       Ex.: REPLACE_ORIGIN=1 bash 36b_set_origin_and_redoc.sh \"$ORIGIN_INPUT\""
      exit 1
    fi
  fi
else
  echo "[info] adicionando origin: $ORIGIN_INPUT"
  git remote add origin "$ORIGIN_INPUT"
  echo "[ok] origin configurado"
fi

# 5) Regerar documentação e verificar aviso do TypeDoc
echo "[info] gerando TypeDoc…"
TMP_LOG="$(mktemp)"
if pnpm run docs >"$TMP_LOG" 2>&1; then
  echo "[ok] TypeDoc executado"
else
  echo "[erro] falha ao gerar TypeDoc. Log:"
  cat "$TMP_LOG"
  rm -f "$TMP_LOG"
  exit 1
fi

DOC_MAIN="$ROOT/docs/api/index.html"
if [ ! -f "$DOC_MAIN" ]; then
  echo "[erro] artefato não encontrado: $DOC_MAIN"
  rm -f "$TMP_LOG"
  exit 1
fi

if grep -q "The provided git remote \"origin\" was not valid" "$TMP_LOG"; then
  echo "[aviso] TypeDoc ainda reportou remote inválido. Verifique se você tem acesso ao origin:"
  echo "        $(git remote get-url origin)"
  echo "        (o aviso pode persistir até o primeiro push; é seguro ignorar por ora)"
else
  echo "[ok] nenhum aviso de remote inválido encontrado no TypeDoc"
fi

rm -f "$TMP_LOG"

# 6) Resumo e próximos passos
echo "----------------------------------------"
echo "ORIGIN      : $(git remote get-url origin)"
echo "BRANCH      : $(git branch --show-current)"
echo "DOCS        : $DOC_MAIN"
echo "----------------------------------------"
echo "[dica] Primeiro push (se for o caso):"
echo "       git add -A && git commit -m \"chore: inicializa origin e docs\" || true"
echo "       git push -u origin main"
