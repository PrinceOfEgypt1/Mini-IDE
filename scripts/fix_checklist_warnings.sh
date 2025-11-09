#!/usr/bin/env bash
set -euo pipefail

TARGET="42_pipeline_checklist.sh"

# 0) Sanidade: existir e ser arquivo
if [[ ! -f "$TARGET" ]]; then
  echo "[erro] $TARGET não encontrado na raiz. Rode a partir de ~/workspace/Mini-IDE"
  exit 1
fi

# 1) Backup
STAMP="$(date +%Y%m%d-%H%M%S)"
cp -f "$TARGET" "${TARGET}.bak.${STAMP}"

# 2) Garantir shebang + set -euo (apenas se não existir)
#    Obs: não habilito set -x para não poluir pipeline
if ! head -n 1 "$TARGET" | grep -qE '^#!/'; then
  sed -i '1s|^|#!/usr/bin/env bash\n|' "$TARGET"
fi
if ! grep -q 'set -euo pipefail' "$TARGET"; then
  sed -i '1a set -euo pipefail' "$TARGET"
fi

# 3) Corrigir GREP: adicionar -E e '--' onde faltar
#    - Se a linha tem 'grep' mas não tem -E nem -F, adiciona -E.
#    - Adiciona '--' antes do padrão/arquivos (não duplica).
#    - Não mexe em linhas já com -E/-F ou com --.
tmp="$(mktemp)"
awk '
  function has_flag(s,f) { return index(s,f)>0 }
  /^.*\bgrep\b/ {
    line=$0
    # pular pipes que são só " | grep -q " etc — ainda queremos -E por padrão
    # 3.1) Inserir -E se não houver -E/-F
    if (line ~ /\bgrep\b/ && line !~ /\bgrep[^\n]*\-(E|F)\b/) {
      sub(/\bgrep\b/, "grep -E", line)
    }
    # 3.2) Inserir -- se não houver
    if (line ~ /\bgrep\b/ && line !~ /--/) {
      # após flags, antes do primeiro padrão
      # substitui "grep -E  PATTERN" por "grep -E -- PATTERN"
      sub(/grep([^|;"]*)-E[[:space:]]+/, "grep\\1-E -- ", line)
      sub(/grep([^|;"]*)-F[[:space:]]+/, "grep\\1-F -- ", line)
      sub(/grep([[:space:]]+)/, "grep -- ", line) # fallback
    }
    print line
    next
  }
  { print }
' "$TARGET" > "$tmp" && mv "$tmp" "$TARGET"

# 4) Blindar comparações numéricas com variáveis possivelmente vazias
#    Converte: [ "$X" -gt 0 ] -> [[ "${X:-}" =~ ^[0-9]+$ ]] && [ "$X" -gt 0 ]
#    Mesma lógica para -ge, -lt, -le.
#    *Casos já protegidos por regex não serão tocados.
perl -0777 -pe '
  s/\[\s*"\$([A-Za-z_]\w*)"\s*-(gt|ge|lt|le)\s*([0-9]+)\s*\]/[[ "\${$1:-}" =~ ^[0-9]+$ ]] \&\& [ "\${$1}" -$2 $3 ]/g
' -i "$TARGET"

# 5) Também cobre test [[ "$X" -gt 0 ]] (com [[ ... ]])
perl -0777 -pe '
  s/\[\[\s*"\$([A-Za-z_]\w*)"\s*-(gt|ge|lt|le)\s*([0-9]+)\s*\]\]/[[ "\${$1:-}" =~ ^[0-9]+$ ]] \&\& [ "\${$1}" -$2 $3 ]/g
' -i "$TARGET"

# 6) Validar sintaxe
bash -n "$TARGET"

echo "[ok] $TARGET: grep ajustados e comparações numéricas robustas."
echo "[ok] backup em: ${TARGET}.bak.${STAMP}"
