"""Execution gates: behaviour identity, contract truth, and mutation score.

Everything here runs the program, so it lives behind a subprocess boundary (`runner.py`) — a
mutant can loop forever or allocate without bound, and a contract file can leave junk in
`sys.modules`.

The awkward bit is `Ensures`. Its argument is evaluated EAGERLY, at the top of the body, where the
return value does not exist — the real shim's `Result()` is `None`, so `Result() % 2` would crash.
So each postcondition is checked twice over: an inert absorbing stand-in during the call (so the
program runs unchanged), then a real re-evaluation afterwards with `Result()` bound to the value
that was actually returned. Only the second one decides anything.
"""

from __future__ import annotations

import ast
import builtins
import signal
import sys
import traceback
import types
from dataclasses import dataclass, field

from .unit import CONTRACT_MARKERS, RESULT_MARKERS, parse_input

RESULT_VAR = "__cqa_result"
_BUILTIN_NAMES = set(dir(builtins))


class ContractViolation(AssertionError):
    """A runtime-checked contract that was false. Subclasses `AssertionError`, so any `except
    AssertionError` in the program under test behaves exactly as it does with the real shim."""

    def __init__(self, marker: str) -> None:
        super().__init__(f"{marker} is false")
        self.marker = marker


class Timeout(Exception):
    pass


def _alarm(_sig, _frm):
    raise Timeout()


def install_alarm() -> None:
    try:
        signal.signal(signal.SIGALRM, _alarm)
    except ValueError:  # pragma: no cover  (not the main thread)
        pass


def _set_timer(seconds: float) -> None:
    try:
        signal.setitimer(signal.ITIMER_REAL, seconds)
    except ValueError:  # pragma: no cover
        pass


# -- the stand-in for Result() while the function is still running ---------------------------

class _Anything:
    """Absorbs every operation. Present only so the eager evaluation of an `Ensures` argument
    cannot change what the function does; the postcondition is judged afterwards, for real."""

    def _same(self, *_a, **_k):
        return self

    __add__ = __radd__ = __sub__ = __rsub__ = __mul__ = __rmul__ = _same
    __truediv__ = __rtruediv__ = __floordiv__ = __rfloordiv__ = _same
    __mod__ = __rmod__ = __pow__ = __rpow__ = _same
    __and__ = __rand__ = __or__ = __ror__ = __xor__ = __rxor__ = _same
    __neg__ = __pos__ = __abs__ = __invert__ = __getitem__ = __call__ = _same

    def __getattr__(self, _name):
        return self._same

    def __len__(self):
        return 0

    def __iter__(self):
        return iter(())

    def __contains__(self, _o):
        return True

    def __bool__(self):
        return True

    def __eq__(self, _o):
        return True

    __ne__ = __lt__ = __le__ = __gt__ = __ge__ = __eq__

    def __hash__(self):
        return 0

    def __str__(self):
        return ""

    def __repr__(self):
        return "<Result()>"


def make_shim() -> types.ModuleType:
    """The `contracts` module as the QA harness needs it.

    `Requires`/`Assume`/`Assert`/`Invariant`/`Decreases` stay asserted, but raise a
    `ContractViolation` naming the marker, so a mutation kill can be attributed. `Ensures` is
    neutralised — its argument is still evaluated (that is how an unbound name is caught) but its
    truth is decided after the call.
    """
    mod = types.ModuleType("contracts")

    def checker(marker: str):
        def check(expr, *_rest):
            if not expr:
                raise ContractViolation(marker)
            return expr
        return check

    for marker in CONTRACT_MARKERS:
        setattr(mod, marker, checker(marker))
    mod.Ensures = lambda _expr=True: True
    mod.Assume = lambda expr=True: None
    mod.Decreases = lambda expr=None, condition=True: True
    mod.Result = lambda: _Anything()
    mod.ResultT = lambda _v=None: _Anything()
    mod.__all__ = [*CONTRACT_MARKERS, *RESULT_MARKERS]
    return mod


