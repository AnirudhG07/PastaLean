"""Deterministic, execution-free gates over a contracted Python file.

Everything here is decided by the parser. An LLM is never asked to judge something `ast` can
settle, and a check that a *parser* can make is strictly cheaper and more reliable than one that
needs a test run — so these run first and short-circuit the rest of the ladder.

Each check exists because a real shipped contract file failed exactly that way:

  forbidden      `Implies`/`Forall` have no Lean mapping and `return True`, so the spec is vacuous;
                 `Old`/`ForAll` are not defined at all and raise `NameError` on every call.
  scope          a contract argument is evaluated EAGERLY, in place, so naming a local bound below
                 it turns "returns a value" into "raises `UnboundLocalError`" on every call.
  nested_ensures a postcondition inside an inner `def` is attributed to the enclosing entry point
                 and read in the wrong scope.
  loop_mutated   Python captures the entry value of a name at the top of the body; Lean's Hoare
                 postcondition reads the FINAL value. Passes every Python test, unprovable in Lean.
  mid_function   `Ensures`/`Result`-bearing `Assert` with a loop both before and after it is a
                 program-point checkpoint, which a Hoare postcondition cannot express.
  invariant_*    `Invariant` outside a loop, or not grouped at the top of the loop body, is not
                 lifted by the loop lowering.
  lowerability   constructs that degrade the whole unit to a `pyUnsupported` placeholder, or that
                 lower to something that silently means nothing (`is`, multi-clause comprehensions).
  vacuous        zero substantive `Ensures` — nothing about the OUTPUT is being claimed.
"""

from __future__ import annotations

import ast
from dataclasses import dataclass, field

from .unit import CONTRACT_MARKERS, FORBIDDEN_MARKERS, RESULT_MARKERS

import builtins as _builtins

_BUILTINS = set(dir(_builtins))

#: Foreign modules whose calls PastaLean has no runtime for.
_FOREIGN_MODULES = {"random", "hashlib", "os", "sys", "secrets", "time", "itertools", "functools"}


@dataclass
class Finding:
    """One defect. `error` blocks shipping; `warn` is reported and fed back but does not block."""

    kind: str
    severity: str          # "error" | "warn"
    message: str
    line: int = 0
    where: str = ""        # enclosing function, when known

    def __str__(self) -> str:
        loc = f"line {self.line}" + (f" in {self.where}()" if self.where else "")
        return f"[{self.severity}:{self.kind}] {loc}: {self.message}"

    def as_dict(self) -> dict:
        return {"kind": self.kind, "severity": self.severity, "message": self.message,
                "line": self.line, "where": self.where}


# -- name analysis --------------------------------------------------------------------------

def _target_names(node: ast.expr) -> set[str]:
    out: set[str] = set()
    for n in ast.walk(node):
        if isinstance(n, ast.Name):
            out.add(n.id)
    return out


def _arg_names(a: ast.arguments) -> set[str]:
    names = {x.arg for x in (*a.posonlyargs, *a.args, *a.kwonlyargs)}
    if a.vararg:
        names.add(a.vararg.arg)
    if a.kwarg:
        names.add(a.kwarg.arg)
    return names


def free_names(node: ast.AST) -> set[str]:
    """Names an expression READS from the enclosing scope.

    Comprehension targets and lambda parameters bind their own names, so they are excluded — a
    naive `ast.walk` would report `c` in `all(... for c in Result())` as unbound.
    """
    free: set[str] = set()

    def visit(n: ast.AST, bound: set[str]) -> None:
        if isinstance(n, ast.Name):
            if isinstance(n.ctx, ast.Load) and n.id not in bound:
                free.add(n.id)
            return
        if isinstance(n, (ast.ListComp, ast.SetComp, ast.GeneratorExp, ast.DictComp)):
            inner = set(bound)
            for i, gen in enumerate(n.generators):
                visit(gen.iter, bound if i == 0 else inner)
                inner |= _target_names(gen.target)
                for cond in gen.ifs:
                    visit(cond, inner)
            if isinstance(n, ast.DictComp):
                visit(n.key, inner)
                visit(n.value, inner)
            else:
                visit(n.elt, inner)
            return
        if isinstance(n, ast.Lambda):
            for d in (*n.args.defaults, *(x for x in n.args.kw_defaults if x)):
                visit(d, bound)
            visit(n.body, bound | _arg_names(n.args))
            return
        for child in ast.iter_child_nodes(n):
            visit(child, bound)

    visit(node, set())
    return free


