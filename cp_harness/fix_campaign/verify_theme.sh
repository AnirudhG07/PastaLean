#!/bin/bash
# Compile-check the campaign problems of one or more themes, one fresh backend per file
# (reliable, unlike the warm-Session convert whose backend can go stale mid-run).
#
#   ./verify_theme.sh "T6 option-field-proj" "T10 counter-methods"
#   ./verify_theme.sh --problems foo-bar baz-qux
#
# Prints "PASS <problem>" / "FAIL <problem>" per solution and a tally.
set -u
cd "$(dirname "$0")/../.." || exit 1

if [ "${1:-}" = "--problems" ]; then
  shift; PROBS=("$@")
else
  mapfile -t PROBS < <(python3 -c "
import json,sys
t=json.load(open('cp_harness/fix_campaign/themes.json'))
for k in sys.argv[1:]:
    for p in t[k]['problems']: print(p)
" "$@")
fi

pass=0; fail=0
for P in "${PROBS[@]}"; do
  f="cp_harness/dataset_leetcode/$P/solutions/sol_0.py"
  [ -f "$f" ] || { echo "MISS $P"; continue; }
  if uv run pastalean translate "$f" 2>&1 | grep -qE "^ok: "; then
    echo "PASS $P"; pass=$((pass+1))
  else
    echo "FAIL $P"; fail=$((fail+1))
  fi
done
echo "== $pass PASS / $fail FAIL =="
