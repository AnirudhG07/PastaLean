import PastaLean.PyGens.Core.Utils

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-!
## Syntactic desugaring of the JSON IR

Rewrites that turn Python-only syntax into shapes the lowering already handles. All run once per
translation request, before codegen (see `py2lean.lean`).

* **Nested `for` targets.** `for i, (a, b) in xs` binds a tuple element, but the `for` lowering only
  binds plain names. Tuple *assignment* already handles nesting, so rewrite to
  `for i, __for_unpack_1 in xs` with `a, b = __for_unpack_1` at the top of the body.

* **Unbounded iterators.** `for k in count(1):` has no finite `List` to iterate, so it becomes a
  `while True` whose body starts by advancing `k`. Which library members are unbounded is declared
  by the library (`Libraries.libraryInfiniteIter?`), not listed here.

* **The walrus operator.** `if (y := e) in d:` becomes `y = e` followed by `if y in d:`. Hoisting is
  only sound where the expression is evaluated exactly once and unconditionally, so a walrus in a
  `while` test, in an `and`/`or` operand, in an `if`-expression, or in a comprehension/lambda is
  rejected — hoisting there would change *when* the expression runs.
-/

/-- Desugaring threads a counter for the fresh names it introduces, and fails with a message. -/
abbrev DesugarM := StateT Nat (Except String)

private def freshVar (stem : String) : DesugarM String := do
  let n ← get
  set (n + 1)
  return s!"{stem}{n + 1}"

private def nameLoad (id : String) : Json :=
  Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str id)]

private def assignStmt (target value : Json) : Json :=
  Json.mkObj [("node_type", Json.str "Assign"), ("target", target), ("value", value)]

private def isTupleTarget (json : Json) : Bool :=
  jsonNodeType? json == some "Tuple" || jsonNodeType? json == some "List"

/-- Rewrite every statement list (`body`/`orelse`/`finalbody`) in `json` with `f`, innermost first. -/
partial def rewriteStatementLists (f : Array Json → DesugarM (Array Json)) (json : Json) :
    DesugarM Json := do
  match json with
  | .arr elems => return Json.arr (← elems.mapM (rewriteStatementLists f))
  | .obj fields =>
      let mut rewritten := []
      for (key, value) in fields.toList do
        let value ← rewriteStatementLists f value
        let value ←
          if key == "body" || key == "orelse" || key == "finalbody" then
            match value with
            | .arr stmts => pure (Json.arr (← f stmts))
            | _ => pure value
          else pure value
        rewritten := rewritten ++ [(key, value)]
      return Json.mkObj rewritten
  | _ => return json

/-! ### Nested `for` targets -/

/-- Emit `target = value` as assignments whose tuple targets contain no further tuples. The tuple
targets are stamped `_tuple_unpack` — a nested for-target (`for i, (a, b) in enumerate(zip(…))`)
unpacks a `Prod`, so codegen must use `Prod.fst`/`Prod.snd`, not list indexing. -/
partial def flattenAssign (target value : Json) : DesugarM (Array Json) := do
  unless isTupleTarget target do return #[assignStmt target value]
  let tupleUnpack (t : Json) : Json := t.setObjVal! "_tuple_unpack" (Json.bool true)
  let elts := (target.getObjValAs? (Array Json) "elts").toOption.getD #[]
  unless elts.any isTupleTarget do return #[assignStmt (tupleUnpack target) value]
  let mut flatElts := #[]
  let mut deferred := #[]
  for elt in elts do
    if isTupleTarget elt then
      let name ← freshVar "__for_unpack_"
      flatElts := flatElts.push (nameLoad name)
      deferred := deferred.push (elt, nameLoad name)
    else
      flatElts := flatElts.push elt
  let mut stmts := #[assignStmt (tupleUnpack (target.setObjVal! "elts" (Json.arr flatElts))) value]
  for (nestedTarget, tempName) in deferred do
    stmts := stmts ++ (← flattenAssign nestedTarget tempName)
  return stmts

