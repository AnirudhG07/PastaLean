#!/usr/bin/env bash
# Overnight: generate contracts + Lean code for all ingested HumanEval+ problems, then compile-check.
#
# The API key is read automatically from `.env` (llm.py calls load_dotenv()). This repo's `.env`
# has GEMINI_API_KEY, so the default provider here is `Gemini` — the same one used for leetcode.
# To use another provider, put its key in `.env` and run with `PROVIDER=OpenAI` (etc.).
#
# Do NOT run any other `lake build` / `cpasta_eval` while this runs — regen uses a warm Lean
# backend and a concurrent build corrupts its oleans.

set -euo pipefail
cd /home/anirudhgupta/PyAstLean
source .venv/bin/activate

PROVIDER="${PROVIDER:-Gemini}"
log() { echo "[$(date '+%H:%M:%S')] $*"; }

HE_MODS=$(ls PastaBench/humaneval | grep -v '^manifest.json$')
N=$(echo "$HE_MODS" | wc -w)

# 1) CONTRACTS — LLM writes solution_contracts.py per problem. Resumable: already-annotated ones
#    are skipped, so re-running after an interruption costs nothing.
log "[1/3] Generating contracts for $N HumanEval+ problems (provider=$PROVIDER, 8 workers) ..."
# python3 PastaBench/pastabench.py contracts --track humaneval --provider "$PROVIDER" --workers 8

# 2) REGEN — translate the (now contract-annotated) solutions -> Generated.lean. HumanEval+ only.
log "[2/3] Regenerating Lean for $N problems ..."
# python3 PastaBench/pastabench.py regen --only $HE_MODS 2>&1 | tee PastaBench/humaneval_regen.log

# 3) COMPILE-CHECK — build every generated module. `sorry` = spec unproved (fine); `error` = the
#    translation doesn't elaborate (a convert/compile failure to look at).
HE_TARGETS=$(for m in $HE_MODS; do [ "$m" = "README.md" ] && continue; echo "PastaBench.humaneval.$m.Proofs"; done)
log "[3/3] Compile-checking ..."
lake build $HE_TARGETS 2>&1 | tee PastaBench/humaneval_build.log | tail -8 || true

# Tally.
log "Done. Tally:"
python3 - "$@" <<'PY'
import re, pathlib
log = pathlib.Path("PastaBench/humaneval_build.log").read_text()
errs = set(re.findall(r"PastaBench/humaneval/([^/]+)/(?:Generated|Proofs)\.lean:\d+:\d+: (?!declaration uses)", log))
sorries = set(re.findall(r"PastaBench/humaneval/([^/]+)/Generated\.lean:\d+:\d+: declaration uses `sorry`", log))
he = [d.name for d in pathlib.Path("PastaBench/humaneval").iterdir() if (d/"Generated.lean").exists()]
contracted = [d.name for d in pathlib.Path("PastaBench/humaneval").iterdir() if (d/"solution_contracts.py").exists()]
clean = [m for m in he if m not in errs]
print(f"  contracts written : {len(contracted)}/{len(he)}")
print(f"  compiles clean    : {len(clean)}/{len(he)}   (errored: {len(errs)})")
print(f"  spec has sorry    : {len(sorries)}  (unproved but compiling)")
PY
echo "Logs: PastaBench/humaneval_regen.log, PastaBench/humaneval_build.log, PastaBench/contracts_summary.json"
