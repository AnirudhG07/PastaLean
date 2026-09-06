"""Generate TypyBench predictions with PastaLean's repo-level TypeInfer engine.

TypyBench (ICML 2025, https://github.com/typybench/typybench) evaluates repository-level type
inference: given `repo_without_types/` (an untyped Python repo), a tool must emit an annotated copy;
TypyBench extracts types via mypy from the prediction and the ground-truth `original_repo/` and scores
TypeSim / exact-match / TypeCheck.

This driver is a *dumb pipe* on the Python side (matching the project's Lean-first split): it parses
each file to raw IR (no inference), asks the standalone `typeinfer` exe's `inferRepo` task to infer the
whole repo in one Lean fixpoint, then writes the inferred types back as annotations. All inference —
including cross-file import resolution — happens in Lean.

Usage:
    python typybench_bench/predict.py <untyped_repo_dir> <out_pred_dir>
"""
from __future__ import annotations
import ast
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))
from pastalean.transpile import driver  # noqa: E402
from pastalean import paths  # noqa: E402

EXE = Path(paths.LAKE_BIN_DIR) / "typeinfer"


def module_name(rel: Path) -> str:
    """Dotted module name for a repo-relative .py path (`pkg/sub/mod.py` -> `pkg.sub.mod`,
    `pkg/__init__.py` -> `pkg`)."""
    parts = list(rel.with_suffix("").parts)
    if parts and parts[-1] == "__init__":
        parts = parts[:-1]
    return ".".join(parts)


def collect_modules(repo: Path) -> tuple[dict[str, dict], dict[str, Path]]:
    """Raw per-file IR keyed by dotted module name (Python does NO inference here)."""
    mods, files = {}, {}
    for py in sorted(repo.rglob("*.py")):
        rel = py.relative_to(repo)
        dotted = module_name(rel)
        if not dotted or dotted.startswith("."):
            continue
        try:
            raw = driver.translate_to_json(py.read_text(encoding="utf-8"), str(py),
                                           best_effort=True, infer_only=True, resolve_imports=False)
            mods[dotted] = json.loads(raw)
            files[dotted] = py
        except Exception:  # noqa: BLE001
            continue
    return mods, files


def infer_repo(mods: dict[str, dict]) -> dict[str, dict]:
    """One Lean fixpoint over the whole repo via the `inferRepo` task."""
    proc = subprocess.Popen([str(EXE), "--server"], stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE, text=True,
                            env={**os.environ, "LEAN_NUM_THREADS": str(min(os.cpu_count() or 8, 64))})
    proc.stdin.write(json.dumps({"task": "inferRepo", "modules": mods}) + "\n")
    proc.stdin.flush()
    out = json.loads(proc.stdout.readline())
    proc.stdin.close(); proc.wait()
    return out.get("modules", {})


def render_type(node: dict | None) -> str | None:
    """Render an IR type node (`{node_type:Name/Subscript/Tuple}`) to a Python annotation string.
    The nodes are already annotation-shaped, so `ast.unparse` on the reconstructed expr suffices."""
    expr = _to_expr(node)
    if expr is None:
        return None
    try:
        s = ast.unparse(ast.fix_missing_locations(expr))
        # Reject non-committal annotations that would only hurt (TypyBench counts `Any` as missing).
        return None if s in ("Any", "None", "object", "_", "") else s
    except Exception:  # noqa: BLE001
        return None


def _to_expr(node: dict | None):
    if not isinstance(node, dict):
        return None
    nt = node.get("node_type")
    if nt == "Name":
        i = node.get("id")
        return ast.Name(id=i) if isinstance(i, str) and i.isidentifier() else None
    if nt == "Subscript":
        v = _to_expr(node.get("value")); s = _to_expr(node.get("slice"))
        return ast.Subscript(value=v, slice=s, ctx=ast.Load()) if v and s else None
    if nt == "Tuple":
        elts = [_to_expr(e) for e in node.get("elts", [])]
        return ast.Tuple(elts=[e for e in elts if e], ctx=ast.Load()) if all(elts) else None
    return None


def _strip_ssa(name: str) -> str:
    """SSA versions a rebinding as `x'v1`; the source binder is the base name."""
    return name.split("'")[0]


