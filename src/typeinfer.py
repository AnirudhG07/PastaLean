"""`pastalean typeinfer` — surface the TypeInfer engine's inferences for one Python file.

The engine itself is the compiled Lean `typeinfer` binary (see `backend/typeinfer.py`); this module
is the production front-end around it:

    Python source --(node_visitor)--> JSON IR --(typeinfer exe)--> type-stamped AST
                                                    |
                        +-------------------------- +-------------------------+
                        v                           v                         v
                  annotated .py                JSON of types            human report

The engine stamps each assignment target / parameter / class field with a `_ty` (or `_bench_ty`)
annotation node and each function with a return-type stamp (`_ret_ty` / `_bench_ret_ty` /
`_ret_float`). `collect_types` walks that stamped AST into scope-keyed records, `render_pytype` turns
one annotation node into a Python type string (`list[int]`, `Optional[str]`, `Callable`, `Any`), and
the three formatters render those records.
"""

from __future__ import annotations

import ast as _ast
import json
import re
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

from .backend.typeinfer import infer_ast, infer_repo
from .transpile import driver

MODULE_SCOPE = "<module>"

# Lean runtime type names -> the Python type a user expects to read.
_SCALAR_PY = {
    "Int": "int", "Nat": "int", "int": "int",
    "String": "str", "Char": "str", "str": "str",
    "Bool": "bool", "bool": "bool",
    "Float": "float", "Rat": "float", "Real": "float", "float": "float", "complex": "complex",
    "None": "None", "NoneType": "None", "Nonetype": "None", "Unit": "None",
    "bytes": "bytes",
}
_CONTAINER_PY = {
    "List": "list", "list": "list",
    "Dict": "dict", "dict": "dict", "Std.HashMap": "dict",
    "PyDefaultDict": "defaultdict", "Counter": "Counter",
    "Set": "set", "set": "set", "frozenset": "frozenset",
    "Tuple": "tuple", "tuple": "tuple",
    "deque": "deque",
}


def render_pytype(node) -> str | None:
    """A TypeInfer `_ty` annotation node -> a Python type string, or None when it carries no
    information (an un-inferred `PyAny` reads as `Any`; a truly empty node is None)."""
    if not isinstance(node, dict):
        return None
    nt = node.get("node_type")
    if nt == "Name":
        rid = node.get("id")
        if not rid:
            return None
        if rid in ("PyAny", "Any"):
            return "Any"
        if rid in ("Callable", "callable", "function"):
            return "Callable"
        if rid in _SCALAR_PY:
            return _SCALAR_PY[rid]
        if rid in _CONTAINER_PY:
            return _CONTAINER_PY[rid]
        return rid.split(".")[-1]  # a user class name (strip any namespace)
    if nt == "Constant":
        return "None" if node.get("value") is None else None
    if nt == "Attribute":
        return node.get("attr")
    if nt == "Tuple":
        parts = [render_pytype(e) or "Any" for e in node.get("elts", [])]
        return "tuple[" + ", ".join(parts) + "]" if parts else "tuple"
    if nt == "Subscript":
        base = node.get("value")
        sl = node.get("slice")
        bid = base.get("id") if isinstance(base, dict) else None
        if bid in ("Optional", "Option"):
            return f"Optional[{render_pytype(sl) or 'Any'}]"
        base_str = render_pytype(base) or (bid.split(".")[-1] if bid else None)
        if base_str is None:
            return None
        if isinstance(sl, dict) and sl.get("node_type") == "Tuple":
            args = ", ".join(render_pytype(e) or "Any" for e in sl.get("elts", []))
        else:
            args = render_pytype(sl) or "Any"
        return f"{base_str}[{args}]"
    return None


# --- records --------------------------------------------------------------------------------------

@dataclass
class FuncInfo:
    qualname: str
    params: dict[str, str] = field(default_factory=dict)
    returns: str | None = None


@dataclass
class VarInfo:
    name: str          # display name (SSA version rendered as `__N`)
    type: str
    scope: str
    base: str = ""     # the original Python identifier, for matching the untouched source


@dataclass
class FieldInfo:
    cls: str
    name: str
    type: str


@dataclass
class InferResult:
    functions: list[FuncInfo] = field(default_factory=list)
    variables: list[VarInfo] = field(default_factory=list)
    fields: list[FieldInfo] = field(default_factory=list)


_SUBSCRIPTS = "₀₁₂₃₄₅₆₇₈₉"
_SUB_TO_ASCII = str.maketrans(_SUBSCRIPTS, "0123456789")


def _base(name: str) -> str:
    """Strip TypeInfer's SSA version suffix (`total'v1`, `total₀` -> `total`) so a name aligns with
    the original Python identifier — used to match the untouched source."""
    if not isinstance(name, str):
        return name
    return name.split("'")[0].rstrip(_SUBSCRIPTS)


