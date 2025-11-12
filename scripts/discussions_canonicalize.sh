#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-PrinceOfEgypt1/Mini-IDE}"   # owner/repo
OWNER="${REPO%/*}"
NAME="${REPO#*/}"
CANON="${CANON:-8}"                       # discussão canônica
read -r -a DUPS_ARR <<< "${DUPS:-9 10 11}"
MSG="${MSG:-Consolidado na discussão #$CANON. Use: https://github.com/$REPO/discussions/$CANON}"

echo "[i] Repositório: $REPO"
echo "[i] Canônica:    #$CANON"
echo "[i] Duplicatas:  ${DUPS_ARR[*]}"

gid() {
  local num="$1"
  gh api graphql \
    -F owner="$OWNER" -F name="$NAME" -F number="$num" \
    -f query='query($owner:String!,$name:String!,$number:Int!){
      repository(owner:$owner,name:$name){
        discussion(number:$number){ id locked url title number }
      }
    }' --jq '.data.repository.discussion.id'
}

# 1) Comentar nas duplicatas (GraphQL) – idempotente o bastante
for N in "${DUPS_ARR[@]}"; do
  DID="$(gid "$N")" || { echo "[warn] não achei discussion #$N"; continue; }
  echo "[i] Comentando na #$N…"
  gh api graphql \
    -F discussionId="$DID" -F body="$MSG" \
    -f query='mutation($discussionId:ID!,$body:String!){
      addDiscussionComment(input:{discussionId:$discussionId, body:$body}){ comment { url } }
    }' >/dev/null || true
done

# 2) Lock nas duplicatas (REST) – SEM reason (a API não aceita reason para discussions)
for N in "${DUPS_ARR[@]}"; do
  echo "[i] Bloqueando (lock) a #$N…"
  gh api -H "Accept: application/vnd.github+json" \
    -X PUT "repos/$REPO/discussions/$N/lock" >/dev/null || true
done

# 3) Revalidação
echo "[i] Estados finais:"
for N in "$CANON" "${DUPS_ARR[@]}"; do
  gh api -H "Accept: application/vnd.github+json" \
    "repos/$REPO/discussions/$N" --jq '.number, .locked'
done

echo "[ok] Discussões consolidadas."
