#!/usr/bin/env python3
"""Benchmark PastaLean's TypeInfer engine against the TypeEvalPy micro-benchmark.

TypeEvalPy (ICSE 2024) ships 150+ self-contained core-Python snippets with ground-truth type
"facts" (function return / parameter / local-variable types, as *root* types like ``list``,
``callable``, ``Nonetype``, class names). We run PastaLean's `inferTypes` backend task over each
snippet, map its inferred annotations to TypeEvalPy's root-type vocabulary, and score:

  * exact-match  — inferred root type is in the ground-truth type list (TypeEvalPy's own metric)
  * coverage     — fraction of facts we inferred *anything* (non-Any) for (recall of the engine)
  * TypeSim      — a light semantic-similarity overlay (int~float, list~set~tuple, …) for partial credit

Variable facts include subscript/attribute expressions (``my_list[0]``, ``self.width``,
``data[0]['name']``); these are resolved by descending the base variable's inferred container/class
type (element type of a list/dict, or a class field's type).

Usage:  uv run python typeinfer_bench/typeinfer_eval.py [--bench DIR] [--out FILE] [--diff CATEGORY]
"""
from __future__ import annotations
import argparse, ast, json, re
from collections import defaultdict
from pathlib import Path

from pastalean import Session

DEFAULT_BENCH = Path("/tmp/TypeEvalPy/micro-benchmark/python_features")

_SCALAR = {
    "int": "int", "Int": "int", "Nat": "int",
    "str": "str", "String": "str", "Char": "str",
    "bool": "bool", "Bool": "bool",
    "float": "float", "Float": "float", "Rat": "float", "Real": "float", "complex": "float",
    "None": "Nonetype", "NoneType": "Nonetype", "Nonetype": "Nonetype", "Unit": "Nonetype",
    "bytes": "bytes",
}
_CONTAINER = {
    "List": "list", "list": "list", "Std.HashMap": "dict", "Dict": "dict", "dict": "dict",
    "Set": "set", "set": "set", "frozenset": "set", "Tuple": "tuple", "tuple": "tuple",
    "PyDefaultDict": "dict", "Counter": "dict", "deque": "list",
}
_LIST_LIKE = {"List", "list", "Set", "set", "frozenset", "deque"}
_DICT_LIKE = {"Dict", "dict", "Std.HashMap", "PyDefaultDict", "Counter"}


def ann_root(node):
    """A PastaLean `_ty`/`_bench_ty` annotation node -> a TypeEvalPy root type string, or None."""
    if not isinstance(node, dict):
        return None
    nt = node.get("node_type")
    if nt == "Name":
        rid = node.get("id")
        if rid in ("PyAny", "Any"):
            return None
        if rid in ("Callable", "callable", "function"):
            return "callable"
        if rid in _SCALAR:
            return _SCALAR[rid]
        if rid in _CONTAINER:
            return _CONTAINER[rid]
        return rid.split(".")[-1] if rid else None
    if nt == "Constant":
        return "Nonetype" if node.get("value") is None else None
    if nt == "Subscript":
        base = node.get("value")
        base_id = base.get("id") if isinstance(base, dict) else None
        if base_id in ("Optional", "Option"):
            return ann_root(node.get("slice"))
        return ann_root(base)
    if nt == "Attribute":
        return node.get("attr")
    if nt == "Tuple":
        return "tuple"
    return None


def ann_index(ann):
    """Element-type annotation after a subscript on `ann` (list->elem, dict->value, str->str)."""
    if not isinstance(ann, dict):
        return None
    nt = ann.get("node_type")
    if nt == "Name":
        return {"node_type": "Name", "id": "str"} if ann.get("id") in ("str", "String") else None
    if nt != "Subscript":
        return None
    base = ann.get("value"); sl = ann.get("slice")
    bid = base.get("id") if isinstance(base, dict) else None
    if bid in ("Optional", "Option"):
        return ann_index(sl)
    if bid in _LIST_LIKE:
        return sl
    if bid in ("Tuple", "tuple"):
        if isinstance(sl, dict) and sl.get("node_type") == "Tuple":
            elts = sl.get("elts", [])
            return elts[0] if elts else None
        return sl
    if bid in _DICT_LIKE:
        if isinstance(sl, dict) and sl.get("node_type") == "Tuple":
            elts = sl.get("elts", [])
            return elts[-1] if elts else None
        return sl
    return None


# --- light TypeSim overlay -----------------------------------------------------------------------

_ITERABLE = {"list", "set", "tuple", "dict", "generator", "str", "map", "zip"}
_NUMERIC = {"int", "float", "bool"}


def type_sim(pred, gold):
    if pred == gold:
        return 1.0
    if pred is None:
        return 0.0
    if pred in _NUMERIC and gold in _NUMERIC:
        return 0.6
    if pred in _ITERABLE and gold in _ITERABLE:
        return 0.5
    return 0.0