# -- postcondition extraction ----------------------------------------------------------------

class _StripResult(ast.NodeTransformer):
    def visit_Call(self, node):  # noqa: N802
        self.generic_visit(node)
        if isinstance(node.func, ast.Name) and node.func.id in RESULT_MARKERS:
            return ast.Name(id=RESULT_VAR, ctx=ast.Load())
        return node


@dataclass
class Postcondition:
    text: str          # source of the clause, with Result() rebound to RESULT_VAR
    line: int
    original: str      # as written, for diagnostics


def postconditions(source: str, entry: str) -> list[Postcondition]:
    """Every `Ensures(...)` in the entry function (plus any `Result()`-bearing `Assert`)."""
    out: list[Postcondition] = []
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return out
    for fn in tree.body:
        if not (isinstance(fn, (ast.FunctionDef, ast.AsyncFunctionDef)) and fn.name == entry):
            continue
        for node in ast.walk(fn):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.args):
                continue
            if node.func.id not in ("Ensures", "Assert"):
                continue
            arg = node.args[0]
            if node.func.id == "Assert" and not any(
                    isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
                    and n.func.id in RESULT_MARKERS for n in ast.walk(arg)):
                continue
            original = ast.unparse(arg)
            rebound = _StripResult().visit(ast.parse(original, mode="eval"))
            out.append(Postcondition(ast.unparse(ast.fix_missing_locations(rebound)),
                                     getattr(node, "lineno", 0), original))
    return out


# -- one program under test -------------------------------------------------------------------

@dataclass
class Program:
    """A loaded module plus the entry point and its postconditions."""

    namespace: dict
    fn: object
    posts: list[Postcondition]
    needs_locals: bool
    error: str | None = None


def load(source: str, entry: str, path: str = "<contracts>", with_shim: bool = True) -> Program:
    if with_shim:
        sys.modules["contracts"] = make_shim()
    ns: dict = {}
    try:
        exec(compile(source, path, "exec"), ns)  # noqa: S102
    except Exception:  # noqa: BLE001
        return Program({}, None, [], False, traceback.format_exc(limit=3))
    fn = ns.get(entry)
    if fn is None:
        return Program(ns, None, [], False, f"entry point `{entry}` is not defined")
    posts = postconditions(source, entry) if with_shim else []
    # Capturing the return frame's locals costs ~10x per call, so only do it when a postcondition
    # actually names something that is neither a parameter nor a global (i.e. a snapshot local).
    params: set[str] = set()
    try:
        import inspect

        params = set(inspect.signature(fn).parameters)
    except (TypeError, ValueError):
        pass
    from .static_gates import free_names

    needs = False
    for p in posts:
        try:
            names = free_names(ast.parse(p.text, mode="eval"))
        except SyntaxError:
            continue
        if names - params - set(ns) - {RESULT_VAR} - _BUILTIN_NAMES:
            needs = True
    return Program(ns, fn, posts, needs)


@dataclass
class CallResult:
    status: str          # "ok" | "contract" | "error" | "timeout"
    value: object = None
    detail: str = ""
    marker: str = ""


def call(prog: Program, args: dict, timeout: float) -> CallResult:
    captured: dict = {}
    entry_name = getattr(prog.fn, "__name__", "")

    def tracer(frame, _event, _arg):
        if frame.f_code.co_name != entry_name:
            return None

        def local(f, ev, _a):
            if ev == "return":
                captured.clear()
                captured.update(f.f_locals)
            return local

        return local

    install_alarm()
    try:
        _set_timer(timeout)
        try:
            if prog.needs_locals:
                sys.settrace(tracer)
            value = prog.fn(**args)
        finally:
            sys.settrace(None)
            _set_timer(0)
    except Timeout:
        return CallResult("timeout", detail=f"exceeded {timeout}s")
    except ContractViolation as exc:
        return CallResult("contract", detail=_where(exc), marker=exc.marker)
    except AssertionError as exc:
        return CallResult("contract", detail=f"assert failed: {exc}", marker="assert")
    except Exception as exc:  # noqa: BLE001
        return CallResult("error", detail=f"{type(exc).__name__}: {exc}")
    res = CallResult("ok", value=value)
    res.detail = ""
    setattr(res, "locals", captured)
    return res


