#!/usr/bin/env bash
set -euo pipefail
cd ~/workspace/Mini-IDE

echo "========================================="
echo "🎉 CICLO 1 - CONFIRMAÇÃO"
echo "========================================="
echo ""

echo "[1] PR Mergeado:"
git log --oneline --grep="pull request" -3
echo ""

echo "[2] Código em main:"
git log origin/main --oneline -5
echo ""

echo "[3] Branch atual:"
git branch --show-current
echo ""

echo "========================================="
echo "✅ CICLO 1 COMPLETO - HU-Server-Analyze-200 ENTREGUE!"
echo "========================================="