def _bindings_of(stmt: ast.stmt, *, descend: bool = True) -> set[str]:
    """Names this statement binds in the CURRENT scope (a nested `def` binds only its own name)."""
    out: set[str] = set()
    if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
        return {stmt.name}
    if isinstance(stmt, (ast.Import, ast.ImportFrom)):
        for alias in stmt.names:
            out.add(alias.asname or alias.name.split(".")[0])
        return out
    if isinstance(stmt, ast.Assign):
        for t in stmt.targets:
            out |= _target_names(t)
    elif isinstance(stmt, (ast.AugAssign, ast.AnnAssign)):
        if getattr(stmt, "value", None) is not None or isinstance(stmt, ast.AugAssign):
            out |= _target_names(stmt.target)
    elif isinstance(stmt, (ast.For, ast.AsyncFor)):
        out |= _target_names(stmt.target)
    elif isinstance(stmt, (ast.With, ast.AsyncWith)):
        for item in stmt.items:
            if item.optional_vars is not None:
                out |= _target_names(item.optional_vars)
    elif isinstance(stmt, ast.Try):
        for h in stmt.handlers:
            if h.name:
                out.add(h.name)
    elif isinstance(stmt, (ast.Global, ast.Nonlocal)):
        return set()
    if descend:
        for child in ast.iter_child_nodes(stmt):
            if isinstance(child, ast.stmt):
                out |= _bindings_of(child)
            elif isinstance(child, ast.AST):
                for sub in ast.walk(child):
                    if isinstance(sub, (ast.NamedExpr,)) and isinstance(sub.target, ast.Name):
                        out.add(sub.target.id)
    return out


def _all_locals(fn: ast.AST) -> set[str]:
    """Every name that is LOCAL to `fn` — reading one before its binding is `UnboundLocalError`."""
    out: set[str] = set()
    declared_global: set[str] = set()
    for stmt in getattr(fn, "body", []):
        out |= _bindings_of(stmt)
    for n in ast.walk(fn):
        if isinstance(n, (ast.Global, ast.Nonlocal)):
            declared_global |= set(n.names)
    return out - declared_global


def _module_names(tree: ast.Module) -> set[str]:
    """Module-level bindings. Order does not matter: a global is resolved at CALL time, so a
    helper defined below the function that names it is still fine at runtime."""
    out: set[str] = set()
    for stmt in tree.body:
        out |= _bindings_of(stmt, descend=False)
        if isinstance(stmt, ast.ImportFrom) and any(a.name == "*" for a in stmt.names):
            out |= set(CONTRACT_MARKERS) | set(RESULT_MARKERS) | set(FORBIDDEN_MARKERS)
    return out


# -- contract shape helpers ------------------------------------------------------------------

def contract_call(node: ast.AST) -> tuple[str, ast.expr] | None:
    """`(marker, argument)` if `node` is a bare contract-marker call statement or expression."""
    call = node.value if isinstance(node, ast.Expr) else node
    if (isinstance(call, ast.Call) and isinstance(call.func, ast.Name)
            and call.func.id in CONTRACT_MARKERS and call.args):
        return call.func.id, call.args[0]
    return None


def mentions_result(expr: ast.AST) -> bool:
    return any(isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
               and n.func.id in RESULT_MARKERS for n in ast.walk(expr))


def _is_trivial_ensures(expr: ast.expr) -> bool:
    """A vacuous postcondition: a one-sided bound against a constant (`Result() >= 0`,
    `len(x) <= n`). A real property relates the output to a FORMULA over the inputs."""
    if not (isinstance(expr, ast.Compare) and len(expr.comparators) == 1):
        return False
    left, right = expr.left, expr.comparators[0]

    def literalish(n: ast.expr) -> bool:
        return (isinstance(n, ast.Constant)
                or (isinstance(n, ast.UnaryOp) and isinstance(n.operand, ast.Constant)))

    def bare_ref(n: ast.expr) -> bool:
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name):
            return n.func.id in (*RESULT_MARKERS, "len", "abs") and all(
                literalish(a) or isinstance(a, ast.Name) for a in n.args)
        return isinstance(n, ast.Name)

    return (literalish(left) and bare_ref(right)) or (literalish(right) and bare_ref(left))


