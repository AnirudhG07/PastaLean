#!/usr/bin/env python3
"""Score Astral's `ty` type checker on the TypeEvalPy micro-benchmark, for a head-to-head with
PastaLean's TypeInfer on the SAME ground truth.

`ty` is a *checker*, not an inference-fact emitter, so we extract its inferred types the standard
way: inject `reveal_type(<name>)` after every assignment target, run `ty check`, and parse the
`Revealed type` diagnostics. We score VARIABLE facts (the bulk) name-keyed, exactly like the
PastaLean harness, so the numbers are comparable.

Usage:  uv run python typeinfer_bench/run_ty.py [--bench DIR]
"""
from __future__ import annotations
import argparse, ast, json, re, subprocess, sys, tempfile
from collections import defaultdict
from pathlib import Path

DEFAULT_BENCH = Path("/tmp/TypeEvalPy/micro-benchmark/python_features")

_SCALAR = {"int": "int", "str": "str", "bool": "bool", "float": "float",
           "None": "Nonetype", "bytes": "bytes"}
_CONTAINER = {"list": "list", "dict": "dict", "set": "set", "tuple": "tuple",
              "frozenset": "set"}


def ty_type_to_root(t):
    """Map a `ty` revealed type string (e.g. `list[int]`, `def func() -> int`, `Unknown`) to a
    TypeEvalPy root type, or None when ty gives no useful type."""
    t = t.strip().strip("`")
    if not t or t in ("Unknown", "Any", "None", "Never"):
        return "Nonetype" if t == "None" else None
    # `def f(...) -> R` / bound method / `<class 'X'>` → callable / class.
    if t.startswith("def ") or "->" in t or t.startswith("bound method"):
        return "callable"
    m = re.match(r"^([A-Za-z_][\w.]*)", t)
    if not m:
        return None
    head = m.group(1).split(".")[-1]
    if head in _SCALAR:
        return _SCALAR[head]
    if head in _CONTAINER:
        return _CONTAINER[head]
    if head in ("Literal",):
        # Literal[42] → int, Literal['x'] → str
        inner = t[t.find("[") + 1:t.rfind("]")] if "[" in t else ""
        if inner.isdigit() or (inner.startswith("-") and inner[1:].isdigit()):
            return "int"
        if inner.startswith(("'", '"')):
            return "str"
        if inner in ("True", "False"):
            return "bool"
        return None
    return head  # a class name


def inject_reveals(src):
    """Return (source-with-reveal_type-after-each-Name-assign, [names-in-injection-order])."""
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return None, []
    names = []

    class Injector(ast.NodeTransformer):
        def _reveal_stmts(self, targets):
            out = []
            for t in targets:
                for n in ast.walk(t):
                    if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Store):
                        names.append(n.id)
                        out.append(ast.Expr(ast.Call(
                            func=ast.Name(id="reveal_type", ctx=ast.Load()),
                            args=[ast.Name(id=n.id, ctx=ast.Load())], keywords=[])))
            return out

        def visit_Module(self, node):
            self.generic_visit(node)
            return node

        def _process_body(self, body):
            new = []
            for s in body:
                new.append(s)
                if isinstance(s, ast.Assign):
                    new.extend(self._reveal_stmts(s.targets))
                elif isinstance(s, (ast.AnnAssign, ast.AugAssign)) and s.target:
                    new.extend(self._reveal_stmts([s.target]))
            return new

        def visit_FunctionDef(self, node):
            self.generic_visit(node)
            node.body = self._process_body(node.body)
            return node

    tree.body = Injector()._process_body(tree.body)
    tree = ast.fix_missing_locations(Injector().visit(tree))
    try:
        return ast.unparse(tree), names
    except Exception:  # noqa: BLE001
        return None, []


def run_ty_on(src):
    """Return {name: root_type} from ty's reveal_type diagnostics on `src` (reveals are matched to
    names in source order)."""
    injected, names = inject_reveals(src)
    if injected is None:
        return {}
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False, dir="/tmp") as f:
        f.write(injected)
        path = f.name
    try:
        out = subprocess.run(["uv", "run", "ty", "check", path], capture_output=True, text=True,
                             cwd=str(Path(__file__).resolve().parent.parent)).stdout
    except Exception:  # noqa: BLE001
        return {}
    # Each reveal produces a block ending in `^^^ \`Type\``; collect them in order.
    revealed = re.findall(r"revealed-type[\s\S]*?\^+\s*`([^`]*)`", out)
    result = {}
    for name, ty_t in zip(names, revealed):
        result[name] = ty_type_to_root(ty_t)
    return result


def load_gt_vars(gt_path):
    facts = []
    for f in json.loads(Path(gt_path).read_text()):
        if "variable" in f and "[" not in f["variable"] and "." not in f["variable"]:
            golds = [_SCALAR.get(g, _CONTAINER.get(g, g)) for g in (f.get("type") or [])]
            facts.append((f["variable"], golds))
    return facts


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", type=Path, default=DEFAULT_BENCH)
    args = ap.parse_args()
    snippets = sorted(args.bench.glob("*/*/main.py"))
    print(f"[*] ty on {len(snippets)} snippets (plain module-level variable facts)")
    matched = covered = total = 0
    by_cat = defaultdict(lambda: [0, 0])
    for py in snippets:
        gt = py.with_name("main_gt.json")
        if not gt.exists():
            continue
        cat = py.parts[-3]
        preds = run_ty_on(py.read_text())
        for name, golds in load_gt_vars(gt):
            total += 1
            pred = preds.get(name)
            by_cat[cat][1] += 1
            if pred is not None:
                covered += 1
                if pred in golds:
                    matched += 1
                    by_cat[cat][0] += 1
    print(f"\n  ty  — plain variable facts: match {matched}/{total} "
          f"({100*matched/total:.1f}%)  cover {covered}/{total} ({100*covered/total:.1f}%)")
    print("\n  (compare to PastaLean's variable dimension on the same snippets)")


if __name__ == "__main__":
    main()
