"""Client for the standalone `typeinfer` Lean binary.

Type inference is a pure `Json -> Json` pipeline in Lean (`lowerGenerators -> desugarAst ->
ssaModule -> inferModule`) that touches no `Environment`, so the `typeinfer` executable runs it
without the ~4s/~1GiB Mathlib boot the full `py2lean` backend pays. This module is the thin Python
side: it hands a JSON IR module to the exe and reads back the type-stamped AST. No Mathlib, no warm
process to manage — the exe starts, answers one task, and exits.
"""

from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

from .. import paths


class TypeInferUnavailable(RuntimeError):
    """The `typeinfer` binary is missing or failed to answer."""


def typeinfer_exe() -> Path:
    exe = Path(paths.LAKE_BIN_DIR) / "typeinfer"
    if not exe.exists():
        raise TypeInferUnavailable(
            f"typeinfer binary not found at {exe} — build it with `lake build typeinfer`."
        )
    return exe


def _run_task(task: dict) -> dict:
    """Send one task to the exe over its `--server` line protocol (avoids argv-length limits on a
    large AST) and parse the single JSON response line. `LEAN_NUM_THREADS` sizes the exe's task
    scheduler pool so `inferBatch`/`inferRepo` fan across the machine's cores in-process."""
    exe = typeinfer_exe()
    env = {**os.environ, "LEAN_NUM_THREADS": str(min(os.cpu_count() or 8, 64))}
    proc = subprocess.Popen(
        [str(exe), "--server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=env,
    )
    out, err = proc.communicate(json.dumps(task) + "\n")
    line = next((ln for ln in (out or "").splitlines() if ln.strip()), "")
    if not line:
        raise TypeInferUnavailable(f"typeinfer produced no output (stderr: {(err or '').strip()})")
    resp = json.loads(line)
    if not resp.get("result", False):
        raise TypeInferUnavailable(resp.get("error", "typeinfer task failed"))
    return resp


def infer_ast(ast: dict) -> dict:
    """Whole-module inference on one JSON IR module; returns the type-stamped AST.

    Best-effort, matching the engine's contract: if a pre-pass fails the exe returns the original
    AST unchanged rather than an error, so extraction still sees the (untransformed) program.
    """
    return _run_task({"task": "inferTypes", "ast": ast}).get("ast", ast)


def infer_batch(asts: list[dict]) -> list[dict]:
    """Infer a list of independent modules in one call. The exe dispatches each to Lean's task
    scheduler, so they run across the machine's cores in a single process (no cross-file resolution
    — use `infer_repo` for that)."""
    return _run_task({"task": "inferBatch", "asts": asts}).get("results", [])


def infer_repo(modules: dict[str, dict]) -> dict[str, dict]:
    """Repo-level inference: `modules` maps each dotted module name to its raw IR. Lean resolves
    imports, composes the repo, runs one cross-file fixpoint, and returns each module's stamped IR."""
    return _run_task({"task": "inferRepo", "modules": modules}).get("modules", {})
