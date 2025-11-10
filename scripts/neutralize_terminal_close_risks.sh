#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "[1/5] Removendo 'exec node' em scripts ativos…"
# Só em scripts fora de archive/, para não reescrever histórico
grep -RIl --exclude-dir=archive-*/ --include='*.sh' -E '^[[:space:]]*exec[[:space:]]+node[[:space:]]' scripts \
  | while read -r f; do
    sed -i -E 's/^[[:space:]]*exec[[:space:]]+node[[:space:]]/node /' "$f"
    echo " - $f"
  done || true

echo "[2/5] Corrigindo typos 'exit 1' -> 'exit 1'…"
grep -RIl --include='*.sh' -E '\bexi 1\b' scripts 42_pipeline_checklist.sh \
  | while read -r f; do
    sed -i 's/\bexi 1\b/exit 1/g' "$f"
    echo " - $f"
  done || true

echo "[3/5] Inserindo ';' ausente antes de 'exit 1' em strings detectadas…"
# Caso específico visto no grep: …"Tests falharam" exit 1; fi
# Tornamos …"Tests falharam"; exit 1; fi
perl -0777 -pe 's/("Tests falharam")\s+exit 1;/\1; exit 1;/g' -i scripts/hardening_checklist_and_audit.sh 2>/dev/null || true

echo "[4/5] Ampliando traps para não matar shell e capturar sinais…"
# padroniza 'trap cleanup EXIT' -> 'trap cleanup EXIT INT TERM' quando não há INT/TERM
grep -RIl --include='*.sh' -E 'trap[[:space:]]+cleanup[[:space:]]+EXIT(?![[:space:]]+INT[[:space:]]+TERM)' scripts 42_pipeline_checklist.sh \
  | while read -r f; do
    sed -i -E 's/(trap[[:space:]]+cleanup[[:space:]]+)EXIT(?![[:space:]]+INT[[:space:]]+TERM)/\1EXIT INT TERM/' "$f"
    echo " - $f"
  done || true

echo "[5/5] Garantindo cabeçalho seguro e não-fork-bomb…"
for f in 42_pipeline_checklist.sh scripts/run_full_pipeline_and_commit.sh; do
  [ -f "$f" ] || continue
  # injeta set -euo pipefail se não existir
  grep -q 'set -euo pipefail' "$f" || sed -i '1s|^|set -euo pipefail\n|' "$f"
  # garante que não será 'sourced' por engano: aborta se estiver sendo sourceado
  grep -q 'BASH_SOURCE' "$f" || sed -i '2i [[ "${BASH_SOURCE[0]}" != "$0" ]] && { echo "[erro] não faça source: execute ./'"$f"'"; return 1 2>/dev/null || exit 1; }' "$f"
  echo " - header sane in $f"
done

echo "[ok] Hardening aplicado."
