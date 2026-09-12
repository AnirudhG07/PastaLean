"""Drive the standalone `typeinfer` Lean binary over a file / directory.

Python source is parsed to JSON IR by the pure Python front-end (`driver.translate_to_json` with
`infer_only=True`, no backend boot), the compiled engine runs the fixpoint, and `collect_types`
gathers the stamped result. Repo mode ships every module's IR to the `inferRepo` task so imports
resolve in one cross-file fixpoint."""

from __future__ import annotations

import json
from pathlib import Path

from ..backend.typeinfer import infer_ast, infer_repo
from ..transpile import driver
from .collect import collect_types
from .records import InferResult


def infer_source(source: str, path: str | None = None) -> InferResult:
    """Parse `source` to JSON IR (pure Python front-end, no backend boot), run the standalone
    `typeinfer` engine over it, and collect the stamped types."""
    ir = json.loads(driver.translate_to_json(source, path, best_effort=True, infer_only=True))
    return collect_types(infer_ast(ir))


def infer_file(path: str | Path) -> InferResult:
    path = Path(path)
    return infer_source(path.read_text(encoding="utf-8"), str(path))


def _module_name(rel: Path) -> str:
    """Dotted module name for a repo-relative path (`pkg/sub/mod.py` -> `pkg.sub.mod`,
    `pkg/__init__.py` -> `pkg`)."""
    parts = list(rel.with_suffix("").parts)
    if parts and parts[-1] == "__init__":
        parts = parts[:-1]
    return ".".join(parts)


def _collect_repo_modules(repo: Path) -> tuple[dict[str, dict], dict[str, Path]]:
    """Raw per-file IR keyed by dotted module name (no inference here — Lean does it all). Imports are
    left unresolved (`resolve_imports=False`); `inferRepo` resolves them against this module set."""
    mods: dict[str, dict] = {}
    files: dict[str, Path] = {}
    for py in sorted(repo.rglob("*.py")):
        dotted = _module_name(py.relative_to(repo))
        if not dotted or dotted.startswith("."):
            continue
        try:
            raw = driver.translate_to_json(py.read_text(encoding="utf-8"), str(py),
                                           best_effort=True, infer_only=True, resolve_imports=False)
            mods[dotted] = json.loads(raw)
            files[dotted] = py
        except Exception:  # noqa: BLE001  (a single unparseable file must not sink the repo)
            continue
    return mods, files


def infer_repo_dir(repo: Path) -> dict[str, tuple[Path, InferResult]]:
    """Cross-file inference over every `.py` under `repo` in one Lean fixpoint (the `inferRepo`
    task). Returns each module's source path and collected types, keyed by dotted module name."""
    mods, files = _collect_repo_modules(repo)
    stamped = infer_repo(mods)
    out: dict[str, tuple[Path, InferResult]] = {}
    for dotted, st in stamped.items():
        src = files.get(dotted)
        if src is not None:
            out[dotted] = (src, collect_types(st))
    return out
