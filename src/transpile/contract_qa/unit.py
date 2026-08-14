"""A benchmark *unit*: one directory holding a reference solution, its contracted twin, and tests.

The layout is PastaBench's (`meta.json` / `tests.json` / `solution.py` / `solution_contracts.py`),
but nothing here is specific to a track — any directory with those four files works.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

#: The only markers the Lean side maps (`PastaLean/PyVerify/Contracts.lean`).
CONTRACT_MARKERS = ("Requires", "Ensures", "Assume", "Assert", "Invariant", "Decreases")
#: Plus the return-value references, legal only inside a postcondition.
RESULT_MARKERS = ("Result", "ResultT")
#: In the Python shim but NOT mapped to Lean. `Implies`/`Forall` return True unconditionally, so a
#: contract built from them is silently vacuous; the rest raise `NameError`. Never ship either.
FORBIDDEN_MARKERS = (
    "Forall", "ForAll", "Old", "Implies", "Refute", "Exsures", "Unfold", "Reveal", "isNaN",
)


@dataclass
class Unit:
    """One benchmark problem."""

    dir: Path
    meta: dict
    tests: list[dict]
    reference: str                  # solution.py — the untouched program
    contracts_path: Path            # where the annotated twin lives (may not exist)
    statement: str = ""             # problem.txt, for the critic

    @property
    def module(self) -> str:
        return self.meta.get("module") or self.dir.name

    @property
    def method(self) -> str:
        return self.meta["method"]

    def contracts_source(self) -> str | None:
        return self.contracts_path.read_text() if self.contracts_path.exists() else None


def load_unit(unit_dir: str | Path, contracts_name: str = "solution_contracts.py") -> Unit:
    d = Path(unit_dir).resolve()
    meta = json.loads((d / "meta.json").read_text())
    tests_file = d / "tests.json"
    tests = json.loads(tests_file.read_text()) if tests_file.exists() else []
    statement = (d / "problem.txt").read_text() if (d / "problem.txt").exists() else ""
    return Unit(
        dir=d,
        meta=meta,
        tests=tests,
        reference=(d / "solution.py").read_text(),
        contracts_path=d / contracts_name,
        statement=statement,
    )


def discover_units(root: str | Path, only: list[str] | None = None) -> list[Path]:
    """Every unit directory at or under `root`. A unit is a directory with a `meta.json` naming an
    entry point and a `tests.json` of recorded inputs — the two things the execution gates need."""
    root = Path(root).resolve()
    if (root / "meta.json").exists():
        return [root]
    dirs = sorted({p.parent for p in root.rglob("meta.json")})
    if only:
        wanted = set(only)
        dirs = [d for d in dirs if d.name in wanted]
    return dirs


def parse_input(spec: str, namespace: dict) -> dict | None:
    """`"n = 3, p = 5"` -> `{"n": 3, "p": 5}`.

    The recorded form is a comma-separated keyword list, which is not a statement on its own —
    `dict(...)` makes it one. The `exec` path covers the rarer multi-statement recordings.
    """
    try:
        return eval(f"dict({spec})", {**namespace})  # noqa: S307  (recorded test inputs)
    except Exception:  # noqa: BLE001
        pass
    scope: dict = {}
    try:
        exec(spec, {**namespace}, scope)  # noqa: S102
    except Exception:  # noqa: BLE001
        return None
    return {k: v for k, v in scope.items() if not k.startswith("_")}