def substantive_ensures_count(source: str) -> int:
    """How many NON-TRIVIAL `Ensures(...)` the file states about its output. Each must mention
    `Result()` and not be a bare constant bound. Zero means nothing is claimed about the answer."""
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return 0
    n = 0
    for node in ast.walk(tree):
        got = contract_call(node)
        if got and got[0] == "Ensures" and mentions_result(got[1]) and not _is_trivial_ensures(got[1]):
            n += 1
    return n


# -- the checks -----------------------------------------------------------------------------

@dataclass
class StaticReport:
    findings: list[Finding] = field(default_factory=list)
    substantive_ensures: int = 0
    n_contracts: int = 0

    @property
    def errors(self) -> list[Finding]:
        return [f for f in self.findings if f.severity == "error"]

    @property
    def warnings(self) -> list[Finding]:
        return [f for f in self.findings if f.severity == "warn"]

    @property
    def ok(self) -> bool:
        return not self.errors

    def as_dict(self) -> dict:
        return {"ok": self.ok, "substantive_ensures": self.substantive_ensures,
                "n_contracts": self.n_contracts,
                "findings": [f.as_dict() for f in self.findings]}


def _loop_assigned(fn: ast.AST) -> set[str]:
    """Names any loop in `fn` reassigns — including the loop target itself."""
    out: set[str] = set()
    for n in ast.walk(fn):
        if isinstance(n, (ast.For, ast.AsyncFor, ast.While)):
            if isinstance(n, (ast.For, ast.AsyncFor)):
                out |= _target_names(n.target)
            for stmt in n.body:
                out |= _bindings_of(stmt)
            for stmt in n.orelse:
                out |= _bindings_of(stmt)
    return out


def _check_lowerability(expr: ast.AST, add, line: int, where: str, ctx: str) -> None:
    """Constructs known to degrade codegen, or to lower to something that means nothing."""
    for n in ast.walk(expr):
        if isinstance(n, ast.Call):
            f = n.func
            if isinstance(f, ast.Name) and f.id == "pow" and len(n.args) == 3:
                add("lowerability", "warn", f"3-argument pow() in {ctx} does not lower", line, where)
            if isinstance(f, ast.Name) and f.id == "int" and len(n.args) == 2:
                add("lowerability", "warn", f"2-argument int(s, base) in {ctx} does not lower", line, where)
            if isinstance(f, ast.Attribute) and isinstance(f.value, ast.Name):
                if f.value.id == "math" and f.attr == "pow":
                    add("lowerability", "warn", f"math.pow in {ctx} does not lower (use ** or *)", line, where)
                elif f.value.id in _FOREIGN_MODULES:
                    add("lowerability", "warn",
                        f"{f.value.id}.{f.attr} in {ctx}: no PastaLean runtime for this module", line, where)
            if (isinstance(f, ast.Name) and f.id in ("all", "any") and n.args
                    and isinstance(n.args[0], (ast.GeneratorExp, ast.ListComp))
                    and len(n.args[0].generators) > 1):
                add("lowerability", "warn",
                    f"multi-clause comprehension inside {f.id}() in {ctx} falls back to an inert Bool "
                    "fold instead of a real quantifier — nest single-generator comprehensions",
                    line, where)
        if isinstance(n, ast.Compare):
            if any(isinstance(o, (ast.Is, ast.IsNot)) for o in n.ops):
                add("lowerability", "warn",
                    f"`is`/`is not` in {ctx} lowers to structural equality, so it asserts nothing",
                    line, where)
            if ctx == "a contract" and len(n.ops) > 1:
                add("lowerability", "warn",
                    "chained comparison in a contract — split it into two contracts", line, where)


