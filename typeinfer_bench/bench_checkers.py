#!/usr/bin/env python3
"""Head-to-head inference RECALL on TypeEvalPy: PastaLean vs the 5 production type checkers
(ty, pyrefly, pyright, mypy, zuban), scored on the IDENTICAL set of plain module-level variable
facts.

TypeEvalPy is an inference-recall benchmark; a checker is not a fact emitter, so for each snippet we
inject `reveal_type(<name>)` after every module-level `Name` assignment, run the checker, and parse
its revealed types (each checker has its own format). Every tool is scored name-keyed against the same
ground-truth variable facts, so the numbers are directly comparable.

Usage:  uv run python typeinfer_bench/bench_checkers.py [--bench DIR] [--tools ty,mypy,...]
"""
from __future__ import annotations
import argparse, ast, json, re, subprocess, sys, tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from typeinfer_eval import collect, ann_root                    # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
VENV = ROOT / ".venv" / "bin"
DEFAULT_BENCH = Path("/tmp/TypeEvalPy/micro-benchmark/python_features")

_SCALAR = {"int": "int", "str": "str", "bool": "bool", "float": "float",
           "None": "Nonetype", "NoneType": "Nonetype", "bytes": "bytes"}
_CONTAINER = {"list": "list", "dict": "dict", "set": "set", "tuple": "tuple", "frozenset": "set"}


def norm_gold(g):
    return _SCALAR.get(g, _CONTAINER.get(g, g))


def type_str_to_root(t):
    """Map any checker's revealed-type STRING (mypy `builtins.list[builtins.int]`, pyright
    `Literal[42]`, pyrefly `list[int]`, ty `int`) to a TypeEvalPy root, or None for no-info."""
    t = t.strip().strip("`\"'").rstrip("?")  # zuban marks inferred types with a trailing `?`
    if not t or t in ("Unknown", "Any", "Never", "Untyped"):
        return None
    if t == "None":
        return "Nonetype"
    # Function/callable forms.
    if t.startswith(("def ", "bound method", "(")) or "->" in t or "Callable" in t:
        return "callable"
    # Literal[...] → element kind.
    m = re.match(r"^Literal\[(.*)\]$", t)
    if m:
        inner = m.group(1).split(",")[0].strip()
        if inner in ("True", "False"):
            return "bool"
        if inner.startswith(("'", '"')):
            return "str"
        if re.match(r"^-?\d+$", inner):
            return "int"
        if re.match(r"^-?\d+\.", inner):
            return "float"
        return None
    head = re.match(r"^([\w.]+)", t)
    if not head:
        return None
    name = head.group(1).split(".")[-1]  # builtins.int -> int
    if name in _SCALAR:
        return _SCALAR[name]
    if name in _CONTAINER:
        return _CONTAINER[name]
    return name  # class name


def _reveal(name):
    return ast.Expr(ast.Call(func=ast.Name(id="reveal_type", ctx=ast.Load()),
                             args=[ast.Name(id=name, ctx=ast.Load())], keywords=[]))


def _params_of(fn):
    a = fn.args
    return [p.arg for p in (a.posonlyargs + a.args + a.kwonlyargs)] + \
           ([a.vararg.arg] if a.vararg else []) + ([a.kwarg.arg] if a.kwarg else [])


def _process_body(stmts, enclosing_params=frozenset()):
    """Return a new statement list with `reveal_type(x)` after each Name assignment, a leading
    `reveal_type(p)` for each parameter inside a function body (the PARAMETER fact), and
    `reveal_type(funcname)` after each function def (the RETURN fact), recursively. A var-reveal is
    NOT emitted for a name that is a parameter of the enclosing function, so a param name stays
    unambiguously a param fact."""
    out = []
    for s in stmts:
        if isinstance(s, (ast.FunctionDef, ast.AsyncFunctionDef)):
            pnames = _params_of(s)
            s.body = [_reveal(p) for p in pnames] + _process_body(s.body, frozenset(pnames))
            for attr in ("decorator_list",):
                pass
        else:
            for attr in ("body", "orelse", "finalbody"):
                if hasattr(s, attr) and isinstance(getattr(s, attr), list):
                    setattr(s, attr, _process_body(getattr(s, attr), enclosing_params))
            if hasattr(s, "handlers"):
                for h in s.handlers:
                    h.body = _process_body(h.body, enclosing_params)
        out.append(s)
        targets = []
        if isinstance(s, ast.Assign):
            targets = s.targets
        elif isinstance(s, (ast.AnnAssign, ast.AugAssign)) and s.target:
            targets = [s.target]
        for t in targets:
            for n in ast.walk(t):
                if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Store) \
                        and n.id not in enclosing_params:
                    out.append(_reveal(n.id))
        if isinstance(s, (ast.FunctionDef, ast.AsyncFunctionDef)):
            out.append(_reveal(s.name))  # reveals `def f(...) -> R` → the RETURN fact
    return out