/-- `for i, (a, b) in xs:` → `for i, t in xs:` with `a, b = t` prepended to the body. Targets with
`*rest` are left alone; starred unpacking is unsupported and its own error is clearer. -/
def flattenForTargets (stmts : Array Json) : DesugarM (Array Json) := do
  stmts.mapM fun stmt => do
    unless jsonNodeType? stmt == some "For" do return stmt
    let .ok target := stmt.getObjVal? "target" | return stmt
    unless isTupleTarget target do return stmt
    if jsonContainsNodeType target ["Starred"] then return stmt
    let elts := (target.getObjValAs? (Array Json) "elts").toOption.getD #[]
    unless elts.any isTupleTarget do return stmt
    -- A subscript/attribute element is not something this pass can name; leave the diagnostic to
    -- the `for` lowering.
    if elts.any (fun e => jsonNodeType? e != some "Name" && !isTupleTarget e) then return stmt

    let mut flatElts := #[]
    let mut unpacks := #[]
    for elt in elts do
      if isTupleTarget elt then
        let name ← freshVar "__for_unpack_"
        flatElts := flatElts.push (nameLoad name)
        unpacks := unpacks ++ (← flattenAssign elt (nameLoad name))
      else
        flatElts := flatElts.push elt
    let body := (stmt.getObjValAs? (Array Json) "body").toOption.getD #[]
    return (stmt.setObjVal! "target" (target.setObjVal! "elts" (Json.arr flatElts))).setObjVal!
      "body" (Json.arr (unpacks ++ body))

/-! ### Walrus -/

/-- Contexts that evaluate their operands conditionally or repeatedly, so a walrus inside them
cannot be hoisted without changing evaluation order. -/
private def conditionalContexts : Array String :=
  #["BoolOp", "IfExp", "Lambda", "ListComp", "SetComp", "DictComp", "GeneratorExp"]

/-- Is there a `NamedExpr` beneath a node of type `context` anywhere in `json`? -/
private partial def hasWalrusUnder (context : String) (json : Json) : Bool :=
  if jsonNodeType? json == some context && jsonContainsNodeType json ["NamedExpr"] then true
  else match json with
    | .arr elems => elems.any (hasWalrusUnder context)
    | .obj fields => fields.toList.any (fun (_, v) => hasWalrusUnder context v)
    | _ => false

private def guardHoistable (expr : Json) : DesugarM Unit := do
  for context in conditionalContexts do
    if hasWalrusUnder context expr then
      throw s!"walrus inside {context} is evaluated conditionally; hoisting it would change \
        evaluation order."

