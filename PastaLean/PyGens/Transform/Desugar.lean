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
  -- Normalise the generated stem to a Python-invalid form (`__foo` → `p'_foo`) so it can never
  -- shadow a user variable (Python identifiers cannot contain `'`).
  let stem := if stem.startsWith "__" then
      let c := stem.drop 2
      "p'_" ++ (if c.startsWith "py_" then c.drop 3 else c)
    else stem
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

/-- Does `json` reference (as a `Name`) any id in `names`? -/
partial def jsonMentionsAnyName (names : Array String) (json : Json) : Bool :=
  if jsonNodeType? json == some "Name" then
    match json.getObjValAs? String "id" with
    | .ok id => names.contains id
    | _ => false
  else match json with
    | .arr a => a.any (jsonMentionsAnyName names)
    | .obj kvs => kvs.toList.any (fun (_, v) => jsonMentionsAnyName names v)
    | _ => false

/-- Emit `target = value` as assignments whose tuple targets contain no further tuples. The tuple
targets are stamped `_tuple_unpack` — a nested for-target (`for i, (a, b) in enumerate(zip(…))`)
unpacks a `Prod`, so codegen must use `Prod.fst`/`Prod.snd`, not list indexing. -/
partial def flattenAssign (target value : Json) : DesugarM (Array Json) := do
  unless isTupleTarget target do return #[assignStmt target value]
  -- Default a flattened nested target to `Prod` access, but NOT when TypeInfer already marked it
  -- `_list_unpack` (`for k, (l, r) in enumerate(rows)` — the inner `(l, r)` unpacks a list row).
  let tupleUnpack (t : Json) : Json :=
    if t.getObjValAs? Bool "_list_unpack" == .ok true then t
    else t.setObjVal! "_tuple_unpack" (Json.bool true)
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

/-- `for i, (a, b) in xs:` → `for i, t in xs:` with `a, b = t` prepended to the body. A nested tuple
may itself hold a `*rest` (`for i, (_, *xs) in …`) — the prepended `_, *xs = t` is a starred
assignment, which the assign lowering handles. A TOP-LEVEL starred element (`for a, *b in xs`) is left
to the `for` lowering (line below), since it would need the `for` header itself to unpack a star. -/
def flattenForTargets (stmts : Array Json) : DesugarM (Array Json) := do
  stmts.mapM fun stmt => do
    unless jsonNodeType? stmt == some "For" do return stmt
    let .ok target := stmt.getObjVal? "target" | return stmt
    unless isTupleTarget target do return stmt
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