def inject_reveals(src, sub_exprs=()):
    """Add reveals for every Name assignment (variable), parameter, function def (return), plus a
    reveal for each (scope, expr) in `sub_exprs` (subscript/attribute facts). Returns
    (injected_source, {line: (kind, key)}) with kind in var/param/return."""
    try:
        tree = ast.parse(src)
    except SyntaxError:
        return None, {}
    func_names = {n.name for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
    # No `from typing import reveal_type` import: every checker recognizes `reveal_type` as a native
    # special form, and the import resolves against py3.10 stdlib (no member) which makes ty abort.
    tree.body = _process_body(tree.body)
    # Subscript/attribute variable facts (`my_list[0]`, `data[0]['name']`): append `reveal_type(expr)`
    # at the end of its scope so every checker gets a fair shot at them (module scope covers the bulk;
    # a fact tagged with a `function` gets its reveal appended to that function's body).
    fn_by_name = {n.name: n for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))}
    for scope, expr in sub_exprs:
        try:
            node = ast.parse(expr, mode="eval").body
        except SyntaxError:
            continue
        rev = ast.Expr(ast.Call(func=ast.Name(id="reveal_type", ctx=ast.Load()), args=[node], keywords=[]))
        if scope and scope in fn_by_name:
            fn_by_name[scope].body.append(rev)
        else:
            tree.body.append(rev)
    ast.fix_missing_locations(tree)
    try:
        injected = ast.unparse(tree)
    except Exception:  # noqa: BLE001
        return None, {}
    # Tag each reveal line by walking the emitted tree with a function-scope stack:
    #  - Name arg that is a parameter of the enclosing function → ("param", (funcname, arg))
    #  - Name arg that is a function name                       → ("return", arg)
    #  - Name arg otherwise                                     → ("var", arg)
    #  - non-Name arg (subscript/attribute)                     → ("var", unparse(arg))
    line_tag = {}

    def visit(node, fstack):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            fstack = fstack + [(node.name, set(_params_of(node)))]
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                and node.func.id == "reveal_type" and node.args):
            arg = node.args[0]
            if isinstance(arg, ast.Name):
                nm = arg.id
                if fstack and nm in fstack[-1][1]:
                    line_tag[node.lineno] = ("param", (fstack[-1][0], nm))
                elif nm in func_names:
                    line_tag[node.lineno] = ("return", nm)
                else:
                    line_tag[node.lineno] = ("var", nm)
            else:
                line_tag[node.lineno] = ("var", ast.unparse(arg))
        for ch in ast.iter_child_nodes(node):
            visit(ch, fstack)

    visit(ast.parse(injected), [])
    return injected, line_tag


def load_gt(gt_path):
    """Per-occurrence fact list matching TypeEvalPy's own scoring: a list of (kind, key, golds) with
    kind in {'return','param','var'}. Same shape as typeinfer_eval.load_gt so PastaLean is scored by
    its native harness and the checkers by the identical fact list."""
    facts = []
    for f in json.loads(Path(gt_path).read_text()):
        golds = [norm_gold(g) for g in (f.get("type") or [])]
        if "parameter" in f:
            facts.append(("param", (f.get("function"), f["parameter"]), golds))
        elif "variable" in f:
            facts.append(("var", f["variable"], golds))
        elif "function" in f:
            facts.append(("return", f["function"], golds))
    return facts


def sub_exprs_of(facts):
    """The subscript/attribute variable expressions in a fact list, with a best-effort scope (the GT
    doesn't record scope for these, so module scope is used — where the bulk live)."""
    out = []
    for kind, key, _ in facts:
        if kind == "var" and ("[" in key or "." in key):
            out.append(("", key))
    return out


# --- checker runners: each returns {basename: {line: type_str}} -----------------------------------

