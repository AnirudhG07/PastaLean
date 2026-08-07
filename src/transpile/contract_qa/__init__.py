"""Contract QA — a generate → verify → repair pipeline for contract-annotated Python.

The generator (an LLM) is not trusted. Every candidate `solution_contracts.py` passes through a
ladder of gates, cheapest and most decisive first:

    1. static   — parse, forbidden vocabulary, scope, placement, lowerability   (`static_gates`)
    2. dynamic  — behaviour identity vs `solution.py`, and every contract TRUE  (`dynamic`)
    3. mutation — does the spec REJECT wrong implementations?                   (`mutation`)
    4. critic   — advisory LLM judgement, never a gate                          (`llm_io`)

Gates 1-3 are deterministic and need no API key. Only gate 4 does.

One loop, not two: `repair_unit` verifies whatever is on disk (or nothing yet) and, only when a
gate fails, spends an LLM call to regenerate with the specific diagnostic fed back — bounded by
`attempts`, and never writing a file that still fails. `check_unit` is the same gates without the
generator, which is what `--attempts 0` runs.
"""

from .harness import check_unit, qa_units
from .pipeline import repair_unit
from .static_gates import Finding, static_check, substantive_ensures_count
from .unit import Unit, load_unit

__all__ = [
    "Finding",
    "Unit",
    "check_unit",
    "load_unit",
    "qa_units",
    "repair_unit",
    "static_check",
    "substantive_ensures_count",
]