# --- extract predictions from the stamped AST ----------------------------------------------------

def _has_value_return(body):
    """Does this statement list contain a `return <expr>` (not a bare `return`), not descending into
    nested function/class defs (their returns belong to them)?"""
    for s in body:
        if not isinstance(s, dict):
            continue
        nt = s.get("node_type")
        if nt in ("FunctionDef", "AsyncFunctionDef", "ClassDef", "Lambda"):
            continue
        if nt == "Return":
            v = s.get("value")
            if isinstance(v, dict) and v.get("node_type") is not None:
                return True
        for k, v in s.items():
            if isinstance(v, list) and _has_value_return(v):
                return True
            if isinstance(v, dict) and _has_value_return([v]):
                return True
    return False


def _base(name):
    """Strip TypeInfer's SSA version suffix (`y'v1` → `y`) so a name aligns with the ground truth,
    which uses the original Python identifier. Also drops a `'rn`/other `'`-suffix the codegen adds."""
    return name.split("'")[0] if isinstance(name, str) else name


def _collect_target(t, cls, var_ann, field_ann, field_by_attr):
    """Record `_bench_ty`/`_ty` on an assignment target, descending tuple/list/starred targets."""
    nt = t.get("node_type")
    if nt == "Name":
        ann = t.get("_bench_ty") or t.get("_ty")
        if ann:
            # SSA versions a type-changing var (`y`→`y'v1`); the ground truth names the base `y`.
            var_ann[_base(t.get("id"))] = ann
    elif nt == "Attribute":
        ann = t.get("_bench_ty") or t.get("_ty")
        if ann:
            field_ann[(cls, t.get("attr"))] = ann
            field_by_attr[t.get("attr")] = ann
    elif nt == "Starred":
        inner = t.get("value")
        if isinstance(inner, dict):
            _collect_target(inner, cls, var_ann, field_ann, field_by_attr)
    elif nt in ("Tuple", "List"):
        for e in t.get("elts", []):
            if isinstance(e, dict):
                _collect_target(e, cls, var_ann, field_ann, field_by_attr)


def collect(stamped):
    """Returns (returns, params, var_ann, field_ann, field_by_attr) where *_ann map to full annotation
    nodes (not roots), so subscript/attribute facts can be resolved by descent."""
    returns, params, var_ann = {}, {}, {}
    field_ann, field_by_attr = {}, {}

    def walk(o, cls):
        if isinstance(o, dict):
            nt = o.get("node_type")
            if nt == "FunctionDef":
                raw = _base(o.get("name") or "")
                fname = (cls + "." if cls else "") + raw
                # TypeEvalPy's ground truth names a method's `function` UNQUALIFIED (`__init__`, not
                # `MyClass.__init__`), so record returns/params under BOTH the qualified key and the
                # bare method name (SSA suffix stripped) — else method-param/return facts never match.
                keys = {fname, raw}
                if o.get("_ret_float") is True:
                    rann = {"node_type": "Name", "id": "float"}
                elif o.get("_ret_ty") or o.get("_bench_ret_ty"):
                    rann = o.get("_ret_ty") or o.get("_bench_ret_ty")
                elif not _has_value_return(o.get("body", [])):
                    # No `return <expr>` anywhere → the function returns None (Python's implicit return).
                    rann = {"node_type": "Name", "id": "None"}
                else:
                    rann = None
                if rann is not None:
                    for k in keys:
                        returns[k] = rann
                for a in o.get("args", {}).get("args", []):
                    ann = a.get("_ty") or a.get("_bench_ty")
                    if ann:
                        pname = _base(a.get("arg") or "")
                        for k in keys:
                            params[(k, pname)] = ann
                for v in o.values():
                    walk(v, cls)
                return
            if nt == "ClassDef":
                inner = (cls + "." if cls else "") + (o.get("name") or "")
                # Class-level variables live in `fields` with a typed default (`class_var = 20.44`).
                # Record them so a `ClassName.class_var` / `obj.class_var` fact resolves.
                for f in o.get("fields", []):
                    if not isinstance(f, dict):
                        continue
                    ann = f.get("_ty") or f.get("_bench_ty")
                    dflt = f.get("default")
                    if ann is None and isinstance(dflt, dict) and dflt.get("node_type") == "Constant":
                        lk = dflt.get("python_literal_kind")
                        if lk in ("int", "float", "str", "bool"):
                            ann = {"node_type": "Name", "id": lk}
                    if ann and f.get("name"):
                        field_ann[(inner, f["name"])] = ann
                        field_by_attr.setdefault(f["name"], ann)
                for v in o.values():
                    walk(v, inner)
                return
            if nt in ("Assign", "AnnAssign", "AugAssign", "For"):
                t = o.get("target")
                if isinstance(t, dict):
                    _collect_target(t, cls, var_ann, field_ann, field_by_attr)
            if nt in ("ListComp", "SetComp", "GeneratorExp", "DictComp"):
                for g in o.get("generators", []):
                    t = g.get("target")
                    if isinstance(t, dict) and t.get("node_type") == "Name":
                        ann = t.get("_bench_ty") or t.get("_ty")
                        if ann:
                            var_ann[t.get("id")] = ann
            for v in o.values():
                walk(v, cls)
        elif isinstance(o, list):
            for v in o:
                walk(v, cls)

    walk(stamped, "")
    return returns, params, var_ann, field_ann, field_by_attr