def _run(cmd, cwd=None):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd, timeout=600)
        return p.stdout + "\n" + p.stderr
    except Exception:  # noqa: BLE001
        return ""


def parse_by_file_line(out, pattern):
    """Generic: pattern has groups (path, line, type). Returns {basename: {line: type_str}}."""
    res = {}
    for m in re.finditer(pattern, out):
        base = Path(m.group(1)).name
        res.setdefault(base, {})[int(m.group(2))] = m.group(3)
    return res


def run_mypy(workspace):
    out = _run([str(VENV / "mypy"), "--no-error-summary", "--soft-error-limit", "-1",
                "--python-version", "3.12", "--no-incremental", str(workspace)])
    return parse_by_file_line(out, r'([^\s:]+\.py):(\d+): note: Revealed type is "([^"]*)"')


def run_zuban(workspace):
    out = _run([str(VENV / "zuban"), "check", str(workspace)])
    return parse_by_file_line(out, r'([^\s:]+\.py):(\d+): note: Revealed type is "([^"]*)"')


def run_pyright(workspace):
    out = _run(["npx", "pyright", "--outputjson", str(workspace)])
    res = {}
    try:
        data = json.loads(out[out.index("{"):out.rindex("}") + 1])
    except Exception:  # noqa: BLE001
        return res
    for d in data.get("generalDiagnostics", []):
        msg = d.get("message", "")
        m = re.match(r'Type of "[^"]*" is "(.*)"$', msg)
        if m and d.get("range"):
            base = Path(d.get("file", "")).name
            line = d["range"]["start"]["line"] + 1
            res.setdefault(base, {})[line] = m.group(1)
    return res


def run_ty(workspace):
    out = _run([str(VENV / "ty"), "check", "--python-version", "3.12", str(workspace)])
    res = {}
    for m in re.finditer(r"revealed-type[\s\S]*?-->\s*([^\s:]+\.py):(\d+)[\s\S]*?\^+\s*`([^`]*)`", out):
        res.setdefault(Path(m.group(1)).name, {})[int(m.group(2))] = m.group(3)
    return res


def run_pyrefly(workspace):
    (workspace / "pyrefly.toml").write_text('project-includes = ["**/*.py"]\npython-version = "3.12"\n')
    out = _run([str(VENV / "pyrefly"), "check"], cwd=str(workspace))
    res = {}
    for m in re.finditer(r"revealed type:\s*(.*?)\s*\[reveal-type\][\s\S]*?-->\s*([^\s:]+\.py):(\d+)", out):
        res.setdefault(Path(m.group(2)).name, {})[int(m.group(3))] = m.group(1)
    return res


CHECKERS = {"ty": run_ty, "pyrefly": run_pyrefly, "pyright": run_pyright,
            "mypy": run_mypy, "zuban": run_zuban}


def return_str_to_root(t):
    """Extract the return type from a revealed function type `def f(...) -> R` / `(...) -> R`."""
    if "->" not in t:
        return None
    return type_str_to_root(t.rsplit("->", 1)[1].strip().rstrip(":"))


def _new_acc():
    return {"return": [0, 0, 0], "param": [0, 0, 0], "var": [0, 0, 0]}


def _tally(preds, facts, acc):
    """preds: {(kind,key): root}. facts: [(kind, key, golds)] per-occurrence. acc[kind]=[m,c,tot]."""
    for kind, key, golds in facts:
        acc[kind][2] += 1
        r = preds.get((kind, key))
        if r is not None:
            acc[kind][1] += 1
            if r in golds:
                acc[kind][0] += 1


def score_checker(runner, workspace, per_file):
    revealed = runner(workspace)
    acc = _new_acc()
    for base, (line_tag, facts) in per_file.items():
        got = revealed.get(base, {})
        preds = {}
        for lineno, ts in got.items():
            tag = line_tag.get(lineno)
            if tag is None:
                continue
            kind, key = tag
            preds[(kind, key)] = return_str_to_root(ts) if kind == "return" else type_str_to_root(ts)
        _tally(preds, facts, acc)
    return acc