def _display_name(name: str) -> str:
    """A readable display name: the SSA subscript version suffix becomes ASCII `__N` (`total₀` ->
    `total__0`), so distinct type-versions of one Python variable stay visible and distinct."""
    if not isinstance(name, str):
        return name
    name = name.split("'")[0]
    i = len(name)
    while i > 0 and name[i - 1] in _SUBSCRIPTS:
        i -= 1
    return name[:i] + "__" + name[i:].translate(_SUB_TO_ASCII) if i < len(name) else name


def _ann_of(node: dict):
    return node.get("_ty") or node.get("_bench_ty")


# --- collect stamped types into scope-keyed records ----------------------------------------------

def collect_types(stamped: dict) -> InferResult:
    """Walk a type-stamped AST into `InferResult`. Variables are first-write-wins within a scope
    (the type at the point a name is introduced), matching how the annotated source reads."""
    res = InferResult()
    seen_var: set[tuple[str, str]] = set()

    def add_var(raw: str, ann, scope: str) -> None:
        t = render_pytype(ann)
        if not t:
            return
        display = _display_name(raw)
        key = (scope, display)
        if key in seen_var:
            return
        seen_var.add(key)
        res.variables.append(VarInfo(display, t, scope, _base(raw)))

    def collect_target(t, scope: str, cls: str | None) -> None:
        if not isinstance(t, dict):
            return
        nt = t.get("node_type")
        if nt == "Name":
            add_var(t.get("id") or "", _ann_of(t), scope)
        elif nt == "Attribute":
            ann = _ann_of(t)
            v = t.get("value")
            base_id = v.get("id") if isinstance(v, dict) else None
            if ann and base_id == "self" and cls and t.get("attr"):
                res.fields.append(FieldInfo(cls, t["attr"], render_pytype(ann) or "Any"))
        elif nt == "Starred":
            collect_target(t.get("value"), scope, cls)
        elif nt in ("Tuple", "List"):
            for e in t.get("elts", []):
                collect_target(e, scope, cls)

    def walk(o, scope: str, cls: str | None) -> None:
        if isinstance(o, dict):
            nt = o.get("node_type")
            if nt in ("FunctionDef", "AsyncFunctionDef"):
                qual = (scope + "." if scope else "") + _base(o.get("name") or "")
                info = FuncInfo(qual)
                for a in o.get("args", {}).get("args", []):
                    pname = _base(a.get("arg") or "")
                    if pname in ("self", "cls"):
                        continue
                    t = render_pytype(_ann_of(a))
                    if t:
                        info.params[pname] = t
                if o.get("_ret_float") is True:
                    info.returns = "float"
                else:
                    info.returns = render_pytype(o.get("_ret_ty") or o.get("_bench_ret_ty"))
                res.functions.append(info)
                for v in o.values():
                    walk(v, qual, cls)  # a nested def/var is scoped under this function
                return
            if nt == "ClassDef":
                name = (scope + "." if scope else "") + (o.get("name") or "")
                for f in o.get("fields", []):
                    if not isinstance(f, dict) or not f.get("name"):
                        continue
                    ann = _ann_of(f) or f.get("annotation")
                    t = render_pytype(ann) if isinstance(ann, dict) else None
                    if t:
                        res.fields.append(FieldInfo(name, f["name"], t))
                for v in o.values():
                    walk(v, name, name)
                return
            if nt in ("Assign", "AnnAssign", "AugAssign", "For"):
                collect_target(o.get("target"), scope, cls)
                for tg in o.get("targets", []):
                    collect_target(tg, scope, cls)
            for v in o.values():
                walk(v, scope, cls)
        elif isinstance(o, list):
            for v in o:
                walk(v, scope, cls)

    walk(stamped, "", None)
    # De-dup fields (a field can be stamped both class-level and in __init__); keep the first.
    seen_field: set[tuple[str, str]] = set()
    deduped = []
    for f in res.fields:
        if (f.cls, f.name) not in seen_field:
            seen_field.add((f.cls, f.name))
            deduped.append(f)
    res.fields = deduped
    return res


# --- run inference for a file --------------------------------------------------------------------

def infer_source(source: str, path: str | None = None) -> InferResult:
    """Parse `source` to JSON IR (pure Python front-end, no backend boot), run the standalone
    `typeinfer` engine over it, and collect the stamped types."""
    ir = json.loads(driver.translate_to_json(source, path, best_effort=True, infer_only=True))
    return collect_types(infer_ast(ir))


def infer_file(path: str | Path) -> InferResult:
    path = Path(path)
    return infer_source(path.read_text(encoding="utf-8"), str(path))


# --- repo / directory level ----------------------------------------------------------------------

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


