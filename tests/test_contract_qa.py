#!/usr/bin/env python3
"""Tests for the contract QA gates — one per defect class found in shipped benchmark contracts.

Run: `.venv/bin/python tests/test_contract_qa.py` (no pytest needed, no API key needed).
"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src" / "transpile"))

from contract_qa.harness import check_unit  # noqa: E402
from contract_qa.llm_io import stub_generator  # noqa: E402
from contract_qa.pipeline import feedback_from, repair_unit  # noqa: E402
from contract_qa.mutation import generate_mutants, sample  # noqa: E402
from contract_qa.static_gates import behaviour_delta, static_check  # noqa: E402

FAILURES: list[str] = []


def expect_kind(name: str, source: str, kind: str, *, entry: str | None = None) -> None:
    rep = static_check(source, entry=entry)
    kinds = {f.kind for f in rep.findings if f.severity == "error"}
    if kind not in kinds:
        FAILURES.append(f"{name}: expected error kind {kind!r}, got {sorted(kinds)}")


def expect_clean(name: str, source: str, entry: str | None = None) -> None:
    rep = static_check(source, entry=entry)
    if rep.errors:
        FAILURES.append(f"{name}: expected no errors, got {[str(f) for f in rep.errors]}")


def expect_warn(name: str, source: str, kind: str) -> None:
    rep = static_check(source)
    kinds = {f.kind for f in rep.warnings}
    if kind not in kinds:
        FAILURES.append(f"{name}: expected warning kind {kind!r}, got {sorted(kinds)}")


PREAMBLE = "from contracts import *\n\n\n"

# -- static gates ------------------------------------------------------------------------------

expect_kind("forbidden Implies", PREAMBLE + """
def f(n: int) -> int:
    Ensures(Implies(n > 0, Result() > 0))
    return n
""", "forbidden")

expect_kind("forbidden Forall", PREAMBLE + """
def f(xs: list) -> int:
    Ensures(Forall(xs, lambda x: x > 0))
    return len(xs)
""", "forbidden")

expect_kind("forbidden Old", PREAMBLE + """
def f(n: int) -> int:
    Ensures(Result() == Old(n))
    return n
""", "forbidden")

# `Ensures` naming a local bound below it: UnboundLocalError on every call.
expect_kind("name bound below", PREAMBLE + """
def f(n: int) -> int:
    Ensures(Result() == total)
    total = n * 2
    return total
""", "scope")

# `import` below the contract is the same bug.
expect_kind("import below", PREAMBLE + """
def f(n: int) -> float:
    Ensures(Result() >= math.sqrt(n))
    import math
    return math.sqrt(n)
""", "scope")

expect_kind("Ensures on nested helper", PREAMBLE + """
def f(n: int) -> int:
    def helper(k: int) -> int:
        Ensures(Result() == k + 1)
        return k + 1
    return helper(n)
""", "nested_ensures")

expect_clean("Requires on nested helper is fine", PREAMBLE + """
def f(n: int) -> int:
    Ensures(2 * Result() == n * (n + 1))

    def helper(k: int) -> int:
        Requires(k >= 0)
        return k
    return helper(n) * (n + 1) // 2
""")

# A postcondition naming a loop-mutated variable: true in Python, unsatisfiable in Lean.
expect_kind("loop-mutated in postcondition", PREAMBLE + """
def f(x: int, base: int) -> str:
    Ensures(x == 0 or Result() != "")
    ret = ""
    while x > 0:
        ret = str(x % base) + ret
        x //= base
    return ret or "0"
""", "loop_mutated")

expect_clean("snapshot instead of the mutated name", PREAMBLE + """
def f(x: int, base: int) -> str:
    x_0 = x
    Ensures(x_0 == 0 or len(Result()) >= 1)
    ret = ""
    while x > 0:
        ret = str(x % base) + ret
        x //= base
    return ret or "0"
""")

expect_kind("Invariant outside a loop", PREAMBLE + """
def f(n: int) -> int:
    Ensures(Result() == n * 2)
    Invariant(n >= 0)
    return n * 2
""", "invariant_placement")

expect_kind("no substantive Ensures", PREAMBLE + """
def f(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() >= 0)
    return n * 2
""", "vacuous")

expect_kind("postcondition between two loops", PREAMBLE + """
def f(xs: list) -> int:
    s = 0
    for x in xs:
        s += x
    Ensures(Result() == s)
    for x in xs:
        s += x
    return s
""", "mid_function")

expect_kind("entry point missing", PREAMBLE + """
def f(n: int) -> int:
    Ensures(2 * Result() == n * (n + 1))
    return n * (n + 1) // 2
""", "entry", entry="g")

_dropped = behaviour_delta("def f():\n    pass\n\n\ndef g():\n    pass\n",
                           PREAMBLE + "def f():\n    Ensures(Result() == 1)\n    return 1\n")
if not any(d.kind == "dropped_defs" for d in _dropped):
    FAILURES.append("behaviour_delta: a dropped definition was not reported")

expect_warn("3-arg pow", PREAMBLE + """
def f(a: int, b: int, m: int) -> int:
    Ensures(Result() == pow(a, b, m))
    return pow(a, b, m)
""", "lowerability")

expect_warn("identity comparison", PREAMBLE + """
def f(x) -> bool:
    Ensures(Result() is True or Result() is False)
    Ensures(Result() == (x == 0))
    return x == 0
""", "lowerability")

expect_warn("multi-clause comprehension", PREAMBLE + """
def f(g: list) -> bool:
    Ensures(all(x <= y for row in g for x in row for y in row))
    Ensures(Result() == len(g))
    return len(g)