def build_type_map(stamped: dict) -> tuple[dict[str, dict[str, str]], dict[str, str], dict[str, str]]:
    """From a stamped module IR, extract: function name -> {param: annot}, function name -> return
    annot, and (function-scope, var) -> annot for locals/assign targets. Keyed by source names, so
    the desugar/SSA structural changes don't matter — only the binder names do."""
    fn_params: dict[str, dict[str, str]] = {}
    fn_ret: dict[str, str] = {}
    var_ann: dict[str, str] = {}

    def walk(node, scope: str):
        if isinstance(node, dict):
            nt = node.get("node_type")
            if nt == "FunctionDef":
                fname = node.get("name", "")
                args = node.get("args", {})
                params = {}
                for a in args.get("args", []) + args.get("posonlyargs", []) + args.get("kwonlyargs", []):
                    ann = render_type(a.get("_ty"))
                    if ann and a.get("arg"):
                        params[a["arg"]] = ann
                if params:
                    fn_params[fname] = params
                r = render_type(node.get("_ret_ty"))
                if r:
                    fn_ret[fname] = r
                for s in node.get("body", []):
                    walk(s, fname)
                return
            if nt in ("Assign", "AnnAssign"):
                tgt = node.get("target") or (node.get("targets") or [None])[0]
                if isinstance(tgt, dict) and tgt.get("node_type") == "Name":
                    ann = render_type(tgt.get("_bench_ty") or tgt.get("_ty"))
                    if ann:
                        var_ann[f"{scope}::{_strip_ssa(tgt.get('id',''))}"] = ann
            for v in node.values():
                walk(v, scope)
        elif isinstance(node, list):
            for x in node:
                walk(x, scope)

    walk(stamped, "")
    return fn_params, fn_ret, var_ann


class Annotator(ast.NodeTransformer):
    """Write the inferred annotations back onto a parsed source file. Only fills annotations that are
    ABSENT (never overwrites a user annotation), matching by name/scope."""

    def __init__(self, fn_params, fn_ret, var_ann):
        self.fn_params, self.fn_ret, self.var_ann = fn_params, fn_ret, var_ann
        self.scope = [""]

    def visit_FunctionDef(self, node):
        params = self.fn_params.get(node.name, {})
        for a in node.args.args + node.args.posonlyargs + node.args.kwonlyargs:
            if a.annotation is None and a.arg in params and a.arg != "self":
                try:
                    a.annotation = ast.parse(params[a.arg], mode="eval").body
                except Exception:  # noqa: BLE001
                    pass
        if node.returns is None and node.name in self.fn_ret:
            try:
                node.returns = ast.parse(self.fn_ret[node.name], mode="eval").body
            except Exception:  # noqa: BLE001
                pass
        self.scope.append(node.name)
        self.generic_visit(node)
        self.scope.pop()
        return node

    visit_AsyncFunctionDef = visit_FunctionDef

    def visit_Assign(self, node):
        if len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
            key = f"{self.scope[-1]}::{node.targets[0].id}"
            if key in self.var_ann:
                try:
                    ann = ast.parse(self.var_ann[key], mode="eval").body
                    return ast.copy_location(
                        ast.AnnAssign(target=node.targets[0], annotation=ann, value=node.value, simple=1), node)
                except Exception:  # noqa: BLE001
                    pass
        return node


def annotate_repo(repo: Path, out: Path):
    mods, files = collect_modules(repo)
    stamped = infer_repo(mods)
    # copy the whole repo, then overwrite the .py files we could annotate
    subprocess.run(["cp", "-r", str(repo), str(out)], check=True)
    n_files = n_annots = 0
    for dotted, st in stamped.items():
        src = files.get(dotted)
        if src is None:
            continue
        fn_params, fn_ret, var_ann = build_type_map(st)
        rel = src.relative_to(repo)
        try:
            tree = ast.parse((repo / rel).read_text(encoding="utf-8"))
        except SyntaxError:
            continue
        Annotator(fn_params, fn_ret, var_ann).visit(tree)
        try:
            (out / rel).write_text(ast.unparse(ast.fix_missing_locations(tree)), encoding="utf-8")
            n_files += 1
            n_annots += sum(len(v) for v in fn_params.values()) + len(fn_ret) + len(var_ann)
        except Exception:  # noqa: BLE001
            continue
    print(f"[typybench] annotated {n_files} files, ~{n_annots} annotations -> {out}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__); sys.exit(1)
    annotate_repo(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
