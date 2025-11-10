#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
SERVER_DIR="$ROOT_DIR/packages/server"
REL_FILE="test/test-utils.ts"
ABS_FILE="$SERVER_DIR/$REL_FILE"
TS_BAK="$ABS_FILE.bak.awaitfix.$(date +%Y%m%d%H%M%S)"

echo "[info] Alvo: $ABS_FILE"
[[ -f "$ABS_FILE" ]] || { echo "[fail] Arquivo não encontrado: $ABS_FILE"; exit 1; }

# --- backup ---
cp -f "$ABS_FILE" "$TS_BAK"
echo "[ok] Backup criado: $TS_BAK"

# --- função que retorna linhas com await-thenable via ESLint ---
get_await_thenable_lines() {
  # Força ESLint a rodar no pacote do server para resolver configs locais
  ( cd "$SERVER_DIR" && pnpm exec eslint "$REL_FILE" --max-warnings=0 ) 2>&1 \
  | awk '
      /^[[:space:]]*[0-9]+:[0-9]+[[:space:]]+error[[:space:]]+Unexpected `await` of a non-Promise/ {
        split($1, a, ":"); print a[1];
      }
    ' | sort -n | uniq
}

# --- função que remove "await " apenas nas linhas especificadas ---
remove_await_on_lines() {
  local file="$1"; shift
  local lines=("$@")
  # Usamos sed -i com endereço de linha: substitui a 1ª ocorrência de "await<espacos>"
  for ln in "${lines[@]}"; do
    # segurança: só edita se a linha existir
    if [[ "$(wc -l < "$file")" -ge "$ln" ]]; then
      sed -i "${ln}s/\<await\>[[:space:]]\+//" "$file"
      echo "[patch] Removido 'await ' na linha ${ln}"
    fi
  done
}

# --- loop de correção ---
MAX_PASSES=5
pass=1
while (( pass <= MAX_PASSES )); do
  echo "[info] ESLint pass #$pass…"
  mapfile -t LINES < <(get_await_thenable_lines || true)

  if (( ${#LINES[@]} == 0 )); then
    echo "[ok] Nenhum await-thenable encontrado 🎯"
    break
  fi

  echo "[info] Linhas com await-thenable: ${LINES[*]}"
  remove_await_on_lines "$ABS_FILE" "${LINES[@]}"

  # Revalida ESLint imediatamente após o patch
  if ( cd "$SERVER_DIR" && pnpm exec eslint "$REL_FILE" --max-warnings=0 ); then
    echo "[ok] ESLint OK após pass #$pass"
    break
  else
    echo "[warn] Ainda há ocorrências; seguindo para próxima iteração…"
  fi

  (( pass++ ))
done

# Se após o loop ainda houver erro, restaura backup
if ! ( cd "$SERVER_DIR" && pnpm exec eslint "$REL_FILE" --max-warnings=0 ); then
  echo "[fail] ESLint ainda falhou após ${MAX_PASSES} passes; restaurando $TS_BAK"
  cp -f "$TS_BAK" "$ABS_FILE"
  exit 1
fi

# Typecheck do pacote server
echo "[info] Typecheck (server)…"
( cd "$SERVER_DIR" && pnpm exec tsc -p tsconfig.json --noEmit )

echo "[ok] Patch aplicado e validado (ESLint + TypeScript)."

# Dica: rodar o pipeline completo e commitar
echo "[tip] Para validar tudo e commitar:"
echo "     bash scripts/run_all_then_commit.sh \"chore(server/tests): remover await de helpers síncronos (await-thenable)\""