/-- Is there a `NamedExpr` beneath a node of type `context` anywhere in `json`? A `BoolOp`'s FIRST
operand is always evaluated (`a and b` / `a or b` runs `a`), so a walrus there is safe to hoist —
only the short-circuited later operands are conditional. (`if (n := len(a)) > 0 and n < 10:`.) -/
private partial def hasWalrusUnder (context : String) (json : Json) : Bool :=
  if context == "BoolOp" && jsonNodeType? json == some "BoolOp" then
    match ((json.getObjValAs? (Array Json) "values").toOption.getD #[]).toList with
    | [] => false
    | v0 :: rest => hasWalrusUnder context v0 || rest.any (fun v => jsonContainsNodeType v ["NamedExpr"])
  else if jsonNodeType? json == some context && jsonContainsNodeType json ["NamedExpr"] then true
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

/-! ### Full-slice assignment on a non-name container -/

/-- `c[i][:] = V` (a full-slice assign whose container is not a plain `Name`) → `c[i] = V`. A full
slice replaces the whole sequence, which under our value semantics is exactly a plain
subscript/attribute assign; only the `name[:] = V` case still routes through `pySliceSet`. -/
def rewriteFullSliceAssign (stmts : Array Json) : DesugarM (Array Json) := do
  let noneField (j : Json) (k : String) : Bool :=
    match j.getObjVal? k with | .ok v => v.isNull | _ => true
  return stmts.map fun stmt =>
    if jsonNodeType? stmt != some "Assign" then stmt else
    match stmt.getObjVal? "target" with
    | .ok target =>
        if jsonNodeType? target == some "Subscript" then
          match target.getObjVal? "slice", target.getObjVal? "value" with
          | .ok sliceJ, .ok containerJ =>
              let isFullSlice := jsonNodeType? sliceJ == some "Slice"
                && noneField sliceJ "lower" && noneField sliceJ "upper" && noneField sliceJ "step"
              if isFullSlice && jsonNodeType? containerJ != some "Name" then stmt.setObjVal! "target" containerJ
              else stmt
          | _, _ => stmt
        else stmt
    | _ => stmt

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
        -- A literal RHS has no side effects, so assign it DIRECTLY to each target (no shared temp).
        -- Each target's type is then inferred on its own — `ans = pre = 0`, where `pre` later widens
        -- to ℚ (`pre = a / b`), gets `pre : ℚ` instead of being pinned to the temp's ℤ.
        if jsonNodeType? value == some "Constant" then
          for target in targets do
            out := out.push (assignStmt target value)
        else
          let tmp ← freshVar "__chain_"
          out := out.push (assignStmt (nameLoad tmp) value)
          for target in targets do
            out := out.push (assignStmt target (nameLoad tmp))
    | none => out := out.push stmt
  return out

/-- SAFE SPLIT: flat `a, b = e1, e2` with a literal-tuple RHS of matching arity referencing no
target (excludes swaps like `a, b = b, a+b`, which must stay simultaneous) → separate
`a = e1; b = e2`, so each var gets its own inferred type instead of being unpacked from a boxed
`Prod` (which boxes mixed-type elements to `PyAny`). -/
def splitIndependentTupleAssign (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    match (do
      guard (jsonNodeType? stmt == some "Assign")
      let t ← (stmt.getObjVal? "target").toOption
      let v ← (stmt.getObjVal? "value").toOption
      guard (isTupleTarget t && jsonNodeType? v == some "Tuple")
      let elts := (t.getObjValAs? (Array Json) "elts").toOption.getD #[]
      let valElts := (v.getObjValAs? (Array Json) "elts").toOption.getD #[]
      let names := elts.filterMap (fun (e : Json) => (e.getObjValAs? String "id").toOption)
      guard (valElts.size == elts.size && names.size == elts.size
        && !valElts.any (jsonMentionsAnyName names))
      pure (elts.zip valElts)) with
    | some pairs => out := out ++ pairs.map (fun (t, v) => assignStmt t v)
    | none => out := out.push stmt
  return out

/-! ### Value-and-mutate calls in sub-expression position -/

/-- `container.pop(...)` / `.popleft()`: yields a value AND mutates its receiver, so it cannot be an
ordinary sub-expression (the two effects need separate statements). -/
private def isValueMutateCall (j : Json) : Bool :=
  jsonNodeType? j == some "Call" &&
    -- A user value+mutate method (`uf.union(a,b)`) is stamped by py2lean; it returns `(value, self)`
    -- so a sub-expression occurrence must be hoisted just like `pop`.
    ((j.getObjValAs? Bool "_is_value_mutator").toOption.getD false ||
    (match (j.getObjVal? "func").toOption with
     | some f =>
         -- METHOD form on a Name or single-subscript receiver: `xs.pop(i)`, `dq.popleft()`,
         -- `g[f].pop()` — the subscript-receiver assign form lowers via `popCallSubscriptParts?`.
         (jsonNodeType? f == some "Attribute"
           && (match f.getObjValAs? String "attr" with
               | .ok a => #["pop", "popleft"].contains a
               | _ => false)
           && (match (f.getObjVal? "value").toOption with
               | some r => #["Name", "Subscript"].contains (jsonNodeType? r |>.getD "")
               | none => false))
         -- LIBRARY form: `heapq.heappop(h)` etc, read from the `Libraries` mutator spec so the set
         -- stays in one place — anything declaring `valueRest?` both yields a value and mutates.
         || (match f.getObjValAs? String "library_module", f.getObjValAs? String "library_member" with
             | .ok m, .ok mem => (Libraries.libraryMutator? m mem).any (·.valueRest?.isSome)
             | _, _ => false)
     | none => false))

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
      -- Never hoist a mutation out of a context that evaluates its operands conditionally or
      -- per-element (a comprehension pops once per item; a BoolOp/IfExp branch may not run at all).
      -- Leave the whole sub-tree intact — codegen reports it clearly rather than us mis-hoisting.
      if conditionalContexts.contains (jsonNodeType? expr |>.getD "") then
        return (expr, #[])
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
    -- Hoist from the primary field, and also from an assignment TARGET — the mutation may sit in the
    -- target's subscript index (`vis[stk.pop()] = False`), not only in the RHS.
    let isAssign := #["Assign", "AugAssign"].contains (jsonNodeType? stmt |>.getD "")
    let fields := (match hoistableField stmt with | some f => #[f] | none => #[])
      ++ (if isAssign then #["target"] else #[])
    for field in fields do
      if let .ok expr := stmt.getObjVal? field then
        -- A value+mutate call that IS the whole field expr lowers directly only in `Expr`/`Assign`/
        -- `Return` value position; elsewhere (an `If`/`Assert` test) even a whole-expr call must be
        -- hoisted, since those positions expect a plain value, not the `(value, self)` pair.
        let nodeTy := jsonNodeType? stmt |>.getD ""
        let directLowerField := field == "value" && #["Expr", "Assign", "Return"].contains nodeTy
        let leaveWholeExpr := directLowerField && isValueMutateCall expr
        let guarded := conditionalContexts.any (fun c =>
          jsonNodeType? expr == some c
          || (match expr with
              | .obj fs => fs.toList.any (fun (_, v) => jsonNodeType? v == some c)
              | _ => false))
        if !leaveWholeExpr && !guarded then
          let (expr', prelude) ← hoistMutatingExpr expr
          if !prelude.isEmpty then
            out := out ++ prelude
            stmt := stmt.setObjVal! field expr'
    out := out.push stmt
  return out

/-! ### Short-circuit value-and-mutate calls -/

/-- Does a value-and-mutate call (`uf.union(a,b)`, `xs.pop()`) appear anywhere in `j`? -/
private partial def hasValueMutate (j : Json) : Bool :=
  isValueMutateCall j ||
    (match j with
     | .obj fs => fs.toList.any (fun (_, v) => hasValueMutate v)
     | .arr xs => xs.any hasValueMutate
     | _ => false)

private def constBool (b : Bool) : Json :=
  Json.mkObj [("node_type", Json.str "Constant"), ("value", Json.bool b)]

private def notExpr (j : Json) : Json :=
  Json.mkObj [("node_type", Json.str "UnaryOp"), ("op", Json.str "not"), ("operand", j)]

private def ifStmt (test : Json) (body : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "If"), ("test", test),
    ("body", Json.arr body), ("orelse", Json.arr #[])]

private def boolOpJoin (op : String) (values : Array Json) : Json :=
  if values.size == 1 then values[0]!
  else Json.mkObj [("node_type", Json.str "BoolOp"), ("op", Json.str op), ("values", Json.arr values)]

/-- `if A and M:` / `if A or M:` where `M` (the LAST operand) is a value+mutate call and every earlier
operand is pure: rewrite into an explicit short-circuit so the mutation runs (and its receiver is
threaded) ONLY on the branch Python would evaluate it. `A and M` → `sc = False; if A: sc = M; if sc:`;
`A or M` → `sc = True; if not A: sc = M; if sc:`. A value+mutate call inside a `BoolOp` is otherwise a
conditional context the plain hoist skips, leaving the `(value, self)` tuple stuck in a truthy position.
Only the last-operand case is handled; a mutator earlier in the chain is left untouched. -/
def hoistShortCircuitMutator (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    let field? := match jsonNodeType? stmt with
      | some "If" | some "Assert" => some "test"
      | _ => none
    match field? with
    | none => out := out.push stmt
    | some field =>
      match (do
        let test ← (stmt.getObjVal? field).toOption
        guard (jsonNodeType? test == some "BoolOp")
        let op ← (test.getObjValAs? String "op").toOption
        let values ← (test.getObjValAs? (Array Json) "values").toOption
        guard (values.size ≥ 2)
        guard (hasValueMutate values.back!)
        guard (values.pop.all (fun v => !hasValueMutate v))
        pure (field, op, values)) with
      | none => out := out.push stmt
      | some (field, op, values) =>
          let scName ← freshVar "__sc'"
          let guardExpr := boolOpJoin op values.pop
          let (seed, guardTest) := if op == "and" then (constBool false, guardExpr)
                                   else (constBool true, notExpr guardExpr)
          out := out.push (assignStmt (nameLoad scName) seed)
          out := out.push (ifStmt guardTest #[assignStmt (nameLoad scName) values.back!])
          out := out.push (stmt.setObjVal! field (nameLoad scName))
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

/-! ### Unfolding a conditionally-evaluated walrus in an `and`-test

`if A and (x := E) < c: BODY` cannot hoist `x = E` (E must not run when A is false — it could raise or
recurse). Instead unfold the short-circuit into nested `if`s so `x` is assigned at its real position
and still reaches BODY: `if A: x = E; if x < c: BODY`. The `while` analogue uses `break` guards. -/

private def ifNoElse (test : Json) (body : Array Json) : Json :=
  Json.mkObj [("node_type", .str "If"), ("test", test), ("body", Json.arr body), ("orelse", Json.arr #[])]

private def andOf : List Json → Json
  | [x] => x
  | xs  => Json.mkObj [("node_type", .str "BoolOp"), ("op", .str "and"), ("values", Json.arr xs.toArray)]

/-- The walrus in `op` is evaluated unconditionally within `op` (not under a nested `and`/`or`/`IfExp`/
comprehension) — the only shape this linear unfold is sound for. -/
private def walrusUnconditional (op : Json) : Bool :=
  !(conditionalContexts.any (fun ctx => hasWalrusUnder ctx op))

/-- `if <and of `values`>: body`, with each conditionally-evaluated walrus turned into an assignment
at its short-circuit position. `none` if a walrus sits under a further conditional inside an operand. -/
partial def buildAndChainIf (values : List Json) (body : Array Json) : DesugarM (Option (Array Json)) := do
  let hasW (j : Json) : Bool := jsonContainsNodeType j ["NamedExpr"]
  let «prefix» := values.takeWhile (fun v => !hasW v)
  match values.drop «prefix».length with
  | [] => return some (if «prefix».isEmpty then body else #[ifNoElse (andOf «prefix») body])
  | w :: tl =>
      unless walrusUnconditional w do return none
      let (w', stmts) ← hoistWalrusExpr w
      let some inner ← buildAndChainIf (w' :: tl) body | return none
      let guarded := stmts ++ inner
      return some (if «prefix».isEmpty then guarded else #[ifNoElse (andOf «prefix») guarded])

/-- `while <and of `values`>: body` → `while True:` with an `if not <op>: break` guard per operand
(walrus operands assign first), so a walrus re-evaluated each iteration runs at its real position. -/
partial def buildAndChainWhile (values : List Json) (body : Array Json) : DesugarM (Option (Array Json)) := do
  let notOf (c : Json) : Json := Json.mkObj [("node_type", .str "UnaryOp"), ("op", .str "not"), ("operand", c)]
  let breakIf (c : Json) : Json := ifNoElse (notOf c) #[Json.mkObj [("node_type", .str "Break")]]
  let mut pre : Array Json := #[]
  for op in values do
    if jsonContainsNodeType op ["NamedExpr"] then
      unless walrusUnconditional op do return none
      let (op', stmts) ← hoistWalrusExpr op
      pre := (pre ++ stmts).push (breakIf op')
    else
      pre := pre.push (breakIf op)
  return some #[whileTrue (pre ++ body)]

/-- Unfold `if`/`while` whose test is an `and` containing a conditionally-evaluated walrus. Runs
before `hoistWalrus`, which would otherwise (correctly) refuse to hoist it. -/
def unfoldWalrusAnd (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out : Array Json := #[]
  for stmt in stmts do
    let isAndWalrusTest : Option (Array Json) := do
      let test ← (stmt.getObjVal? "test").toOption
      guard (jsonNodeType? test == some "BoolOp"
             && (test.getObjValAs? String "op").toOption == some "and"
             && jsonContainsNodeType test ["NamedExpr"])
      (test.getObjValAs? (Array Json) "values").toOption
    match jsonNodeType? stmt, isAndWalrusTest with
    | some "If", some values =>
        let orelse := (stmt.getObjValAs? (Array Json) "orelse").toOption.getD #[]
        let body := (stmt.getObjValAs? (Array Json) "body").toOption.getD #[]
        match ← (if orelse.isEmpty then buildAndChainIf values.toList body else pure none) with
        | some newStmts => out := out ++ newStmts
        | none => out := out.push stmt
    | some "While", some values =>
        let body := (stmt.getObjValAs? (Array Json) "body").toOption.getD #[]
        match ← buildAndChainWhile values.toList body with
        | some newStmts => out := out ++ newStmts
        | none => out := out.push stmt
    | _, _ => out := out.push stmt
  return out

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

/-! ### Unfolding a comprehension whose element MUTATES (`[x.pop() for x in xs]`) into a loop

A value-and-mutate call (`pop`) cannot be a comprehension element — it is per-iteration, so it can't be
hoisted out (`hoistMutatingCalls` rightly skips comprehensions). Instead unfold the comprehension to an
explicit `acc = []; for … : acc.append(elt)` loop (each generator's `ifs` becomes an `if` guard);
`hoistMutatingCalls` then splits the `pop` inside the loop body. Sound only where the comprehension is
evaluated once, unconditionally (same as walrus). This is the pre-pass half of the fallback whose
contract is documented in `PyGens/UseCases/ListComp.lean` (`imperativeComprehensionElement`); a mutating
comprehension in a position this can't reach is rejected there with a clear message. -/

private partial def anyValueMutate (j : Json) : Bool :=
  isValueMutateCall j ||
    (match j with
     | .arr xs => xs.any anyValueMutate
     | .obj fs => fs.toList.any (fun (_, v) => anyValueMutate v)
     | _ => false)

private def compAppendStmt (acc elt : Json) : Json :=
  Json.mkObj [("node_type", .str "Expr"), ("value", Json.mkObj
    [("node_type", .str "Call"),
     ("func", Json.mkObj [("node_type", .str "Attribute"), ("value", acc), ("attr", .str "append")]),
     ("args", Json.arr #[elt]), ("keywords", Json.mkObj [])])]

/-- `[elt for g0 for g1 …]` → nested `for` loops appending `elt` to `acc`; each generator's `ifs` guard
its inner body. -/
private def buildCompLoops (gens : Array Json) (acc elt : Json) : Array Json := Id.run do
  let mut body : Array Json := #[compAppendStmt acc elt]
  for gen in gens.reverse do
    let target := (gen.getObjVal? "target").toOption.getD Json.null
    let iter := (gen.getObjVal? "iter").toOption.getD Json.null
    let ifs := (gen.getObjValAs? (Array Json) "ifs").toOption.getD #[]
    let guarded := if ifs.isEmpty then body else #[ifNoElse (andOf ifs.toList) body]
    body := #[Json.mkObj [("node_type", .str "For"), ("target", target), ("iter", iter),
                          ("body", Json.arr guarded), ("orelse", Json.arr #[])]]
  return body

/-- Replace each `ListComp`/`GeneratorExp` whose element mutates with a fresh accumulator name,
returning the `acc = []; for …` statements. Does not descend into a conditional context (a comp there
is per-branch, so its own error is clearer). -/
private partial def unfoldMutatingCompExpr (expr : Json) : DesugarM (Json × Array Json) := do
  if #["ListComp", "GeneratorExp"].contains (jsonNodeType? expr |>.getD "")
     && ((expr.getObjVal? "elt").toOption.map anyValueMutate |>.getD false) then
    let elt := (expr.getObjVal? "elt").toOption.getD Json.null
    let gens := (expr.getObjValAs? (Array Json) "generators").toOption.getD #[]
    let name ← freshVar "__comp_"
    let acc := nameLoad name
    return (acc, #[assignStmt acc (Json.mkObj [("node_type", .str "List"), ("elts", Json.arr #[])])]
                  ++ buildCompLoops gens acc elt)
  if conditionalContexts.contains (jsonNodeType? expr |>.getD "") then return (expr, #[])
  match expr with
  | .arr elems =>
      let mut out := #[]; let mut pre := #[]
      for e in elems do let (e', p) ← unfoldMutatingCompExpr e; out := out.push e'; pre := pre ++ p
      return (Json.arr out, pre)
  | .obj fields =>
      let mut rw := []; let mut pre := #[]
      for (k, v) in fields.toList do
        let (v', p) ← unfoldMutatingCompExpr v; pre := pre ++ p; rw := rw ++ [(k, v')]
      return (Json.mkObj rw, pre)
  | _ => return (expr, #[])

/-- Unfold a mutating comprehension in a statement's once-evaluated field into a preceding loop. -/
def unfoldMutatingComprehension (stmts : Array Json) : DesugarM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    let mut stmt := stmt
    if let some field := hoistableField stmt then
      if let .ok expr := stmt.getObjVal? field then
        if anyValueMutate expr then
          let (expr', prelude) ← unfoldMutatingCompExpr expr
          unless prelude.isEmpty do
            out := out ++ prelude
            stmt := stmt.setObjVal! field expr'
    out := out.push stmt
  return out

/-! ### `count()` bounded by a finite companion: any parallel-iteration builtin (`zip`, `map`) stops
at its shortest argument, so an infinite `count(s)` there is bounded — `count(s)` = `range(s, s+len(c))`
for a finite companion `c`, which lowers through the ordinary finite path. -/

private def isCountCall (j : Json) : Bool :=
  jsonNodeType? j == some "Call" &&
    (match (j.getObjVal? "func").toOption with
     | some f => (f.getObjValAs? String "library_module").toOption == some "itertools"
                 && (f.getObjValAs? String "library_member").toOption == some "count"
     | none => false)

private def zipCountToRange (countCall other : Json) : Json :=
  let lenOf (a : Json) : Json := Json.mkObj
    [("node_type", .str "Call"), ("func", Json.mkObj [("node_type", .str "Name"), ("id", .str "len")]),
     ("args", Json.arr #[a]), ("keywords", Json.mkObj [])]
  let mkRange (rargs : Array Json) : Json := Json.mkObj
    [("node_type", .str "Range"), ("func", Json.mkObj [("node_type", .str "Name"), ("id", .str "range")]),
     ("args", Json.arr rargs), ("keywords", Json.mkObj [])]
  match ((countCall.getObjValAs? (Array Json) "args").toOption.getD #[])[0]? with
  | none => mkRange #[lenOf other]
  | some start => mkRange #[start, Json.mkObj
      [("node_type", .str "BinOp"), ("op", .str "add"), ("left", start), ("right", lenOf other)]]

/-- Rewrite `count()` args of a parallel-iteration builtin (`zip(a, count())`, `map(f, a, count())`)
anywhere in the tree, children first. `map`'s first arg is the function, so iterables start at 1. -/
partial def rewriteZipCount (json : Json) : Json :=
  let json := match json with
    | .arr xs => Json.arr (xs.map rewriteZipCount)
    | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, rewriteZipCount v)))
    | _ => json
  let fnId := (json.getObjVal? "func").toOption.bind (·.getObjValAs? String "id" |>.toOption)
  if jsonNodeType? json == some "Call" && (fnId == some "zip" || fnId == some "map") then
    let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
    let iterStart := if fnId == some "map" then 1 else 0
    let iters := args.extract iterStart args.size
    -- Need a finite companion to bound the counter; if every iterable is a counter, leave it.
    match iters.find? (fun a => !isCountCall a) with
    | some companion =>
        if iters.any isCountCall then
          let newArgs := (Array.range args.size).map fun i =>
            let a := args[i]!
            if i ≥ iterStart && isCountCall a then zipCountToRange a companion else a
          json.setObjVal! "args" (Json.arr newArgs)
        else json
    | none => json
  else json

/-- Run every desugaring over one translation request's AST. -/
def desugarAst (json : Json) : Except String Json := do
  let json := rewriteZipCount json
  let pass : DesugarM Json := do
    let json ← rewriteStatementLists rewriteFullSliceAssign json
    let json ← rewriteStatementLists splitChainedAssign json
    let json ← rewriteStatementLists splitIndependentTupleAssign json
    let json ← rewriteStatementLists flattenForTargets json
    let json ← rewriteStatementLists unrollInfiniteIter json
    let json ← rewriteStatementLists unfoldWalrusAnd json
    let json ← rewriteStatementLists hoistWalrus json
    let json ← rewriteStatementLists unfoldMutatingComprehension json
    let json ← rewriteStatementLists hoistShortCircuitMutator json
    rewriteStatementLists hoistMutatingCalls json
  return (← pass.run 0).1

end PastaLean