# --- resolve a (possibly subscript/attribute) variable name to a type ----------------------------

def parse_accessors(name):
    m = re.match(r"^([A-Za-z_]\w*)", name)
    if not m:
        return None, []
    base, rest, accs = m.group(1), name[m.end():], []
    while rest:
        if rest.startswith("["):
            j = rest.find("]")
            if j < 0:
                break
            accs.append(("sub",))
            rest = rest[j + 1:]
        elif rest.startswith("."):
            m2 = re.match(r"\.([A-Za-z_]\w*)", rest)
            if not m2:
                break
            accs.append(("attr", m2.group(1)))
            rest = rest[m2.end():]
        else:
            break
    return base, accs


def resolve(name, var_ann, field_ann, field_by_attr):
    base, accs = parse_accessors(name)
    if base is None:
        return None
    if base == "self":
        if accs and accs[0][0] == "attr":
            ann = field_by_attr.get(accs[0][1])
            accs = accs[1:]
        else:
            return None
    else:
        ann = var_ann.get(base)
        # `ClassName.attr` (a class-variable / static access): the base is a class name, not an
        # assigned variable, so `var_ann` misses it — resolve the attribute directly as a field.
        if ann is None and accs and accs[0][0] == "attr":
            ann = field_ann.get((base, accs[0][1])) or field_by_attr.get(accs[0][1])
            accs = accs[1:]
    for acc in accs:
        if ann is None:
            return None
        if acc[0] == "sub":
            ann = ann_index(ann)
        else:  # attr
            cls = ann.get("id") if isinstance(ann, dict) and ann.get("node_type") == "Name" else None
            ann = (field_ann.get((cls, acc[1])) if cls else None) or field_by_attr.get(acc[1])
    return ann


# --- ground truth + scoring ----------------------------------------------------------------------

def load_gt(gt_path):
    facts = []
    for f in json.loads(Path(gt_path).read_text()):
        golds = [_SCALAR.get(g, _CONTAINER.get(g, g)) for g in (f.get("type") or [])]
        if "parameter" in f:
            facts.append(("param", (f.get("function"), f["parameter"]), golds))
        elif "variable" in f:
            facts.append(("var", f["variable"], golds))
        elif "function" in f:
            facts.append(("return", f["function"], golds))
    return facts