def _where(exc: BaseException) -> str:
    frames = traceback.extract_tb(exc.__traceback__)
    for fr in reversed(frames):
        if fr.filename in ("<contracts>", "<mutant>"):
            return f"{exc.args[0]} at line {fr.lineno}: {(fr.line or '').strip()}"
    return str(exc.args[0] if exc.args else exc)


def check_posts(prog: Program, args: dict, result: CallResult) -> tuple[str, str]:
    """`("ok", "")`, `("ensures_false", clause)` or `("ensures_error", detail)`."""
    local_vars = getattr(result, "locals", {}) or {}
    for p in prog.posts:
        # Entry arguments win over captured locals: a parameter the body mutates must read as it
        # was PASSED, which is how Lean's snapshot substitution resolves it.
        scope = {**prog.namespace, **local_vars, **args, RESULT_VAR: result.value}
        try:
            val = eval(p.text, scope)  # noqa: S307  (our own source)
        except Exception as exc:  # noqa: BLE001
            return "ensures_error", f"line {p.line}: {p.original}  ({type(exc).__name__}: {exc})"
        if not val:
            return "ensures_false", f"line {p.line}: {p.original}"
    return "ok", ""


# -- the reference oracle ----------------------------------------------------------------------

@dataclass
class Oracle:
    """What the untouched `solution.py` does on each recorded input."""

    args: list[dict | None] = field(default_factory=list)
    values: list[object] = field(default_factory=list)
    usable: list[int] = field(default_factory=list)   # indices with a reference value
    error: str | None = None
    recorded: list[str] = field(default_factory=list)


def build_oracle(reference: str, entry: str, tests: list[dict], timeout: float) -> Oracle:
    prog = load(reference, entry, path="<reference>", with_shim=False)
    if prog.error:
        return Oracle(error=prog.error)
    orc = Oracle()
    for t in tests:
        args = parse_input(t["input"], prog.namespace)
        orc.args.append(args)
        orc.recorded.append(t.get("output", ""))
        if args is None:
            orc.values.append(None)
            continue
        res = call(prog, dict(args), timeout)
        orc.values.append(res.value if res.status == "ok" else None)
        if res.status == "ok":
            orc.usable.append(len(orc.values) - 1)
    return orc


def same(a: object, b: object) -> bool:
    """Contracts are no-ops and a mutant is a different program, so identity of behaviour is
    exact equality — with a repr fallback for values that do not compare cleanly."""
    try:
        r = a == b
        if isinstance(r, bool):
            return r
        return bool(r)
    except Exception:  # noqa: BLE001
        return repr(a) == repr(b)


# -- gate 2: behaviour identity + contract truth ------------------------------------------------

