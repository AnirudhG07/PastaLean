#!/usr/bin/env python3
"""Prototype: use PastaLean's TypeInfer as a standalone Python type ANNOTATOR.

PastaLean's `inferTypes` pass already stamps inferred types onto the IR (`_ty`/`_bench_ty` on params,
`_ret_ty`/`_bench_ret_ty` on returns, `_bench_ty` on assignment targets). This script maps those back
to PEP 484 Python annotations and rewrites the source — turning the transpiler's inference engine into
a MonkeyType-style annotator (`pastalean annotate foo.py`), independent of any Lean/transpile step.

Usage:  uv run python typeinfer_bench/annotate.py <file.py>          # prints annotated source
"""
from __future__ import annotations
import ast, sys
from pathlib import Path

from pastalean import Session

_NAME = {"Int": "int", "Nat": "int", "String": "str", "Char": "str", "Bool": "bool",
         "Float": "float", "Rat": "float", "Real": "float", "None": "None", "Unit": "None",
         "PyAny": "Any", "Callable": "Callable"}
_CONT = {"List": "list", "Std.HashMap": "dict", "Set": "set", "PyDefaultDict": "dict",
         "Counter": "dict"}


def ann_to_pystr(node):
    """A PastaLean `_ty` annotation node → a Python annotation string, or None."""
    if not isinstance(node, dict):
        return None
    nt = node.get("node_type")
    if nt == "Name":
        rid = node.get("id")
        if rid in _NAME:
            return _NAME[rid]
        if rid in _CONT:
            return _CONT[rid]
        return rid  # class name / already-python name
    if nt == "Subscript":
        base = node.get("value", {})
        bid = base.get("id") if isinstance(base, dict) else None
        if bid in ("Optional", "Option"):
            inner = ann_to_pystr(node.get("slice"))
            return f"Optional[{inner}]" if inner else None
        if bid in ("List",) or bid == "list":
            inner = ann_to_pystr(node.get("slice"))
            return f"list[{inner}]" if inner else "list"
        if bid in ("Set",) or bid == "set":
            inner = ann_to_pystr(node.get("slice"))
            return f"set[{inner}]" if inner else "set"
        if bid in ("Std.HashMap", "Dict", "dict", "PyDefaultDict", "Counter"):
            sl = node.get("slice", {})
            if isinstance(sl, dict) and sl.get("node_type") == "Tuple":
                parts = [ann_to_pystr(e) for e in sl.get("elts", [])]
                if all(parts):
                    return f"dict[{', '.join(parts)}]"
            return "dict"
        if bid == "Callable":
            return "Callable"
        return ann_to_pystr(base)
    return None


def _pystr_to_ast(s):
    try:
        return ast.parse(s, mode="eval").body
    except SyntaxError:
        return None


def annotate(source, stamped):
    """Rewrite `source`'s AST, adding annotations from the stamped IR (params/returns/vars)."""
    tree = ast.parse(source)

    # Index inferred types by (function-name, param-name) and function-name -> return.
    ret_ty, param_ty = {}, {}

    def walk(o):
        if isinstance(o, dict):
            if o.get("node_type") == "FunctionDef":
                fn = o.get("name")
                r = o.get("_ret_ty") or o.get("_bench_ret_ty")
                if o.get("_ret_float") is True:
                    ret_ty[fn] = "float"
                elif r:
                    ret_ty[fn] = ann_to_pystr(r)
                for a in o.get("args", {}).get("args", []):
                    t = ann_to_pystr(a.get("_ty") or a.get("_bench_ty"))
                    if t:
                        param_ty[(fn, a.get("arg"))] = t
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    walk(stamped)

    class Annotator(ast.NodeTransformer):
        def visit_FunctionDef(self, node):
            self.generic_visit(node)
            for i, a in enumerate(node.args.args):
                if i == 0 and a.arg in ("self", "cls"):
                    continue  # `self`/`cls` are unannotated by convention
                if a.annotation is None:
                    t = param_ty.get((node.name, a.arg))
                    if t and t != "Any":
                        a.annotation = _pystr_to_ast(t)
            if node.returns is None and node.name in ret_ty and ret_ty[node.name] not in (None, "Any"):
                node.returns = _pystr_to_ast(ret_ty[node.name])
            return node

    tree = Annotator().visit(tree)
    return ast.unparse(ast.fix_missing_locations(tree))


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    py = Path(sys.argv[1])
    src = py.read_text()
    with Session(target="command", mode="both") as s:
        ir = s.to_json_ir_file(py)
        res = s.client.infer_types(ir)
        stamped = res.get("ast", res) if isinstance(res, dict) else res
    print(annotate(src, stamped))


if __name__ == "__main__":
    main()
