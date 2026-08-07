"""The generate → verify → repair loop.

Invariant: **a file that fails a gate is never written.** The loop keeps the best candidate it has
seen; if no candidate passes, the on-disk contracts are left exactly as they were and the unit is
reported as failing. That is the whole point — the previous one-shot generator shipped whatever the
model returned as long as it parsed.

Repair is execution-guided: the model is handed the *specific* diagnostic (the failing input, the
false clause, the unbound name, the wrong implementation its spec accepted), not a generic "try
again". This is the Reflexion / self-debugging pattern, with the reflection produced by a verifier
rather than by the model itself.
"""

from __future__ import annotations

import json
from pathlib import Path

from .harness import check_unit, mutation_score
from .llm_io import Generator, no_critic
from .unit import load_unit


def _rank(report: dict) -> tuple:
    """Higher is better. Passing beats failing; then mutation score; then spec strength."""
    passing = report.get("status") == "pass"
    score = mutation_score(report)
    static = report.get("static") or {}
    return (
        1 if passing else 0,
        score if score is not None else -1.0,
        static.get("substantive_ensures", 0),
        -len([f for f in static.get("findings", []) if f["severity"] == "warn"]),
    )


def feedback_from(report: dict, min_mutation_score: float | None) -> list[str]:
    """The verifier's findings, in the order that matters for a rewrite: things that are WRONG
    first, then things that are merely WEAK."""
    out: list[str] = []
    static = report.get("static") or {}
    for f in static.get("findings", []):
        if f["severity"] == "error":
            out.append(str_finding(f))
    for p in (report.get("dynamic") or {}).get("problems", []):
        out.append(f"[error:runtime] {p}")
    mut = report.get("mutation") or {}
    score = mut.get("score")
    if score is not None and min_mutation_score is not None and score < min_mutation_score:
        out.append(
            f"[error:vacuity] mutation score {score:.2f} — your specification accepted "
            f"{mut.get('survived', 0)} of {mut.get('effective', 0)} deliberately-broken variants of "
            "this implementation. It is true but too weak to distinguish right from wrong.")
    for s in mut.get("survivors", []):
        out.append(f"[error:vacuity] a broken variant your contracts ACCEPTED — "
                   f"{s['description']} (line {s['line']}) {s['evidence']}")
    for f in static.get("findings", []):
        if f["severity"] == "warn":
            out.append(str_finding(f))
    return out


def str_finding(f: dict) -> str:
    loc = f"line {f['line']}" + (f" in {f['where']}()" if f.get("where") else "")
    return f"[{f['severity']}:{f['kind']}] {loc}: {f['message']}"


def repair_unit(unit_dir: str | Path, *, generator: Generator | None = None, attempts: int = 2,
                min_mutation_score: float | None = None, critic=no_critic,
                out_dir: str | Path | None = None, in_place: bool = False,
                contracts_name: str = "solution_contracts.py", **check_kwargs) -> dict:
    """Verify a unit's contracts and, on failure, regenerate them with the diagnostic fed back.

    `attempts` counts REGENERATIONS, so `attempts=0` is a pure verification pass. Nothing is written
    unless the winning candidate passes every hard gate.
    """
    unit = load_unit(unit_dir, contracts_name)
    history: list[dict] = []
    current = unit.contracts_source()
    best_report: dict | None = None
    best_source: str | None = None
    llm_calls = 0

    if current is not None:
        report = check_unit(unit.dir, current, contracts_name=contracts_name, **check_kwargs)
        report["attempt"] = 0
        report["origin"] = "existing"
        history.append(report)
        best_report, best_source = report, current

    for attempt in range(1, attempts + 1):
        good_enough = (best_report is not None and best_report["status"] == "pass"
                       and (min_mutation_score is None
                            or (mutation_score(best_report) or 0.0) >= min_mutation_score))
        if good_enough:
            break
        if generator is None:
            break
        prev = best_source if best_report is not None else None
        fb = feedback_from(best_report, min_mutation_score) if best_report is not None else []
        if best_report is not None and critic is not no_critic and prev:
            llm_calls += 1
            try:
                advice = critic(unit, prev)
            except Exception as exc:  # noqa: BLE001  (advisory only; never blocks)
                advice = {"error": f"{type(exc).__name__}: {exc}"}
            if advice.get("missing_property"):
                fb.append(f"[advisory:critic] the reviewer says the missing property is: "
                          f"{advice['missing_property']}")
            best_report.setdefault("critic", advice)
        llm_calls += 1
        try:
            candidate = generator(unit, prev, fb)
        except Exception as exc:  # noqa: BLE001
            history.append({"attempt": attempt, "status": "fail",
                            "diagnostics": [f"generator failed: {type(exc).__name__}: {exc}"]})
            break
        report = check_unit(unit.dir, candidate, contracts_name=contracts_name, **check_kwargs)
        report["attempt"] = attempt
        report["origin"] = "regenerated"
        history.append(report)
        if best_report is None or _rank(report) > _rank(best_report):
            best_report, best_source = report, candidate

    result = dict(best_report or {"module": unit.module, "status": "missing", "diagnostics": []})
    result["attempts"] = len(history)
    result["llm_calls"] = llm_calls
    result["history"] = [{"attempt": h.get("attempt"), "status": h.get("status"),
                          "score": mutation_score(h), "origin": h.get("origin")} for h in history]

    wrote = None
    if best_source is not None and result.get("status") == "pass" and best_source != current:
        target = (unit.contracts_path if in_place
                  else Path(out_dir or unit.dir.parent / "_contract_qa") / f"{unit.module}.contracts.py")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(best_source)
        wrote = str(target)
    result["written"] = wrote
    return result


def write_report(reports: list[dict], path: str | Path) -> None:
    from .harness import aggregate

    Path(path).write_text(json.dumps({"summary": aggregate(reports), "units": reports}, indent=2) + "\n")
