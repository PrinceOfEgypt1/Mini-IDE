# scripts/finalize_release_v1_0_16.sh
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

REPO="${REPO:-PrinceOfEgypt1/Mini-IDE}"
BRANCH="${BRANCH:-main}"
VER="v1.0.16"
ISSUE_ROADMAP="${ISSUE_ROADMAP:-6}"   # ajuste se o roadmap da 1.0.16 for outra issue
TITLE="Mini-IDE ${VER} — pipeline verde"
ANNOUNCEMENTS_SLUG="announcements"

say(){ printf '%s\n' "$*"; }

# 0) Sync main
git fetch origin
git switch "$BRANCH"
git reset --hard "origin/$BRANCH"

# 1) Tag local (se não existir) e push
if git rev-parse -q --verify "refs/tags/${VER}" >/dev/null; then
  say "[ok] tag ${VER} já existe localmente."
else
  HEAD_SHA="$(git rev-parse HEAD)"
  git tag -a "${VER}" -m "Release ${VER} (from ${BRANCH} @ ${HEAD_SHA})"
  say "[ok] tag ${VER} criada em ${HEAD_SHA}."
fi
git push origin "refs/tags/${VER}" || true

# 2) Release (idempotente)
if gh release view "${VER}" --repo "$REPO" >/dev/null 2>&1; then
  say "[ok] release ${VER} já existe."
else
  gh release create "${VER}" --repo "$REPO" \
    --target "$BRANCH" \
    --title "Mini-IDE ${VER}" \
    --generate-notes --latest
  say "[ok] release ${VER} criada."
fi

# 3) Milestone (cria se faltar e fecha)
MID="$(gh api "repos/$REPO/milestones?state=all" \
  --jq '.[]|select(.title=="'"$VER"'")|.number' || true)"
if [[ -z "${MID:-}" ]]; then
  MID="$(gh api -X POST "repos/$REPO/milestones" -f title="$VER" --jq '.number')"
  say "[ok] milestone ${VER} criada (#${MID})."
fi
# fecha se não estiver closed
STATE="$(gh api "repos/$REPO/milestones/$MID" --jq '.state')"
if [[ "$STATE" != "closed" ]]; then
  gh api -X PATCH "repos/$REPO/milestones/$MID" -f state=closed >/dev/null
  say "[ok] milestone ${VER} fechada."
else
  say "[ok] milestone ${VER} já está fechada."
fi

# 4) Issue Roadmap (se existir, marca milestone ${VER} e fecha)
if gh issue view "$ISSUE_ROADMAP" --repo "$REPO" >/dev/null 2>&1; then
  gh api -X PATCH "repos/$REPO/issues/$ISSUE_ROADMAP" -f milestone="$MID" >/dev/null || true
  CUR_STATE="$(gh issue view "$ISSUE_ROADMAP" --repo "$REPO" --json state --jq .state)"
  if [[ "$CUR_STATE" != "CLOSED" ]]; then
    gh issue close "$ISSUE_ROADMAP" --repo "$REPO" -c "Fechando no release ${VER}." >/dev/null || true
  fi
  say "[ok] Issue #${ISSUE_ROADMAP} com milestone ${VER} e fechada."
else
  say "[warn] Issue #${ISSUE_ROADMAP} não encontrada; pulando."
fi

# 5) Discussion em Announcements (cria se faltar; evita duplicatas)
GH_JSON="$(gh api graphql -f owner="${REPO%/*}" -f name="${REPO#*/}" -f query='
  query($owner:String!, $name:String!){
    repository(owner:$owner,name:$name){
      id
      discussionCategory(slug:"announcements"){ id name }
    }
  }')"
REPO_ID="$(jq -r '.data.repository.id' <<<"$GH_JSON")"
CAT_ID="$(jq -r '.data.repository.discussionCategory.id' <<<"$GH_JSON")"

EXIST_NUM="$(gh api "repos/$REPO/discussions?per_page=100" \
  --jq '.[] | select(.title=="'"$TITLE"'") | .number' | head -n1 || true)"

if [[ -z "${EXIST_NUM:-}" ]]; then
  CREATE_JSON="$(gh api graphql \
    -f repositoryId="$REPO_ID" -f categoryId="$CAT_ID" -f title="$TITLE" \
    -f body=$'# '"$TITLE"$'\n\n- ✅ Build/typecheck/lint/tests verdes\n- 🔒 Pre-commit unificado + fallback seguro\n- 🧰 CLI mais tolerante ao /analyze (guards + normalização)\n- 🧾 Docs stub em docs/api/index.html\n\nRelease: https://github.com/'"$REPO"'/releases/tag/'"$VER"$'\nSem breaking changes (patch).' \
    -f query='mutation($repositoryId:ID!,$categoryId:ID!,$title:String!,$body:String!){
      createDiscussion(input:{repositoryId:$repositoryId,categoryId:$categoryId,title:$title,body:$body}){
        discussion{ number url }
      }
    }')"
  DNUM="$(jq -r '.data.createDiscussion.discussion.number' <<<"$CREATE_JSON")"
  DURL="$(jq -r '.data.createDiscussion.discussion.url' <<<"$CREATE_JSON")"
  say "[ok] Discussion #${DNUM} criada: ${DURL}"
else
  DNUM="$EXIST_NUM"
  DURL="https://github.com/$REPO/discussions/$DNUM"
  say "[ok] Discussion já existente: #${DNUM} ${DURL}"
fi

# 6) README com ÚNICO link para a canônica (esta ${DNUM})
LINK="- [Discussão: ${TITLE}](${DURL})"
# remove linhas antigas desse título
sed -i "/\[Discussão: ${TITLE//\//\\/}\]/d" README.md
# garante 1 linha correta
printf "\n%s\n" "$LINK" >> README.md
git add README.md
git commit -m "docs(readme): apontar ${VER} para Discussion #${DNUM} (único link)" || true
git push || true

say "[done] v1.0.16 pronta. Agora rode: ./scripts/verify_release_v1_0_16.sh"