def static_check(source: str, entry: str | None = None) -> StaticReport:
    """Every execution-free gate. `entry` is the unit's entry point, when known."""
    rep = StaticReport()

    def add(kind: str, severity: str, message: str, line: int = 0, where: str = "") -> None:
        rep.findings.append(Finding(kind, severity, message, line, where))

    try:
        tree = ast.parse(source)
    except SyntaxError as exc:
        add("syntax", "error", f"does not parse: {exc}", getattr(exc, "lineno", 0) or 0)
        return rep

    module_names = _module_names(tree)
    imports_contracts = any(
        isinstance(s, ast.ImportFrom) and s.module == "contracts" for s in tree.body)

    # -- forbidden vocabulary (anywhere in the file) ----------------------------------------
    for n in ast.walk(tree):
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id in FORBIDDEN_MARKERS:
            why = ("returns True unconditionally, so the contract is silently VACUOUS"
                   if n.func.id in ("Implies", "Forall", "ForAll", "Unfold", "Reveal")
                   else "is not defined and raises NameError on every call")
            add("forbidden", "error",
                f"`{n.func.id}` has no Lean mapping and {why}", n.lineno)
        if isinstance(n, ast.Name) and n.id in ("forall", "Old") and isinstance(n.ctx, ast.Load):
            add("forbidden", "error", f"`{n.id}` is not part of the contract vocabulary", n.lineno)

    used_markers = [n for n in ast.walk(tree)
                    if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
                    and n.func.id in CONTRACT_MARKERS]
    rep.n_contracts = len(used_markers)
    if used_markers and not imports_contracts:
        add("import", "error", "uses contract markers but never does `from contracts import *`", 1)
    if not used_markers:
        add("vacuous", "error", "no contracts at all", 1)

    rep.substantive_ensures = substantive_ensures_count(source)
    if rep.substantive_ensures == 0 and used_markers:
        add("vacuous", "error",
            "zero substantive Ensures: nothing non-trivial is claimed about the return value", 1)

    # -- per-function scope / placement -----------------------------------------------------
    def walk_function(fn: ast.AST, enclosing: set[str], top_level: bool) -> None:
        name = getattr(fn, "name", "<module>")
        locals_ = _all_locals(fn)
        params = _arg_names(fn.args) if hasattr(fn, "args") else set()
        loop_vars = _loop_assigned(fn)
        bound = set(enclosing) | params

        def check_expr(marker: str, expr: ast.expr, line: int, bound_now: set[str]) -> None:
            for fname in sorted(free_names(expr)):
                if fname in bound_now or fname in module_names or fname in _BUILTINS:
                    continue
                if fname in locals_:
                    add("scope", "error",
                        f"{marker}(...) reads `{fname}`, a local bound BELOW this line — a contract "
                        "argument is evaluated eagerly, so every call raises UnboundLocalError",
                        line, name)
                else:
                    add("scope", "error", f"{marker}(...) reads unknown name `{fname}`", line, name)
            _check_lowerability(expr, add, line, name, "a contract")
            if marker in ("Ensures",) or (marker == "Assert" and mentions_result(expr)):
                for fname in sorted(free_names(expr) & loop_vars):
                    add("loop_mutated", "error",
                        f"postcondition mentions `{fname}`, which a loop reassigns: Python captures "
                        "its ENTRY value here, Lean reads its FINAL value — take a snapshot "
                        f"(`{fname}_0 = {fname}` above the contracts) and use that instead",
                        line, name)
            if marker != "Ensures" and mentions_result(expr) and marker != "Assert":
                add("result_misuse", "error",
                    f"Result() used inside {marker}(...) — only a postcondition may name it", line, name)

        def walk_body(body: list[ast.stmt], bound_now: set[str], in_loop: bool) -> set[str]:
            for stmt in body:
                got = contract_call(stmt)
                if got:
                    marker, expr = got
                    if marker == "Ensures" and not top_level:
                        add("nested_ensures", "error",
                            "Ensures inside a nested def is attributed to the enclosing entry point "
                            "and read in the wrong scope — hoist the helper or inline the property "
                            "at the call site", stmt.lineno, name)
                    if marker == "Invariant" and not in_loop:
                        add("invariant_placement", "error",
                            "Invariant outside a loop body", stmt.lineno, name)
                    check_expr(marker, expr, stmt.lineno, bound_now)
                    continue
                if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    bound_now = bound_now | {stmt.name}
                    walk_function(stmt, bound_now, top_level=False)
                    continue
                _check_lowerability(stmt, add, stmt.lineno, name, "the body")
                if isinstance(stmt, (ast.For, ast.AsyncFor)):
                    bound_now = bound_now | _target_names(stmt.target)
                    _check_invariant_prefix(stmt, name)
                    walk_body(stmt.body, bound_now, in_loop=True)
                    walk_body(stmt.orelse, bound_now, in_loop)
                elif isinstance(stmt, ast.While):
                    _check_invariant_prefix(stmt, name)
                    walk_body(stmt.body, bound_now, in_loop=True)
                    walk_body(stmt.orelse, bound_now, in_loop)
                elif isinstance(stmt, ast.If):
                    walk_body(stmt.body, bound_now, in_loop)
                    walk_body(stmt.orelse, bound_now, in_loop)
                elif isinstance(stmt, ast.Try):
                    walk_body(stmt.body, bound_now, in_loop)
                    for h in stmt.handlers:
                        walk_body(h.body, bound_now | ({h.name} if h.name else set()), in_loop)
                    walk_body(stmt.orelse, bound_now, in_loop)
                    walk_body(stmt.finalbody, bound_now, in_loop)
                elif isinstance(stmt, (ast.With, ast.AsyncWith)):
                    for item in stmt.items:
                        if item.optional_vars is not None:
                            bound_now = bound_now | _target_names(item.optional_vars)
                    walk_body(stmt.body, bound_now, in_loop)
                bound_now = bound_now | _bindings_of(stmt, descend=False)
            return bound_now

        def _check_invariant_prefix(loop: ast.stmt, where: str) -> None:
            seen_work = False
            for stmt in loop.body:
                got = contract_call(stmt)
                if got and got[0] in ("Invariant", "Decreases"):
                    if seen_work:
                        add("invariant_placement", "warn",
                            f"{got[0]} is not at the top of the loop body — the loop lowering only "
                            "lifts a leading group", stmt.lineno, where)
                elif not (got or isinstance(stmt, ast.Expr) and isinstance(stmt.value, ast.Constant)):
                    seen_work = True

        walk_body(fn.body if hasattr(fn, "body") else [], bound, in_loop=False)

        # Postconditions must not sit between two loops: that is a program-point checkpoint,
        # which a Hoare postcondition cannot express (see `hasMidFunctionPostcondition`).
        if top_level:
            saw_loop = False
            for stmt in fn.body:
                if isinstance(stmt, (ast.For, ast.AsyncFor, ast.While)):
                    saw_loop = True
                    continue
                got = contract_call(stmt)
                if not got:
                    continue
                marker, expr = got
                is_post = marker == "Ensures" or (marker == "Assert" and mentions_result(expr))
                if is_post and saw_loop and any(
                        isinstance(s, (ast.For, ast.AsyncFor, ast.While))
                        for s in fn.body[fn.body.index(stmt):]):
                    add("mid_function", "error",
                        f"{marker} has a loop both before and after it — a postcondition cannot "
                        "describe intermediate state", stmt.lineno, name)

    for stmt in tree.body:
        if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef)):
            walk_function(stmt, module_names, top_level=True)
        elif isinstance(stmt, ast.ClassDef):
            for sub in stmt.body:
                if isinstance(sub, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    walk_function(sub, module_names, top_level=True)

    if entry and entry not in module_names:
        add("entry", "error", f"entry point `{entry}` is not defined at module level", 1)
    return rep


def behaviour_delta(reference: str, annotated: str) -> list[Finding]:
    """Structural drift between the two files: a dropped or renamed definition means the theorem
    would be about a DIFFERENT program than the reference solution."""
    out: list[Finding] = []
    try:
        ref, ann = ast.parse(reference), ast.parse(annotated)
    except SyntaxError:
        return out
    def defs(t: ast.Module) -> set[str]:
        return {n.name for n in t.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef))}
    missing = defs(ref) - defs(ann)
    if missing:
        out.append(Finding("dropped_defs", "error",
                           f"annotated file dropped definitions: {', '.join(sorted(missing))}", 1))
    return out