def verify(source: str, entry: str, oracle: Oracle, tests: list[dict],
           timeout: float = 10.0, max_problems: int = 4) -> dict:
    prog = load(source, entry, path="<contracts>")
    if prog.error:
        return {"ok": False, "stage": "import", "problems": [prog.error],
                "n_tests": len(tests), "n_ok": 0, "n_posts": 0}
    problems: list[str] = []
    n_ok = 0
    for i in range(len(oracle.args)):
        args = oracle.args[i]
        if args is None:
            problems.append(f"UNPARSABLE INPUT {tests[i]['input']!r}")
            continue
        res = call(prog, dict(args), timeout)
        if res.status == "timeout":
            problems.append(f"TIMEOUT on {tests[i]['input']}")
        elif res.status == "contract":
            problems.append(f"CONTRACT FALSE ({res.marker}) on {tests[i]['input']}: {res.detail}")
        elif res.status == "error":
            problems.append(f"RAISES on {tests[i]['input']}: {res.detail}")
        else:
            if i in oracle.usable and not same(res.value, oracle.values[i]):
                problems.append(f"BEHAVIOUR DIFFERS from solution.py on {tests[i]['input']}: "
                                f"contracted returned {res.value!r}, reference {oracle.values[i]!r}")
            elif not (repr(res.value) == oracle.recorded[i] or str(res.value) == oracle.recorded[i]
                      or i in oracle.usable):
                problems.append(f"OUTPUT MISMATCH on {tests[i]['input']}: got {res.value!r} "
                                f"want {oracle.recorded[i]}")
            else:
                kind, detail = check_posts(prog, dict(args), res)
                if kind == "ensures_false":
                    problems.append(f"ENSURES FALSE on {tests[i]['input']}: {detail}  "
                                    f"(Result() = {res.value!r})")
                elif kind == "ensures_error":
                    problems.append(f"ENSURES UNEVALUABLE on {tests[i]['input']}: {detail}")
                else:
                    n_ok += 1
        if len(problems) >= max_problems:
            break
    return {"ok": not problems and n_ok > 0, "stage": "dynamic", "problems": problems,
            "n_tests": len(tests), "n_ok": n_ok, "n_posts": len(prog.posts)}


# -- gate 3: mutation score ---------------------------------------------------------------------

def score_mutants(mutants, entry: str, oracle: Oracle, tests: list[dict],
                  timeout: float = 2.0, test_budget: int = 12) -> dict:
    """Run each mutant against the contracts. A mutant is

        KILLED     — some contract fired, or some `Ensures` was false;
        SURVIVED   — it returned a WRONG answer that every contract accepted (the damning case);
        CRASHED    — it only ever raised or hung, so the spec never got a say;
        EQUIVALENT — no recorded input tells it apart from the reference.

    The score is KILLED / (KILLED + SURVIVED): crashed and equivalent mutants are excluded, which
    is the conservative reading — a spec is never credited for a mutant it was not given a chance
    to reject, and never penalised for one that is not actually wrong.
    """
    idx = oracle.usable[:test_budget] or list(range(min(test_budget, len(oracle.args))))
    counts = {"killed": 0, "survived": 0, "crashed": 0, "equivalent": 0, "broken": 0}
    survivors: list[dict] = []
    killed_by: dict[str, int] = {}
    for m in mutants:
        prog = load(m.source, entry, path="<mutant>")
        if prog.error:
            counts["broken"] += 1
            continue
        verdict, note, marker = "equivalent", "", ""
        for i in idx:
            args = oracle.args[i]
            if args is None:
                continue
            res = call(prog, dict(args), timeout)
            if res.status == "contract":
                verdict, marker, note = "killed", res.marker, res.detail
                break
            if res.status == "ok":
                kind, detail = check_posts(prog, dict(args), res)
                if kind != "ok":
                    verdict, marker, note = "killed", "Ensures", detail
                    break
                if not same(res.value, oracle.values[i]):
                    verdict = "survived"
                    note = (f"on {tests[i]['input']}: returned {res.value!r}, "
                            f"correct is {oracle.values[i]!r}")
            elif verdict == "equivalent":
                verdict, note = "crashed", res.detail
        counts[verdict] += 1
        if verdict == "killed":
            killed_by[marker] = killed_by.get(marker, 0) + 1
        elif verdict == "survived" and len(survivors) < 8:
            survivors.append({"op": m.op, "description": m.description, "line": m.line,
                              "evidence": note})
    effective = counts["killed"] + counts["survived"]
    return {"n_mutants": sum(counts.values()), **counts, "effective": effective,
            "score": (counts["killed"] / effective) if effective else None,
            "killed_by": killed_by, "survivors": survivors}
