#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REPO="${REPO:-PrinceOfEgypt1/Mini-IDE}"
VER="v1.0.16"
ISSUE_ROADMAP="${ISSUE_ROADMAP:-6}"   # ajuste se o roadmap da 1.0.16 for outra issue
RUN_LOCAL_CHECKS="${RUN_LOCAL_CHECKS:-0}"

echo "== (1) Release $VER publicada e acessível =="
gh release view "$VER" --repo "$REPO" --json tagName,name,publishedAt,url \
  --jq '.tagName+" "+.name+" "+.publishedAt+" "+.url'

echo "== (2) Milestone $VER fechada =="
gh api "repos/$REPO/milestones?state=all" \
  --jq '.[]|select(.title=="'"$VER"'")|"\(.title)\t\(.state)"'

echo "== (3) PRs abertos: nenhum =="
gh pr list --repo "$REPO" --state open

echo "== (4) Issue #$ISSUE_ROADMAP (Roadmap): CLOSED + milestone $VER =="
gh issue view "$ISSUE_ROADMAP" --repo "$REPO" \
  --json number,state,milestone,labels,url \
  --jq '"#\(.number) \(.state) ms=\(.milestone.title // "") labels=\([.labels[].name]|join(",")) url=\(.url)"'

echo "== (5) Discussion (Announcements) da "Mini-IDE '"$VER"' — pipeline verde" =="
# Lista discussões de Announcements contendo o título da versão
gh api "repos/$REPO/discussions?per_page=100" \
  --jq '.[] | select(.category.name=="Announcements") |
        select(.title=="Mini-IDE '"$VER"' — pipeline verde") |
        "\(.number)\t\(.title)\t\(.html_url)"' || true

# Escolhe a menor (canônica) se houver duplicatas
CANON_DISC="$(gh api "repos/$REPO/discussions?per_page=100" \
  --jq '[.[] | select(.category.name=="Announcements") |
               select(.title=="Mini-IDE '"$VER"' — pipeline verde") |
               .number] | min // empty')"

if [[ -n "${CANON_DISC:-}" ]]; then
  DISC_URL="https://github.com/$REPO/discussions/$CANON_DISC"
  echo "[ok] Canônica: #$CANON_DISC -> $DISC_URL"
else
  echo "[warn] Nenhuma Discussion encontrada para '"$VER"'."
fi

echo "== (6) README contém um ÚNICO link para a Discussion canônica =="
if [[ -n "${CANON_DISC:-}" ]]; then
  # conta ocorrências totais do título e do id da discussão
  CNT_TITLE="$(grep -cE "Mini-IDE $VER — pipeline verde" README.md || true)"
  CNT_ID="$(grep -c "discussions/$CANON_DISC" README.md || true)"
  echo "Ocorrências do título no README: $CNT_TITLE"
  echo "Ocorrências da #$CANON_DISC no README: $CNT_ID"
  if [[ "${CNT_TITLE:-0}" -eq 1 && "${CNT_ID:-0}" -eq 1 ]]; then
    echo "[ok] README aponta somente para a canônica."
  else
    echo "[warn] README não está canônico (esperado 1/1)."
  fi
else
  echo "[skip] Sem canônica detectada; não dá pra validar README."
fi

if [[ "$RUN_LOCAL_CHECKS" == "1" ]]; then
  echo "== (7) Pipeline local: build, typecheck, lint, test (verde em todos os pacotes) =="
  pnpm -r run build && pnpm -r run typecheck && pnpm -r run lint && pnpm -r run test
else
  echo "[info] Pipeline local pulada (defina RUN_LOCAL_CHECKS=1 para rodar)."
fi
