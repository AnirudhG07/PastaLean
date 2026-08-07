"""Mutation operators — small, behaviour-changing edits to the *implementation*.

Why this is the load-bearing gate: a contract can be well-formed, TRUE on every recorded input, and
still say nothing. Every gate that only looks at the correct program will pass such a spec. So we
ask the question the other way round — *which wrong programs does this specification reject?* — the
standard mutation-testing formulation (DeMillo/Lipton/Sayward 1978; as automated by `mutmut` and
`cosmic-ray`), with the roles inverted: the mutants are the "tests", and the contract is the
artifact under evaluation.

The recorded test suite is only used to decide which mutants are *effective* (genuinely wrong).
A mutant no test distinguishes is an equivalent mutant and is excluded from the denominator.

Contract arguments are never mutated — that would be mutating the specification, not the program.
"""

from __future__ import annotations

import ast
import copy
from dataclasses import dataclass

from .static_gates import contract_call

_MUT_ATTR = "_cqa_site"

_CMP_SWAP = {
    ast.Lt: [ast.LtE, ast.Gt], ast.LtE: [ast.Lt, ast.GtE],
    ast.Gt: [ast.GtE, ast.Lt], ast.GtE: [ast.Gt, ast.LtE],
    ast.Eq: [ast.NotEq], ast.NotEq: [ast.Eq],
    ast.In: [ast.NotIn], ast.NotIn: [ast.In],
}
_BIN_SWAP = {
    ast.Add: [ast.Sub], ast.Sub: [ast.Add], ast.Mult: [ast.Add],
    ast.FloorDiv: [ast.Mult], ast.Div: [ast.Mult], ast.Mod: [ast.FloorDiv],
    ast.Pow: [ast.Mult], ast.BitXor: [ast.BitAnd], ast.BitAnd: [ast.BitOr], ast.BitOr: [ast.BitAnd],
}
_NONCOMMUTATIVE = (ast.Sub, ast.Div, ast.FloorDiv, ast.Mod, ast.Pow, ast.LShift, ast.RShift)


@dataclass
class Mutant:
    """One single-point edit. `op` groups mutants so sampling stays diverse."""

    op: str
    description: str
    source: str
    line: int = 0

    @property
    def name(self) -> str:
        return f"{self.op}@{self.line}"


def _index_sites(tree: ast.Module) -> list[ast.AST]:
    """Number every node outside a contract argument, so a deep copy can find the same node again.

    `ast` nodes take arbitrary attributes and `copy.deepcopy` carries them, which is what makes the
    "copy the tree, then mutate site *i*" loop below work without tracking paths.
    """
    sites: list[ast.AST] = []

    def walk(node: ast.AST) -> None:
        for child in ast.iter_child_nodes(node):
            if contract_call(child) is not None:
                continue                      # never mutate the specification
            setattr(child, _MUT_ATTR, len(sites))
            sites.append(child)
            walk(child)

    walk(tree)
    return sites


def _find(tree: ast.AST, idx: int) -> ast.AST | None:
    for n in ast.walk(tree):
        if getattr(n, _MUT_ATTR, None) == idx:
            return n
    return None


def _emit(tree: ast.Module, idx: int, patch, op: str, desc: str, line: int) -> Mutant | None:
    """Deep-copy the tree, apply `patch` to site `idx`, unparse."""
    clone = copy.deepcopy(tree)
    node = _find(clone, idx)
    if node is None:
        return None
    try:
        patch(node, clone)
        ast.fix_missing_locations(clone)
        src = ast.unparse(clone)
    except Exception:  # noqa: BLE001  (a malformed mutant is simply skipped)
        return None
    return Mutant(op=op, description=desc, source=src, line=line)


def _int_const(v: int) -> ast.expr:
    return ast.Constant(value=v) if v >= 0 else ast.UnaryOp(ast.USub(), ast.Constant(value=-v))


def _replace_child(parent_tree: ast.AST, target: ast.AST, new: ast.AST) -> bool:
    for parent in ast.walk(parent_tree):
        for field, value in ast.iter_fields(parent):
            if value is target:
                setattr(parent, field, new)
                return True
            if isinstance(value, list):
                for i, item in enumerate(value):
                    if item is target:
                        value[i] = new
                        return True
    return False


