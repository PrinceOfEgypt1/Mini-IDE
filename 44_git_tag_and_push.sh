# 44_git_tag_and_push.sh
# Diretório de execução: ~/workspace/Mini-IDE
set -euo pipefail
cd "$HOME/workspace/Mini-IDE"
git add -A
git commit -m "chore: pipeline green (build/typecheck/lint/test/docs) + smoke" || true
git tag -a v1.0.12 -m "Mini-IDE v1.0.12 (pipeline green)"
git push -u origin main
git push origin v1.0.12
echo "[ok] main e tag v1.0.12 publicados"