""", "lowerability")

expect_clean("nested single-generator comprehensions", PREAMBLE + """
def f(g: list) -> int:
    Ensures(all(all(x >= 0 for x in row) for row in g) or Result() >= 0)
    Ensures(Result() == len(g))
    return len(g)
""")

# -- mutation testing ---------------------------------------------------------------------------

STRONG = PREAMBLE + """
def total(n: int) -> int:
    Requires(n >= 0)
    Ensures(2 * Result() == n * (n - 1))
    s = 0
    for i in range(n):
        Invariant(0 <= i)
        Invariant(2 * s == i * (i - 1))
        s = s + i
    return s
"""

WEAK = PREAMBLE + """
def total(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() >= 0)
    Ensures(Result() >= n - 1)
    s = 0
    for i in range(n):
        s = s + i
    return s
"""

REFERENCE = """
def total(n: int) -> int:
    s = 0
    for i in range(n):
        s = s + i
    return s
"""


def _toy_unit(tmp: Path) -> Path:
    d = tmp / "Total"
    d.mkdir(parents=True)
    (d / "meta.json").write_text(json.dumps({"module": "Total", "method": "total"}))
    (d / "solution.py").write_text(REFERENCE)
    tests = [{"input": f"n = {k}", "output": str(sum(range(k)))} for k in range(0, 12)]
    (d / "tests.json").write_text(json.dumps(tests))
    return d


with tempfile.TemporaryDirectory() as td:
    unit = _toy_unit(Path(td))

    if not generate_mutants(STRONG, "total"):
        FAILURES.append("mutation: no mutants generated for the toy program")
    if len(sample(generate_mutants(STRONG, "total"), 5)) != 5:
        FAILURES.append("mutation: sample() did not honour the limit")

    strong = check_unit(unit, STRONG, mutants=30, mutation_tests=8)
    weak = check_unit(unit, WEAK, mutants=30, mutation_tests=8)
    for name, rep in (("strong", strong), ("weak", weak)):
        if rep["status"] != "pass":
            FAILURES.append(f"mutation: the {name} spec should pass the earlier gates: "
                            f"{rep.get('diagnostics')}")
    s_score = (strong.get("mutation") or {}).get("score")
    w_score = (weak.get("mutation") or {}).get("score")
    if s_score is None or w_score is None:
        FAILURES.append(f"mutation: missing scores ({s_score}, {w_score})")
    elif not s_score > w_score:
        FAILURES.append(f"mutation: the exact spec ({s_score}) must outscore the bound ({w_score})")

    # A postcondition that is simply FALSE has to be caught by the runtime gate, not shipped.
    false_spec = PREAMBLE + """
def total(n: int) -> int:
    Requires(n >= 0)
    Ensures(2 * Result() == n * (n + 1))
    s = 0
    for i in range(n):
        s = s + i
    return s
"""
    rep = check_unit(unit, false_spec, mutants=0)
    if rep["status"] == "pass":
        FAILURES.append("runtime gate: a false postcondition was accepted")
    elif not any("ENSURES FALSE" in d for d in rep["diagnostics"]):
        FAILURES.append(f"runtime gate: wrong diagnostic {rep['diagnostics']}")

    # Behaviour drift from solution.py must be caught even when every contract is true.
    drifted = PREAMBLE + """
def total(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() >= 0)
    Ensures(2 * Result() == n * (n - 1) + 2 * n)
    s = 0
    for i in range(n + 1):
        s = s + i
    return s
"""
    rep = check_unit(unit, drifted, mutants=0)
    if rep["status"] == "pass" or not any("BEHAVIOUR DIFFERS" in d or "OUTPUT MISMATCH" in d
                                          for d in rep["diagnostics"]):
        FAILURES.append(f"behaviour gate: drift not caught ({rep['diagnostics']})")

    # -- the repair loop, driven by a stub generator (no API key) -------------------------------
    broken = PREAMBLE + """
def total(n: int) -> int:
    Requires(n >= 0)
    Ensures(Implies(n > 0, Result() == guess))
    s = 0
    for i in range(n):
        s = s + i
    guess = s
    return s
"""
    (unit / "solution_contracts.py").write_text(broken)
    out = Path(td) / "out"
    r = repair_unit(unit, generator=stub_generator({"Total": STRONG}), attempts=2,
                    out_dir=out, mutants=20, mutation_tests=8)
    if r["status"] != "pass":
        FAILURES.append(f"repair: the loop did not recover ({r.get('diagnostics')})")
    if not r.get("written", "").startswith(str(out)):
        FAILURES.append(f"repair: nothing written to the staging dir ({r.get('written')})")
    if (unit / "solution_contracts.py").read_text() != broken:
        FAILURES.append("repair: clobbered solution_contracts.py without --in-place")

    fb = feedback_from(check_unit(unit, broken, mutants=0), 0.6)
    if not any("Implies" in f for f in fb) or not any("guess" in f for f in fb):
        FAILURES.append(f"repair: the diagnostic fed back is not specific enough ({fb})")

    # A candidate that fails the gates must never be written, and must not displace a good one.
    (unit / "solution_contracts.py").write_text(STRONG)
    r = repair_unit(unit, generator=stub_generator({"Total": broken}), attempts=1,
                    out_dir=out, min_mutation_score=1.1, mutants=20, mutation_tests=8)
    if r["status"] != "pass" or (r.get("mutation") or {}).get("score") != 1.0:
        FAILURES.append(f"repair: a failing regeneration displaced the passing original ({r})")


if FAILURES:
    print(f"{len(FAILURES)} FAILURE(S):")
    for f in FAILURES:
        print("  - " + f)
    raise SystemExit(1)
print("contract_qa: all gate tests passed")