/-- Replace each `NamedExpr` in `expr` with its target name, returning the assignments that must
run before the enclosing statement. Nested walruses bind first. -/
partial def hoistWalrusExpr (expr : Json) : DesugarM (Json × Array Json) := do
  match expr with
  | .arr elems =>
      let mut out := #[]
      let mut prelude := #[]
      for elem in elems do
        let (elem, pre) ← hoistWalrusExpr elem
        out := out.push elem
        prelude := prelude ++ pre
      return (Json.arr out, prelude)
  | .obj fields =>
      if jsonNodeType? expr == some "NamedExpr" then
        let .ok target := expr.getObjVal? "target" | throw "NamedExpr is missing a 'target'"
        let .ok value := expr.getObjVal? "value" | throw "NamedExpr is missing a 'value'"
        let (value, prelude) ← hoistWalrusExpr value
        let .ok id := target.getObjValAs? String "id"
          | throw "walrus target must be a plain name"
        return (nameLoad id, prelude.push (assignStmt target value))
      let mut rewritten := []
      let mut prelude := #[]
      for (key, value) in fields.toList do
        let (value, pre) ← hoistWalrusExpr value
        prelude := prelude ++ pre
        rewritten := rewritten ++ [(key, value)]
      return (Json.mkObj rewritten, prelude)
  | _ => return (expr, #[])

/-- The field of a statement whose expression is evaluated exactly once, before its body. -/
private def hoistableField (stmt : Json) : Option String :=
  match jsonNodeType? stmt with
  | some "If" | some "Assert" => some "test"
  | some "Return" | some "Assign" | some "AugAssign" | some "AnnAssign" | some "Expr" => some "value"
  | some "For" => some "iter"
  | _ => none

/-- Hoist every walrus out of a statement list. -/
def hoistWalrus (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    unless jsonContainsNodeType stmt ["NamedExpr"] do
      out := out.push stmt
      continue
    if jsonNodeType? stmt == some "While" then
      if (stmt.getObjVal? "test").toOption.any (jsonContainsNodeType · ["NamedExpr"]) then
        throw "walrus in a `while` test is re-evaluated each iteration and cannot be hoisted."
    let mut stmt := stmt
    if let some field := hoistableField stmt then
      if let .ok expr := stmt.getObjVal? field then
        if jsonContainsNodeType expr ["NamedExpr"] then
          guardHoistable expr
          let (expr, prelude) ← hoistWalrusExpr expr
          out := out ++ prelude
          stmt := stmt.setObjVal! field expr
    -- Nested statement lists were already rewritten; anything left is in a position we cannot hoist.
    let bodyless := #["body", "orelse", "finalbody"].foldl
      (fun (j : Json) key => j.setObjVal! key (Json.arr #[])) stmt
    if jsonContainsNodeType bodyless ["NamedExpr"] then
      throw s!"walrus in an unsupported position ({(jsonNodeType? stmt).getD "?"})."
    out := out.push stmt
  return out

/-! ### Chained assignment -/

/-- `a = b = expr` (an `Assign` carrying a `targets` list) → evaluate `expr` once into a temporary,
then assign that temporary to each target in turn. This keeps `expr`'s side effects single and works
for any target shape (names, subscripts, tuples). -/
def splitChainedAssign (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    match (do
      guard (jsonNodeType? stmt == some "Assign")
      stmt.getObjValAs? (Array Json) "targets" |>.toOption) with
    | some targets =>
        let .ok value := stmt.getObjVal? "value" | out := out.push stmt; continue
        let tmp ← freshVar "__chain_"
        out := out.push (assignStmt (nameLoad tmp) value)
        for target in targets do
          out := out.push (assignStmt target (nameLoad tmp))
    | none => out := out.push stmt
  return out

/-- NOT YET WIRED (see below). `a, (b, c) = …` → flatten the nested tuple target into a
temporary plus a second unpack, so
codegen only ever sees tuple targets whose elements are names or subscripts. `flattenAssign` already
does the work; this applies it to plain assignments (it was only wired into `for` targets).

Left out of `desugarAst` for now: the second unpack (`b, c = tmp`) still lowers with list indexing
because `_tuple_unpack` is not stamped on it, so the result compiles worse than the clean
"unsupported nested target" error it replaces. Wire it once that stamp fires here. -/
def flattenAssignTargets (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    match (do
      guard (jsonNodeType? stmt == some "Assign")
      let t ← (stmt.getObjVal? "target").toOption
      let v ← (stmt.getObjVal? "value").toOption
      guard (isTupleTarget t)
      guard (((t.getObjValAs? (Array Json) "elts").toOption.getD #[]).any isTupleTarget)
      pure (t, v)) with
    | some (t, v) => out := out ++ (← flattenAssign t v)
    | none => out := out.push stmt
  return out

/-! ### Value-and-mutate calls in sub-expression position -/

/-- `container.pop(...)` / `.popleft()`: yields a value AND mutates its receiver, so it cannot be an
ordinary sub-expression (the two effects need separate statements). -/
private def isValueMutateCall (j : Json) : Bool :=
  jsonNodeType? j == some "Call" &&
    (match (j.getObjVal? "func").toOption with
     | some f =>
         -- METHOD form on a plain receiver: `xs.pop(i)`, `dq.popleft()`.
         (jsonNodeType? f == some "Attribute"
           && (match f.getObjValAs? String "attr" with
               | .ok a => #["pop", "popleft"].contains a
               | _ => false)
           && (match (f.getObjVal? "value").toOption with
               | some r => jsonNodeType? r == some "Name"
               | none => false))
         -- LIBRARY form: `heapq.heappop(h)` etc, read from the `Libraries` mutator spec so the set
         -- stays in one place — anything declaring `valueRest?` both yields a value and mutates.
         || (match f.getObjValAs? String "library_module", f.getObjValAs? String "library_member" with
             | .ok m, .ok mem => (Libraries.libraryMutator? m mem).any (·.valueRest?.isSome)
             | _, _ => false)
     | none => false)

/-! `setdefault` is deliberately NOT hoisted. It yields a *reference* the caller then mutates
(`d.setdefault(k, []).append(v)`); binding it to a temporary would append to the temporary and
silently lose the write, which is worse than the current clear error. -/

/-- Replace each value-and-mutate call in `expr` with a fresh name, returning the assignments that
must run first. `x = xs.pop()` is already lowered directly, so only NESTED occurrences are hoisted. -/
private partial def hoistMutatingExpr (expr : Json) : DesugarM (Json × Array Json) := do
  match expr with
  | .arr elems =>
      let mut out := #[]; let mut prelude := #[]
      for elem in elems do
        let (elem, pre) ← hoistMutatingExpr elem
        out := out.push elem; prelude := prelude ++ pre
      return (Json.arr out, prelude)
  | .obj fields =>
      if isValueMutateCall expr then
        let tmp ← freshVar "__popv_"
        return (nameLoad tmp, #[assignStmt (nameLoad tmp) expr])
      let mut rewritten := []; let mut prelude := #[]
      for (key, value) in fields.toList do
        let (value, pre) ← hoistMutatingExpr value
        prelude := prelude ++ pre
        rewritten := rewritten ++ [(key, value)]
      return (Json.mkObj rewritten, prelude)
  | _ => return (expr, #[])

/-- Hoist value-and-mutate calls out of the sub-expressions of a statement list. A call that IS the
whole hoistable expression is left alone — that form already lowers directly. Conditional contexts
are skipped: hoisting out of one would run the mutation unconditionally. -/
def hoistMutatingCalls (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    let mut stmt := stmt
    if let some field := hoistableField stmt then
      if let .ok expr := stmt.getObjVal? field then
        let nestedOnly := !isValueMutateCall expr
        let guarded := conditionalContexts.any (fun c =>
          jsonNodeType? expr == some c
          || (match expr with
              | .obj fs => fs.toList.any (fun (_, v) => jsonNodeType? v == some c)
              | _ => false))
        if nestedOnly && !guarded then
          let (expr', prelude) ← hoistMutatingExpr expr
          if !prelude.isEmpty then
            out := out ++ prelude
            stmt := stmt.setObjVal! field expr'
    out := out.push stmt
  return out

/-! ### Unbounded iterators -/

private def intConst (n : Int) : Json :=
  Json.mkObj [("node_type", Json.str "Constant"), ("value", Json.num n)]

private def binOp (op : String) (left right : Json) : Json :=
  Json.mkObj [("node_type", Json.str "BinOp"), ("op", Json.str op), ("left", left), ("right", right)]

private def callOf (fn : String) (args : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "Call"), ("func", nameLoad fn), ("args", Json.arr args),
    ("keywords", Json.mkObj [])]

private def whileTrue (body : Array Json) : Json :=
  Json.mkObj
    [("node_type", Json.str "While"),
     ("test", Json.mkObj [("node_type", Json.str "Constant"), ("value", Json.bool true)]),
     ("body", Json.arr body), ("orelse", Json.arr #[])]

/-- The `InfiniteIter` a `for` header iterates over, if any, with the call's arguments. -/
private def infiniteIter? (iter : Json) : Option (Libraries.InfiniteIter × Array Json) := do
  guard (jsonNodeType? iter == some "Call")
  let f ← (iter.getObjVal? "func").toOption
  let m ← (f.getObjValAs? String "library_module").toOption
  let mem ← (f.getObjValAs? String "library_member").toOption
  let spec ← Libraries.libraryInfiniteIter? m mem
  let args := (iter.getObjValAs? (Array Json) "args").toOption.getD #[]
  -- `repeat(x, n)` is finite; only the 1-argument form is unbounded.
  guard (spec != .constant || args.size == 1)
  pure (spec, args)

/-- Statements seeding the loop, and the prologue that advances `target` on each iteration. -/
private def unrollShape (spec : Libraries.InfiniteIter) (target : Json) (args : Array Json) :
    DesugarM (Array Json × Array Json) := do
  match spec with
  | .counter =>
      -- Seed one step BELOW `start`, so the shared prologue can do the first advance too.
      let start := args[0]?.getD (intConst 0)
      let step := args[1]?.getD (intConst 1)
      return (#[assignStmt target (binOp "sub" start step)],
        #[Json.mkObj [("node_type", Json.str "AugAssign"), ("target", target),
            ("op", Json.str "add"), ("value", step)]])
  | .cyclic =>
      let xs := args[0]?.getD (Json.arr #[])
      let src ← freshVar "__cycle_"
      let idx ← freshVar "__cycle_i_"
      let wrapped := binOp "mod" (binOp "add" (nameLoad idx) (intConst 1))
        (callOf "len" #[nameLoad src])
      return (#[assignStmt (nameLoad src) xs, assignStmt (nameLoad idx) (intConst (-1))],
        #[assignStmt (nameLoad idx) wrapped,
          assignStmt target (Json.mkObj [("node_type", Json.str "Subscript"),
            ("value", nameLoad src), ("slice", nameLoad idx)])])
  | .constant =>
      let v ← freshVar "__repeat_"
      return (#[assignStmt (nameLoad v) (args[0]?.getD (intConst 0))],
        #[assignStmt target (nameLoad v)])

/-- `for x in <unbounded iterator>:` → `while True:` with `x` advanced by a prologue at the TOP of
the body. Advancing at the top rather than the bottom is what keeps `continue` correct: Python's
`for` always advances, but a `continue` would jump over a trailing bump.

A `for … else` is left alone rather than rewritten — the `else` can only run on exhaustion, which
never happens here, so silently dropping it would hide a genuinely dead branch. -/
def unrollInfiniteIter (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    match (do
      guard (jsonNodeType? stmt == some "For")
      let target ← (stmt.getObjVal? "target").toOption
      guard (jsonNodeType? target == some "Name")
      guard (((stmt.getObjValAs? (Array Json) "orelse").toOption.getD #[]).isEmpty)
      let (spec, args) ← infiniteIter? (← (stmt.getObjVal? "iter").toOption)
      pure (target, spec, args)) with
    | some (target, spec, args) =>
        let (seed, prologue) ← unrollShape spec target args
        let body := (stmt.getObjValAs? (Array Json) "body").toOption.getD #[]
        out := out ++ seed
        out := out.push (whileTrue (prologue ++ body))
    | none => out := out.push stmt
  return out

/-- Run every desugaring over one translation request's AST. -/
def desugarAst (json : Json) : Except String Json := do
  let pass : DesugarM Json := do
    let json ← rewriteStatementLists splitChainedAssign json
    let json ← rewriteStatementLists flattenForTargets json
    let json ← rewriteStatementLists unrollInfiniteIter json
    let json ← rewriteStatementLists hoistWalrus json
    rewriteStatementLists hoistMutatingCalls json
  return (← pass.run 0).1

end PastaLean