def score_pastalean(snippets):
    """PastaLean scored by its OWN native harness (typeinfer_eval.score) — resolves subscript/attribute
    facts by descending the base's container type, exactly the 850-fact scoring. Boot excluded from the
    returned time (warm inference only)."""
    import time
    from pastalean import Session
    from typeinfer_eval import score as pl_score
    acc = _new_acc()
    s = Session(target="command", mode="both"); s.start()          # boot (Mathlib) — NOT timed
    _ = s.to_json_ir_file(snippets[0][0]) if snippets else None    # warm the first request
    t0 = time.time()
    try:
        for py, facts in snippets:
            try:
                ir = s.to_json_ir_file(py, infer_only=True)
                res = s.client.infer_types(ir)
                stamped = res.get("ast", res) if isinstance(res, dict) else res
                agg, _ = pl_score(collect(stamped), facts)
            except Exception:  # noqa: BLE001
                agg = {}
            for kind in ("return", "param", "var"):
                a = agg.get(kind)
                if a:
                    acc[kind][0] += a["matched"]; acc[kind][1] += a["covered"]; acc[kind][2] += a["total"]
    finally:
        warm = time.time() - t0
        s.close()
    return acc, warm


def main():
    import time
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", type=Path, default=DEFAULT_BENCH)
    ap.add_argument("--tools", default="ty,pyrefly,pyright,mypy,zuban")
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()
    snippet_paths = sorted(args.bench.glob("*/*/main.py"))

    # Build a shared workspace of injected snippets + collect gt/line-tag per file.
    workspace = Path(tempfile.mkdtemp(prefix="checkbench_"))
    per_file = {}          # basename -> (line_tag, facts)
    pl_snippets = []       # (path, facts) for PastaLean
    for i, py in enumerate(snippet_paths):
        gtp = py.with_name("main_gt.json")
        if not gtp.exists():
            continue
        facts = load_gt(gtp)
        if not facts:
            continue
        injected, line_tag = inject_reveals(py.read_text(), sub_exprs_of(facts))
        if injected is None:
            continue
        base = f"s{i:04d}.py"
        (workspace / base).write_text(injected)
        per_file[base] = (line_tag, facts)
        pl_snippets.append((py, facts))

    nret = sum(1 for _, fs in per_file.values() for k in fs if k[0] == "return")
    npar = sum(1 for _, fs in per_file.values() for k in fs if k[0] == "param")
    nvar = sum(1 for _, fs in per_file.values() for k in fs if k[0] == "var")
    print(f"[*] {len(per_file)} snippets — return {nret} + param {npar} + variable {nvar} "
          f"= {nret+npar+nvar} facts (per-occurrence, incl. subscript/attribute)\n")

    rows = []          # (name, acc, seconds)
    print("  running PastaLean ...", flush=True)
    pl_acc, pl_warm = score_pastalean(pl_snippets)
    rows.append(("PastaLean (ours)", pl_acc, pl_warm))
    for name in args.tools.split(","):
        name = name.strip()
        if name not in CHECKERS:
            continue
        print(f"  running {name} ...", flush=True)
        t0 = time.time()
        acc = score_checker(CHECKERS[name], workspace, per_file)
        rows.append((name, acc, time.time() - t0))

    def cell(a):
        return f"{a[0]:>4}/{a[2]:<4} ({100*a[0]/a[2]:4.1f}%)" if a[2] else "     —"

    def total(acc):
        return [sum(acc[k][i] for k in acc) for i in range(3)]

    print(f"\n=== Inference recall on TypeEvalPy (fresh run, 2026 tool versions) ===")
    print("  reveal_type extraction for checkers; PastaLean via its native harness; SAME 850 facts")
    print("  PastaLean time = WARM inference only (Mathlib boot excluded); others include startup")
    print("  NOTE: mypy/ty follow the gradual guarantee (decline to infer unannotated code) BY DESIGN\n")
    print(f"  {'Tool':18} {'Return':>17} {'Param':>17} {'Variable':>17} {'TOTAL':>18} {'time':>9}")
    for name, acc, secs in sorted(rows, key=lambda r: -total(r[1])[0]):
        t = total(acc)
        print(f"  {name:18} {cell(acc['return']):>17} {cell(acc['param']):>17} {cell(acc['var']):>17} "
              f"{t[0]:>6}/{t[2]:<5} ({100*t[0]/t[2]:4.1f}%) {secs:>7.1f}s")

    if args.out:
        Path(args.out).write_text(json.dumps(
            {n: {"acc": a, "seconds": s} for n, a, s in rows}, indent=2))


if __name__ == "__main__":
    main()