def annotate_repo(repo: Path, out_dir: Path, *, include_any: bool = True) -> tuple[int, int, dict[str, int]]:
    """Copy `repo` to `out_dir` and overwrite each `.py` with its inferred-type-annotated version.
    Returns (files_annotated, total_repo_files, aggregate annotation counts)."""
    import shutil

    inferred = infer_repo_dir(repo)
    if out_dir.resolve() != repo.resolve():
        if out_dir.exists():
            shutil.rmtree(out_dir)
        shutil.copytree(repo, out_dir)
    n_files = 0
    totals = {"params": 0, "returns": 0, "variables": 0, "fields": 0}
    for _dotted, (src, result) in inferred.items():
        rel = src.relative_to(repo)
        try:
            annotated = annotate_source(src.read_text(encoding="utf-8"), result, include_any=include_any)
            (out_dir / rel).write_text(annotated, encoding="utf-8")
            n_files += 1
            for k, v in count_annotations(result, include_any=include_any).items():
                totals[k] += v
        except (SyntaxError, OSError):  # noqa: PERF203
            continue
    return n_files, len(inferred), totals


# --- annotation counts + summary report ----------------------------------------------------------

def count_annotations(result: InferResult, *, include_any: bool = True) -> dict[str, int]:
    """How many annotations the engine produced per dimension — the ones the annotated source
    actually injects for the same `include_any` setting."""
    def wanted(t: str | None) -> bool:
        return bool(t) and (include_any or t != "Any")
    return {
        "params": sum(1 for f in result.functions for t in f.params.values() if wanted(t)),
        "returns": sum(1 for f in result.functions if wanted(f.returns)),
        "variables": sum(1 for v in result.variables if wanted(v.type)),
        "fields": sum(1 for f in result.fields if wanted(f.type)),
    }


def format_stats_report(path: str, counts: dict[str, int], elapsed: float,
                        files: tuple[int, int] | None = None) -> str:
    """The `--report` summary: annotation counts per dimension and wall-clock time."""
    lines = ["TypeInfer Report", f"Path: {path}"]
    if files is not None:
        lines.append(f"Files annotated: {files[0]}/{files[1]}")
    lines += [
        f"Function Parameter Types: {counts['params']}",
        f"Function Return Types: {counts['returns']}",
        f"Local Variable Types: {counts['variables']}",
        f"Class Field Types: {counts['fields']}",
        f"Total Annotations: {sum(counts.values())}",
        f"Time Taken: {elapsed:.3f}s",
    ]
    return "\n".join(lines)


# --- output formats ------------------------------------------------------------------------------

def to_json_obj(result: InferResult, path: str | None = None) -> dict:
    obj: dict = {}
    if path is not None:
        obj["file"] = path
    obj["functions"] = [
        {"name": f.qualname, "params": f.params, "returns": f.returns} for f in result.functions
    ]
    obj["variables"] = [
        {"name": v.name, "scope": v.scope or MODULE_SCOPE, "type": v.type} for v in result.variables
    ]
    obj["fields"] = [{"class": f.cls, "name": f.name, "type": f.type} for f in result.fields]
    return obj


def to_report(result: InferResult, path: str | None = None) -> str:
    lines: list[str] = []
    if path:
        lines.append(f"Type inference for {path}")
        lines.append("=" * len(lines[-1]))
        lines.append("")

    if result.functions:
        lines.append("Functions")
        for f in result.functions:
            sig = ", ".join(f"{n}: {t}" for n, t in f.params.items())
            ret = f" -> {f.returns}" if f.returns else ""
            lines.append(f"  {f.qualname}({sig}){ret}")
        lines.append("")

    if result.fields:
        lines.append("Class fields")
        for f in result.fields:
            lines.append(f"  {f.cls}.{f.name}: {f.type}")
        lines.append("")

    if result.variables:
        lines.append("Variables")
        by_scope: dict[str, list[VarInfo]] = defaultdict(list)
        for v in result.variables:
            by_scope[v.scope or MODULE_SCOPE].append(v)
        for scope in sorted(by_scope, key=lambda s: (s != MODULE_SCOPE, s)):
            lines.append(f"  [{scope}]")
            for v in by_scope[scope]:
                lines.append(f"    {v.name}: {v.type}")
        lines.append("")

    if not (result.functions or result.fields or result.variables):
        lines.append("(no types inferred)")
    return "\n".join(lines).rstrip()


def _type_expr(type_str: str):
    """Parse a rendered type string into an AST annotation expression, falling back to a string
    literal for anything unparseable."""
    try:
        return _ast.parse(type_str, mode="eval").body
    except SyntaxError:
        return _ast.Constant(value=type_str)


_TYPING_NAMES = ("Any", "Optional", "Callable")