def score(preds, facts):
    returns, params, var_ann, field_ann, field_by_attr = preds
    agg = defaultdict(lambda: {"total": 0, "covered": 0, "matched": 0, "sim": 0.0})
    diffs = []
    for kind, key, golds in facts:
        if kind == "return":
            pred = ann_root(returns.get(key))
        elif kind == "param":
            pred = ann_root(params.get(key))
        else:
            pred = ann_root(resolve(key, var_ann, field_ann, field_by_attr))
        a = agg[kind]
        a["total"] += 1
        if pred is not None:
            a["covered"] += 1
            a["sim"] += max((type_sim(pred, g) for g in golds), default=0.0)
            if pred in golds:
                a["matched"] += 1
        diffs.append((kind, key, pred, golds))
    return agg, diffs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", type=Path, default=DEFAULT_BENCH)
    ap.add_argument("--out", type=Path, default=Path("typeinfer_bench/typeinfer_summary.json"))
    ap.add_argument("--diff", default=None, help="Dump per-fact pred-vs-gold for snippets in this category")
    ap.add_argument("--misses", action="store_true", help="Aggregate the most common miss patterns globally")
    ap.add_argument("--limit", type=int, default=None, help="Only run the first N snippets (for a quick slice)")
    args = ap.parse_args()
    miss_counts = defaultdict(int)
    miss_examples = {}

    snippets = sorted(args.bench.glob("*/*/main.py"))
    if args.limit:
        snippets = snippets[:args.limit]
    print(f"[*] {len(snippets)} snippets under {args.bench}")

    total = defaultdict(lambda: {"total": 0, "covered": 0, "matched": 0, "sim": 0.0})
    by_cat = defaultdict(lambda: defaultdict(lambda: {"total": 0, "covered": 0, "matched": 0, "sim": 0.0}))
    per_snippet, errors = {}, 0

    s = Session(target="command", mode="both")
    s.start()
    try:
        for py in snippets:
            cat = py.parts[-3]
            gt = py.with_name("main_gt.json")
            if not gt.exists():
                continue
            try:
                # Local sibling imports are resolved by the transpiler pipeline itself
                # (driver.resolve_local_imports), so this is exactly what `pastalean translate` sees.
                ir = s.to_json_ir_file(py)
                res = s.client.infer_types(ir)
                stamped = res.get("ast", res) if isinstance(res, dict) else res
                preds = collect(stamped)
            except Exception as e:  # noqa: BLE001
                errors += 1
                preds = ({}, {}, {}, {}, {})
            agg, diffs = score(preds, load_gt(gt))
            if args.misses:
                for kind, key, pred, golds in diffs:
                    if pred not in golds:
                        subs = "[" in str(key) or "." in str(key)
                        bucket = (kind, "sub/attr" if subs else "plain",
                                  "predicted-wrong" if pred else "no-prediction", tuple(golds))
                        miss_counts[bucket] += 1
                        miss_examples.setdefault(bucket, []).append(cat)
            if args.diff and cat == args.diff:
                print(f"\n--- {cat}/{py.parent.name} ---")
                for kind, key, pred, golds in diffs:
                    mark = "OK " if pred in golds else ("~~ " if pred else "MISS")
                    print(f"    [{mark}] {kind:6} {key}: pred={pred} gold={golds}")
            per_snippet[f"{cat}/{py.parent.name}"] = {k: dict(v) for k, v in agg.items()}
            for kind, a in agg.items():
                for f in ("total", "covered", "matched"):
                    total[kind][f] += a[f]; by_cat[cat][kind][f] += a[f]
                total[kind]["sim"] += a["sim"]; by_cat[cat][kind]["sim"] += a["sim"]
    finally:
        s.close()

    def line(a):
        t, c, m, sim = a["total"], a["covered"], a["matched"], a["sim"]
        return (f"match {m}/{t} ({100*m/t:.1f}%)  cover {c}/{t} ({100*c/t:.1f}%)  TypeSim {sim/t:.3f}"
                if t else "—")

    print("\n=== Per dimension ===")
    grand = {"total": 0, "covered": 0, "matched": 0, "sim": 0.0}
    for kind in ("return", "param", "var"):
        a = total[kind]; print(f"  {kind:7} {line(a)}")
        for f in grand:
            grand[f] += a[f]
    print(f"  {'ALL':7} {line(grand)}")

    # TypeEvalPy leaderboard-style breakdown (exact-match counts per dimension).
    print("\n=== Exact-match breakdown (TypeEvalPy leaderboard columns) ===")
    labels = [("Function Return Type", "return"), ("Function Parameter Type", "param"),
              ("Local Variable Type", "var")]
    print(f"  {'Dimension':24} {'Exact match':>14}")
    for label, kind in labels:
        a = total[kind]
        print(f"  {label:24} {a['matched']:>7} / {a['total']:<6}")
    print(f"  {'Total':24} {grand['matched']:>7} / {grand['total']:<6}")

    print("\n=== Per category (all dimensions) ===")
    for cat in sorted(by_cat):
        a = {"total": 0, "covered": 0, "matched": 0, "sim": 0.0}
        for kind in by_cat[cat].values():
            for f in a:
                a[f] += kind[f]
        print(f"  {cat:16} {line(a)}")

    if args.misses:
        print("\n=== Top miss patterns (kind, shape, why, gold) ===")
        for k, c in sorted(miss_counts.items(), key=lambda kv: -kv[1])[:30]:
            print(f"  {c:4}  {k[0]:6} {k[1]:8} {k[2]:16} gold={list(k[3])}  cats: {sorted(set(miss_examples.get(k,[])), key=miss_examples.get(k,[]).count, reverse=True)[:4]}")

    print(f"\n[*] snippets with a backend/convert error: {errors}")
    args.out.write_text(json.dumps({
        "breakdown": {
            "Function Return Type": {"matched": total["return"]["matched"], "total": total["return"]["total"]},
            "Function Parameter Type": {"matched": total["param"]["matched"], "total": total["param"]["total"]},
            "Local Variable Type": {"matched": total["var"]["matched"], "total": total["var"]["total"]},
            "Total": {"matched": grand["matched"], "total": grand["total"]},
        },
        "overall": {k: dict(v) for k, v in total.items()},
        "grand": grand,
        "by_category": {c: {k: dict(v) for k, v in d.items()} for c, d in by_cat.items()},
        "per_snippet": per_snippet, "errors": errors,
    }, indent=2))
    print(f"[*] summary -> {args.out}")


if __name__ == "__main__":
    main()