def generate_mutants(source: str, entry: str | None = None,
                     constant_answer: str | None = None) -> list[Mutant]:
    """Every single-point mutant of `source`, grouped by operator.

    `constant_answer` (the literal a correct run produces for the FIRST recorded input) enables the
    "return a constant" mutant — the sharpest probe for a spec that only bounds its output.
    """
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return []
    sites = _index_sites(tree)
    out: list[Mutant] = []

    for idx, node in enumerate(sites):
        line = getattr(node, "lineno", 0)

        if isinstance(node, ast.Compare) and len(node.ops) == 1:
            for new_op in _CMP_SWAP.get(type(node.ops[0]), []):
                old = type(node.ops[0]).__name__
                out.append(_emit(tree, idx, lambda n, _t, o=new_op: n.ops.__setitem__(0, o()),
                                 "compare", f"{old} -> {new_op.__name__}", line))

        elif isinstance(node, ast.BinOp):
            for new_op in _BIN_SWAP.get(type(node.op), []):
                old = type(node.op).__name__
                out.append(_emit(tree, idx, lambda n, _t, o=new_op: setattr(n, "op", o()),
                                 "arith", f"{old} -> {new_op.__name__}", line))
            if isinstance(node.op, _NONCOMMUTATIVE):
                def swap(n, _t):
                    n.left, n.right = n.right, n.left
                out.append(_emit(tree, idx, swap, "swap_operands",
                                 f"swap operands of {type(node.op).__name__}", line))

        elif isinstance(node, ast.BoolOp):
            new = ast.Or if isinstance(node.op, ast.And) else ast.And
            out.append(_emit(tree, idx, lambda n, _t, o=new: setattr(n, "op", o()),
                             "boolop", f"{type(node.op).__name__} -> {new.__name__}", line))

        elif isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.Not):
            out.append(_emit(tree, idx, lambda n, t: _replace_child(t, n, n.operand),
                             "drop_not", "drop `not`", line))

        elif isinstance(node, ast.Constant) and isinstance(node.value, bool):
            out.append(_emit(tree, idx, lambda n, _t: setattr(n, "value", not n.value),
                             "const", f"{node.value} -> {not node.value}", line))

        elif isinstance(node, ast.Constant) and isinstance(node.value, int):
            for delta in (1, -1):
                out.append(_emit(tree, idx, lambda n, _t, d=delta: setattr(n, "value", n.value + d),
                                 "const", f"{node.value} -> {node.value + delta}", line))

        elif isinstance(node, ast.If):
            for val in (True, False):
                out.append(_emit(tree, idx, lambda n, _t, v=val: setattr(n, "test", ast.Constant(value=v)),
                                 "branch", f"force branch condition {val}", line))

        elif isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
            fname = node.func.id
            if fname == "range" and node.args:
                for pos in range(len(node.args)):
                    for delta in (1, -1):
                        def bump(n, _t, p=pos, d=delta):
                            n.args[p] = ast.BinOp(n.args[p], ast.Add() if d > 0 else ast.Sub(),
                                                  ast.Constant(value=1))
                        out.append(_emit(tree, idx, bump, "range_bound",
                                         f"range arg {pos} {'+' if delta > 0 else '-'} 1", line))
            elif fname == "sorted" and node.args:
                def rev(n, t):
                    _replace_child(t, n, ast.Subscript(
                        value=n, slice=ast.Slice(lower=None, upper=None,
                                                 step=ast.Constant(value=-1)), ctx=ast.Load()))
                out.append(_emit(tree, idx, rev, "sort", "reverse the sort", line))

                def unsorted(n, t):
                    _replace_child(t, n, n.args[0])
                out.append(_emit(tree, idx, unsorted, "sort", "drop the sort", line))
            elif fname in ("min", "max") and node.args:
                other = "max" if fname == "min" else "min"
                out.append(_emit(tree, idx, lambda n, _t, o=other: setattr(n.func, "id", o),
                                 "minmax", f"{fname} -> {other}", line))
            elif fname in ("all", "any") and node.args:
                other = "any" if fname == "all" else "all"
                out.append(_emit(tree, idx, lambda n, _t, o=other: setattr(n.func, "id", o),
                                 "quantifier", f"{fname} -> {other}", line))

        elif isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            if node.func.attr == "sort":
                def revsort(n, _t):
                    n.keywords = [k for k in n.keywords if k.arg != "reverse"]
                    n.keywords.append(ast.keyword(arg="reverse", value=ast.Constant(value=True)))
                out.append(_emit(tree, idx, revsort, "sort", "list.sort(reverse=True)", line))

        elif isinstance(node, ast.Subscript) and isinstance(node.slice, ast.Slice):
            for attr in ("lower", "upper"):
                if getattr(node.slice, attr) is not None:
                    def bump(n, _t, a=attr):
                        setattr(n.slice, a, ast.BinOp(getattr(n.slice, a), ast.Add(), ast.Constant(1)))
                    out.append(_emit(tree, idx, bump, "slice", f"slice {attr} + 1", line))

    if constant_answer is not None:
        try:
            literal = ast.parse(constant_answer, mode="eval").body
        except SyntaxError:
            literal = None
        if literal is not None:
            clone = copy.deepcopy(tree)
            hit = 0
            for fn in clone.body:
                if isinstance(fn, (ast.FunctionDef, ast.AsyncFunctionDef)) and (
                        entry is None or fn.name == entry):
                    for n in ast.walk(fn):
                        if isinstance(n, ast.Return):
                            n.value = copy.deepcopy(literal)
                            hit += 1
            if hit:
                ast.fix_missing_locations(clone)
                out.append(Mutant("return_const",
                                  f"always return {constant_answer[:40]}", ast.unparse(clone), 0))

    return [m for m in out if m is not None and m.source != source]


def sample(mutants: list[Mutant], limit: int, seed: int = 0) -> list[Mutant]:
    """Deterministic, operator-balanced sample. Round-robin across operators so a file with 200
    integer literals does not spend the whole budget on constant bumps."""
    if limit <= 0 or len(mutants) <= limit:
        return list(mutants)
    import random

    rng = random.Random(seed)
    buckets: dict[str, list[Mutant]] = {}
    for m in mutants:
        buckets.setdefault(m.op, []).append(m)
    for v in buckets.values():
        rng.shuffle(v)
    out: list[Mutant] = []
    order = sorted(buckets)
    while len(out) < limit and any(buckets[k] for k in order):
        for k in order:
            if buckets[k] and len(out) < limit:
                out.append(buckets[k].pop())
    return out
