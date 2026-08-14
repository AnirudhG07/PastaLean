"""Parent-side orchestration: run every gate over a unit and fold the verdicts into one report."""

from __future__ import annotations

import concurrent.futures
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from .static_gates import behaviour_delta, static_check
from .unit import discover_units, load_unit

_TRANSPILE_DIR = Path(__file__).resolve().parent.parent
_SENTINEL = "__CQA_JSON__"


def _run_child(job: dict, wall_timeout: float, python: str | None = None) -> dict:
    env = dict(os.environ)
    env["PYTHONPATH"] = os.pathsep.join(
        [str(_TRANSPILE_DIR), *([env["PYTHONPATH"]] if env.get("PYTHONPATH") else [])])
    env.setdefault("PYTHONHASHSEED", "0")
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
        json.dump(job, fh)
        job_path = fh.name
    try:
        proc = subprocess.run(  # noqa: S603
            [python or sys.executable, "-m", "contract_qa.runner", job_path],
            capture_output=True, text=True, env=env, timeout=wall_timeout, check=False)
    except subprocess.TimeoutExpired:
        return {"error": f"execution gates timed out after {wall_timeout}s "
                         "(a mutant or the program itself does not terminate)"}
    finally:
        Path(job_path).unlink(missing_ok=True)
    if _SENTINEL in proc.stdout:
        try:
            return json.loads(proc.stdout.split(_SENTINEL, 1)[1])
        except json.JSONDecodeError:
            pass
    tail = (proc.stderr or proc.stdout or "").strip().splitlines()[-3:]
    return {"error": f"runner produced no verdict (exit {proc.returncode}): {' / '.join(tail)}"}


def check_unit(unit_dir: str | Path, source: str | None = None, *, mutants: int = 30,
               test_limit: int = 50, mutation_tests: int = 12, seed: int = 0,
               wall_timeout: float = 300.0, contracts_name: str = "solution_contracts.py",
               python: str | None = None) -> dict:
    """Run every deterministic gate over one unit. `source` overrides the on-disk contracts file
    (that is how the repair loop grades a candidate without writing it anywhere)."""
    unit = load_unit(unit_dir, contracts_name)
    src = source if source is not None else unit.contracts_source()
    report: dict = {"module": unit.module, "unit_dir": str(unit.dir), "status": "fail",
                    "diagnostics": []}
    if src is None:
        report["diagnostics"].append(f"no {contracts_name} in {unit.dir}")
        report["status"] = "missing"
        return report

    static = static_check(src, entry=unit.method)
    static.findings.extend(behaviour_delta(unit.reference, src))
    report["static"] = static.as_dict()
    report["diagnostics"].extend(str(f) for f in static.findings)

    if any(f.kind == "syntax" for f in static.findings):
        return report

    job = {"unit_dir": str(unit.dir), "source": src, "contracts_name": contracts_name,
           "mutants": mutants, "test_limit": test_limit, "mutation_tests": mutation_tests,
           "seed": seed}
    child = _run_child(job, wall_timeout, python)
    if "error" in child:
        report["dynamic"] = {"ok": False, "problems": [child["error"]]}
        report["diagnostics"].append(child["error"])
        return report

    report["dynamic"] = child.get("dynamic", {})
    report["n_tests"] = child.get("n_tests", 0)
    report["diagnostics"].extend(report["dynamic"].get("problems", []))
    if "mutation" in child:
        report["mutation"] = child["mutation"]

    report["status"] = "pass" if (static.ok and report["dynamic"].get("ok")) else "fail"
    return report


def mutation_score(report: dict) -> float | None:
    return (report.get("mutation") or {}).get("score")


def summarize(report: dict) -> str:
    """One line per unit, in the shape of PALC's verdict lines."""
    mut = report.get("mutation") or {}
    score = mut.get("score")
    dyn = report.get("dynamic") or {}
    static = report.get("static") or {}
    bits = [
        f"{report['status'].upper():7}",
        f"{dyn.get('n_ok', 0):>3}/{dyn.get('n_tests', 0):<3} tests",
        f"E{static.get('substantive_ensures', 0)}",
        (f"mut {score:.2f} ({mut.get('killed', 0)}/{mut.get('effective', 0)})"
         if score is not None else "mut   -- "),
        f"W{len([f for f in static.get('findings', []) if f['severity'] == 'warn'])}",
        report["module"],
    ]
    return "  ".join(bits)


def qa_units(root: str | Path, only: list[str] | None = None, *, workers: int = 4,
             **kwargs) -> list[dict]:
    """Check every unit under `root`, in parallel (each check is its own subprocess anyway)."""
    dirs = discover_units(root, only)
    reports: list[dict] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(check_unit, d, **kwargs): d for d in dirs}
        for fut in concurrent.futures.as_completed(futures):
            d = futures[fut]
            try:
                reports.append(fut.result())
            except Exception as exc:  # noqa: BLE001
                reports.append({"module": d.name, "unit_dir": str(d), "status": "fail",
                                "diagnostics": [f"harness error: {type(exc).__name__}: {exc}"]})
    reports.sort(key=lambda r: r["module"])
    return reports


def aggregate(reports: list[dict]) -> dict:
    scores = [mutation_score(r) for r in reports]
    scored = [s for s in scores if s is not None]
    by_status: dict[str, int] = {}
    for r in reports:
        by_status[r["status"]] = by_status.get(r["status"], 0) + 1
    kinds: dict[str, int] = {}
    for r in reports:
        for f in (r.get("static") or {}).get("findings", []):
            if f["severity"] == "error":
                kinds[f["kind"]] = kinds.get(f["kind"], 0) + 1
    return {
        "units": len(reports),
        "status": by_status,
        "llm_calls": sum(r.get("llm_calls", 0) for r in reports),
        "static_error_kinds": kinds,
        "mutation": {
            "scored_units": len(scored),
            "mean_score": (sum(scored) / len(scored)) if scored else None,
            "vacuous_units": sum(1 for s in scored if s == 0.0),
            "perfect_units": sum(1 for s in scored if s == 1.0),
        },
    }
