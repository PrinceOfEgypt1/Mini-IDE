#!/usr/bin/env bash
set -euo pipefail
cd ~/workspace/Mini-IDE

echo "========================================="
echo "DIAGNÓSTICO - Branches"
echo "========================================="
echo ""

echo "[1] Branch atual:"
git branch --show-current
echo ""

echo "[2] Branches locais:"
git branch -a
echo ""

echo "[3] Últimos commits:"
git log --oneline -10
echo ""

echo "[4] Verificar remote:"
git remote -v
echo ""

echo "[5] Fetch do remote:"
git fetch origin
echo ""

echo "[6] Comparar branches:"
git log origin/main..origin/fix/pipeline-validate-analyze --oneline || echo "Erro ao comparar"
echo ""

echo "========================================="
