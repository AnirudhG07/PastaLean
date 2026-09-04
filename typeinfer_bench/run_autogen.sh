#!/usr/bin/env bash
# Run the TypeInfer benchmark over TypeEvalPy's FULL autogen set (~5.4k snippets, ~46k type facts) —
# the same large benchmark behind the GitHub leaderboard's absolute exact-match counts.
#
# Boots ONE warm Lean backend and runs only the `inferTypes` task per snippet (no codegen / no
# `lake env lean` compilation), so the whole set finishes in ~10-15 min, not hours.
#
#   bash typeinfer_bench/run_autogen.sh [/path/to/TypeEvalPy]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TEP="${1:-/tmp/TypeEvalPy}"
BENCH="$TEP/autogen_typeevalpy_benchmark/python_features"
if [ ! -d "$BENCH" ]; then
  echo "autogen benchmark not found at $BENCH"
  echo "clone it first:  git clone --depth 1 https://github.com/secure-software-engineering/TypeEvalPy $TEP"
  exit 1
fi

echo "[*] Running autogen benchmark under $BENCH"
uv run python typeinfer_bench/typeinfer_eval.py \
  --bench "$BENCH" \
  --out typeinfer_bench/autogen_summary.json \
  2>&1 | grep -vE "warning:|Warning:|HF_TOKEN|best-effort|^  unsupported" \
  | tee typeinfer_bench/autogen_typeinfer.log
