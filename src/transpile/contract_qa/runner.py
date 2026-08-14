"""Child-process entry point for the execution gates.

Run as `python -m contract_qa.runner <job.json>` (with `src/transpile` on `PYTHONPATH`) or
`python -m pastalean.transpile.contract_qa.runner <job.json>`. It prints one JSON object on stdout.

A separate process is not paranoia: mutants loop forever, allocate without bound, and leave junk in
`sys.modules`. The parent kills the child on a wall-clock timeout; an address-space rlimit keeps a
runaway mutant from swapping the machine.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

if __package__ in (None, ""):  # executed as a plain script path
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    __package__ = "contract_qa"  # noqa: A001

from .dynamic import build_oracle, install_alarm, score_mutants, verify  # noqa: E402
from .mutation import generate_mutants, sample  # noqa: E402
from .unit import load_unit  # noqa: E402


def _limit_memory(mb: int) -> None:
    try:
        import resource

        soft, hard = resource.getrlimit(resource.RLIMIT_AS)
        cap = mb * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (cap, hard if hard == resource.RLIM_INFINITY else min(cap, hard)))
    except Exception:  # noqa: BLE001  (unsupported on some platforms; the wall clock still applies)
        pass


def run_job(job: dict) -> dict:
    unit = load_unit(job["unit_dir"], job.get("contracts_name", "solution_contracts.py"))
    source = job.get("source")
    if source is None:
        source = unit.contracts_source()
    if source is None:
        return {"module": unit.module, "error": "no contracts file"}

    entry = unit.method
    tests = unit.tests[: job.get("test_limit", 50)]
    call_timeout = job.get("call_timeout", 10.0)
    oracle = build_oracle(unit.reference, entry, tests, call_timeout)
    if oracle.error:
        return {"module": unit.module, "error": f"reference solution.py failed to load: {oracle.error}"}

    out: dict = {"module": unit.module, "entry": entry,
                 "reference_usable": len(oracle.usable), "n_tests": len(tests)}
    out["dynamic"] = verify(source, entry, oracle, tests, timeout=call_timeout)

    n_mutants = job.get("mutants", 30)
    if n_mutants and out["dynamic"]["ok"]:
        constant = None
        if oracle.usable:
            first = oracle.usable[0]
            constant = repr(oracle.values[first])
        muts = sample(generate_mutants(source, entry, constant), n_mutants, job.get("seed", 0))
        out["mutation"] = score_mutants(muts, entry, oracle, tests,
                                        timeout=job.get("mutant_timeout", 2.0),
                                        test_budget=job.get("mutation_tests", 12))
    return out


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv:
        print(json.dumps({"error": "usage: runner.py <job.json>"}))
        return 2
    job = json.loads(Path(argv[0]).read_text())
    _limit_memory(job.get("memory_mb", 3072))
    install_alarm()
    try:
        result = run_job(job)
    except Exception as exc:  # noqa: BLE001  (a crashed child must still produce a verdict)
        import traceback

        result = {"error": f"runner crashed: {type(exc).__name__}: {exc}",
                  "traceback": traceback.format_exc(limit=5)}
    sys.stdout.write("\n__CQA_JSON__\n" + json.dumps(result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
