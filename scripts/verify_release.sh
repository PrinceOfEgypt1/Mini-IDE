#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REPO="${REPO:-PrinceOfEgypt1/Mini-IDE}"
VER="${1:?Uso: ./scripts/verify_release.sh vX.Y.Z}"
ISSUE_ROADMAP="${ISSUE_ROADMAP:-6}"
RUN_LOCAL_CHECKS="${RUN_LOCAL_CHECKS:-0}"

echo "== Release =="
gh release view "$VER" --repo "$REPO" --json tagName,name,publishedAt,url \
  --jq '.tagName+" "+.name+" "+.publishedAt+" "+.url'

echo "== Milestones (all) =="
gh api "repos/$REPO/milestones?state=all" --jq '.[]|"\(.title)\t\(.state)"'

echo "== PRs abertos =="
gh pr list --repo "$REPO" --state open

echo "== Issue #$ISSUE_ROADMAP =="
gh issue view "$ISSUE_ROADMAP" --repo "$REPO" --json number,state,milestone,labels,url \
  --jq '"#\(.number) \(.state) ms=\(.milestone.title // "") labels=\([.labels[].name]|join(",")) url=\(.url)"'

echo "== Discussions (Announcements) =="
gh api "repos/$REPO/discussions?per_page=50" \
  --jq '.[] | select(.category.name=="Announcements") | "\(.number)\t\(.title)\t\(.html_url)"' \
  | grep -E "$VER|Announcements|Welcome" || true

echo "== README contém link da discussion? =="
grep -nE "Mini-IDE $VER — pipeline verde" README.md || echo "[warn] link não encontrado"

if [ "$RUN_LOCAL_CHECKS" = "1" ]; then
  echo "== Pipeline local (build/typecheck/lint/test) =="
  pnpm run checklist
else
  echo "[info] Pipeline local pulada (RUN_LOCAL_CHECKS=0)."
fi