def _note_typing(type_str: str, used: set[str]) -> None:
    for name in _TYPING_NAMES:
        if re.search(rf"\b{name}\b", type_str):
            used.add(name)


def _ensure_typing_imports(tree: _ast.Module, used: set[str]) -> None:
    """Add `from typing import ...` for any Any/Optional/Callable the annotations reference and that
    isn't imported already (extending an existing typing import, or inserting a new one after the
    module docstring / `__future__` imports)."""
    if not used:
        return
    existing = None
    imported: set[str] = set()
    for stmt in tree.body:
        if isinstance(stmt, _ast.ImportFrom) and stmt.module == "typing":
            existing = stmt
            imported |= {a.name for a in stmt.names}
    missing = sorted(used - imported)
    if not missing:
        return
    if existing is not None:
        existing.names += [_ast.alias(name=n) for n in missing]
        return
    idx = 0
    if (tree.body and isinstance(tree.body[0], _ast.Expr)
            and isinstance(tree.body[0].value, _ast.Constant)
            and isinstance(tree.body[0].value.value, str)):
        idx = 1  # keep a module docstring first
    while (idx < len(tree.body) and isinstance(tree.body[idx], _ast.ImportFrom)
           and tree.body[idx].module == "__future__"):
        idx += 1
    tree.body.insert(idx, _ast.ImportFrom(module="typing",
                                          names=[_ast.alias(name=n) for n in missing], level=0))


def annotate_source(source: str, result: InferResult, *, include_any: bool = True) -> str:
    """Return `source` with the inferred types injected as PEP 484 annotations. Re-parses the
    original with `ast` (which has the positions the IR lacks) and matches the engine's records by
    qualified name, then `ast.unparse`s the result — so comments and exact spacing are not preserved,
    but the code is a faithful annotated view. `include_any` (default True) also stamps bare `Any`
    and adds the needed `from typing import Any`; `--no-any` sets it False."""
    tree = _ast.parse(source)
    func_by_qual = {f.qualname: f for f in result.functions}
    var_by_scope: dict[str, dict[str, str]] = defaultdict(dict)
    for v in result.variables:
        var_by_scope[v.scope].setdefault(v.base or v.name, v.type)
    field_by_cls: dict[str, dict[str, str]] = defaultdict(dict)
    for f in result.fields:
        field_by_cls[f.cls].setdefault(f.name, f.type)

    scope: list[str] = []  # enclosing def/class names -> the collector's qualname
    annotated_vars: set[tuple[str, str]] = set()
    used_typing: set[str] = set()

    def qual() -> str:
        return ".".join(scope)

    def wanted(t: str | None) -> bool:
        return bool(t) and (include_any or t != "Any")

    def expr(t: str):
        _note_typing(t, used_typing)
        return _type_expr(t)

    class Annotator(_ast.NodeTransformer):
        def visit_FunctionDef(self, node: _ast.FunctionDef):
            scope.append(node.name)
            info = func_by_qual.get(qual())
            if info:
                for a in list(node.args.posonlyargs) + list(node.args.args) + list(node.args.kwonlyargs):
                    t = info.params.get(a.arg)
                    if a.annotation is None and wanted(t):
                        a.annotation = expr(t)
                if node.returns is None and wanted(info.returns):
                    node.returns = expr(info.returns)
            self.generic_visit(node)
            scope.pop()
            return node

        visit_AsyncFunctionDef = visit_FunctionDef

        def visit_ClassDef(self, node: _ast.ClassDef):
            scope.append(node.name)
            self.generic_visit(node)
            scope.pop()
            return node

        def visit_Assign(self, node: _ast.Assign):
            self.generic_visit(node)
            if len(node.targets) != 1:
                return node
            tgt = node.targets[0]
            # `self.x = ...` inside a method -> annotate the field.
            if (isinstance(tgt, _ast.Attribute) and isinstance(tgt.value, _ast.Name)
                    and tgt.value.id == "self" and len(scope) >= 2):
                cls = ".".join(scope[:-1])
                t = field_by_cls.get(cls, {}).get(tgt.attr)
                if wanted(t):
                    return _ast.AnnAssign(target=tgt, annotation=expr(t), value=node.value, simple=0)
                return node
            if isinstance(tgt, _ast.Name):
                key = (qual(), tgt.id)
                if key in annotated_vars:
                    return node
                t = var_by_scope.get(qual(), {}).get(tgt.id)
                if wanted(t):
                    annotated_vars.add(key)
                    return _ast.AnnAssign(target=tgt, annotation=expr(t), value=node.value, simple=1)
            return node

    Annotator().visit(tree)
    _ensure_typing_imports(tree, used_typing)
    _ast.fix_missing_locations(tree)
    return _ast.unparse(tree)
