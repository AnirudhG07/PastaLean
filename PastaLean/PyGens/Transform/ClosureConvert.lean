import PastaLean.PyGens.Core.Utils
import TypeInfer

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-!
## Closure conversion

A nested Python `def` lowers to `let f := fun …`, which is **not** recursive, so `dfs(i+1, j)`
inside `dfs` is an unknown identifier. Lean offers no local fix: `let rec` cannot be `partial` (so a
non-structural recursion fails termination checking), and a `where` clause forces `partial` onto the
*enclosing* def, which would cost it its unfolding and its `[simp, taste_ingr]` tag.

So each nested `def` becomes a sibling top-level `partial def` whose captured variables are extra
parameters. The enclosing function stays an ordinary, provable `def`.

`closureConvertFunction` lifts outermost-first: a nested def's captures become its parameters, so a
def one level deeper can capture them in turn. `def a: def b: def c` needs no special case.

Captured names the helper *mutates* (rebind, `x[i] = v`, `x.append(…)`) cannot be threaded yet, so
those are rejected with a clear error rather than silently dropped.
-/

/-- Append `x` unless it is already present, preserving first-seen order. -/
private def pushUnique (xs : Array String) (x : String) : Array String :=
  if xs.contains x then xs else xs.push x

private def appendUnique (xs ys : Array String) : Array String :=
  ys.foldl pushUnique xs

/-- The statement blocks nested directly inside `stmt` (`if`/`for`/`while`/`try` bodies). -/
private def nestedBlocks (stmt : Json) : Array (Array Json) := Id.run do
  let mut blocks := #[]
  for field in #["body", "orelse", "finalbody"] do
    if let .ok elems := stmt.getObjValAs? (Array Json) field then
      blocks := blocks.push elems
  if let .ok handlers := stmt.getObjValAs? (Array Json) "handlers" then
    for handler in handlers do
      if let .ok elems := handler.getObjValAs? (Array Json) "body" then
        blocks := blocks.push elems
  return blocks

/-- Every `Name` id appearing anywhere in `json`. -/
partial def jsonNameIds (json : Json) : Array String :=
  let here :=
    match jsonNodeType? json, json.getObjValAs? String "id" with
    | some "Name", .ok id => #[id]
    | _, _ => #[]
  match json with
  | .arr elems => elems.foldl (fun acc e => appendUnique acc (jsonNameIds e)) here
  | .obj fields => fields.toList.foldl (fun acc (_, v) => appendUnique acc (jsonNameIds v)) here
  | _ => here

/-- The names an assignment/loop target binds (a bare name, or the elements of a tuple unpack).
A `Subscript`/`Attribute` target mutates but does not bind. -/
partial def targetBoundNames (target : Json) : Array String :=
  match jsonNodeType? target with
  | some "Name" =>
      match target.getObjValAs? String "id" with
      | .ok id => #[id]
      | _ => #[]
  | some "Tuple" | some "List" =>
      match target.getObjValAs? (Array Json) "elts" with
      | .ok elts => elts.foldl (fun acc e => appendUnique acc (targetBoundNames e)) #[]
      | _ => #[]
  | _ => #[]

/-- The names `stmt` binds in the scope that contains it. -/
private def stmtBoundNames (stmt : Json) : Array String :=
  match jsonNodeType? stmt with
  | some "Assign" | some "AugAssign" | some "AnnAssign" | some "For" =>
      match stmt.getObjVal? "target" with
      | .ok target => targetBoundNames target
      | _ => #[]
  | some "FunctionDef" | some "ClassDef" =>
      match stmt.getObjValAs? String "name" with
      | .ok name => #[name]
      | _ => #[]
  | _ => #[]

/-- Names bound anywhere in a function body, not descending into a nested function's own scope. -/
partial def bodyBoundNames (stmts : Array Json) : Array String :=
  stmts.foldl (fun acc stmt =>
    let acc := appendUnique acc (stmtBoundNames stmt)
    if jsonNodeType? stmt == some "FunctionDef" then acc
    else (nestedBlocks stmt).foldl (fun a block => appendUnique a (bodyBoundNames block)) acc) #[]

/-- Every comprehension / generator / lambda target-name anywhere in `json` (`[v for v in xs]` binds
`v`; `lambda a: …` binds `a`). These are LOCAL to the comprehension/lambda, so a nested def that uses
one (`sum(v for v in arr)` in its body) must NOT capture it as a free variable — otherwise it is lifted
as a spurious untyped parameter. -/
partial def comprehensionBoundNames (json : Json) : Array String :=
  let here : Array String :=
    match jsonNodeType? json with
    | some "ListComp" | some "SetComp" | some "DictComp" | some "GeneratorExp" =>
        ((json.getObjValAs? (Array Json) "generators").toOption.getD #[]).foldl (fun acc g =>
          appendUnique acc ((g.getObjVal? "target").toOption.elim #[] targetBoundNames)) #[]
    | some "Lambda" =>
        (((json.getObjVal? "args").toOption.bind fun a => (a.getObjValAs? (Array Json) "args").toOption).getD #[]).foldl
          (fun acc p => match p.getObjValAs? String "arg" with | .ok n => appendUnique acc #[n] | _ => acc) #[]
    | _ => #[]
  match json with
  | .arr xs => xs.foldl (fun acc e => appendUnique acc (comprehensionBoundNames e)) here
  | .obj fs => fs.toList.foldl (fun acc (_, v) => appendUnique acc (comprehensionBoundNames v)) here
  | _ => here

/-- The declared parameter names of a `FunctionDef`, in Python declaration order. Covers EVERY binding
form — positional-only, positional, `*args`, keyword-only and `**kwargs` — since each binds a name the
body may shadow. Missing any of them (e.g. a `*args`/`**kwargs`/keyword-only name the enclosing function
also binds) would leave that name out of `innerBound`, so `free = names(inner) \ innerBound` would
misclassify it as free and spuriously capture it as an extra parameter shadowing the real one. -/
def functionParamNames (fnJson : Json) : Array String := Id.run do
  let .ok args := fnJson.getObjVal? "args" | return #[]
  let name? (arg : Json) : Option String := (arg.getObjValAs? String "arg").toOption
  let list (field : String) : Array String :=
    ((args.getObjValAs? (Array Json) field).toOption.getD #[]).filterMap name?
  let single (field : String) : Array String :=
    match (args.getObjVal? field).toOption.bind name? with | some n => #[n] | none => #[]
  return list "posonlyargs" ++ list "args" ++ single "vararg" ++ list "kwonlyargs" ++ single "kwarg"

/-- Each parameter of a `FunctionDef` with the type we can give it: its explicit annotation, else
the `_ty` the inference pass stamped. `none` where neither exists. -/
def functionParamTypedNames (fnJson : Json) : Array (String × Option Json) := Id.run do
  let .ok args := fnJson.getObjVal? "args" | return #[]
  let .ok argsArray := args.getObjValAs? (Array Json) "args" | return #[]
  return argsArray.foldl (fun acc arg =>
    match arg.getObjValAs? String "arg" with
    | .ok name =>
        let ann? := match (arg.getObjVal? "annotation").toOption with
          | some a => if a.isNull then jsonFieldOption arg "_ty" else some a
          | none => jsonFieldOption arg "_ty"
        acc.push (name, ann?)
    | _ => acc) #[]

/-- `param name → annotation` for a `FunctionDef`, so a lifted capture keeps its type. -/
def functionParamAnnotations (fnJson : Json) : Std.HashMap String Json := Id.run do
  let .ok args := fnJson.getObjVal? "args" | return {}
  let .ok argsArray := args.getObjValAs? (Array Json) "args" | return {}
  let mut m : Std.HashMap String Json := {}
  for arg in argsArray do
    if let .ok name := arg.getObjValAs? String "arg" then
      -- Prefer the explicit annotation; fall back to the `_ty` TypeInfer stamped (an inferred
      -- function-typed param, say), so a lifted capture keeps that type too.
      let ann? := match arg.getObjVal? "annotation" with
        | .ok a => if a.isNull then jsonFieldOption arg "_ty" else some a
        | .error _ => jsonFieldOption arg "_ty"
      if let some annotation := ann? then
        m := m.insert name annotation
  return m

/-- Annotations inferred for the enclosing function's locals, from their first assignment. Without
these a lifted capture is an untyped parameter and Lean's instance resolution gets stuck. -/
partial def localAnnotations (stmts : Array Json) : Std.HashMap String Json :=
  stmts.foldl (init := {}) fun acc stmt =>
    let acc :=
      if jsonNodeType? stmt == some "Assign" then
        match stmt.getObjVal? "target", stmt.getObjVal? "value" with
        | .ok target, .ok value =>
            -- Prefer the inference pass's `_ty` (mutation-informed); fall back to the RHS shape.
            let annotation? := (jsonFieldOption target "_ty").orElse fun _ =>
              TypeInfer.toAnnotation? (TypeInfer.ofValue value)
            match target.getObjValAs? String "id", annotation? with
            | .ok name, some annotation =>
                if acc.contains name then acc else acc.insert name annotation
            | _, _ => acc
        | _, _ => acc
      else acc
    if jsonNodeType? stmt == some "FunctionDef" then acc
    else (nestedBlocks stmt).foldl (fun a block =>
      (localAnnotations block).fold (fun m k v => if m.contains k then m else m.insert k v) a) acc

/-- Python methods that mutate their receiver, so a captured container they are called on is
mutated rather than merely read. -/
private def mutatingMethodName (attr : String) : Bool :=
  #["append", "appendleft", "extend", "insert", "pop", "popleft", "remove", "clear",
    "sort", "reverse", "add", "discard", "update", "setdefault"].contains attr

/-- Root `Name` id of `x`, `x[i]`, `x.f`, `x[i].g`. -/
private partial def targetRootName (target : Json) : Option String :=
  match jsonNodeType? target with
  | some "Name" => (target.getObjValAs? String "id").toOption
  | some "Subscript" | some "Attribute" =>
      match target.getObjVal? "value" with
      | .ok inner => targetRootName inner
      | _ => none
  | _ => none

/-- Free functions that mutate their FIRST argument in place (heapq's), so `heappush(pq, x)` mutates
`pq` even though it is not a method call. -/
private def mutatingFreeFn (name : String) : Bool :=
  #["heappush", "heappop", "heapify", "heapreplace", "heappushpop"].contains name

/-- Does `json` mutate `name`: rebind it, assign through it (`x[i] = v`), call a mutating method on it,
or pass it as the first arg of a mutating free function (`heappush(x, …)`)? -/
partial def jsonMutatesCapture (json : Json) (name : String) : Bool :=
  let here :=
    match jsonNodeType? json with
    | some "Assign" | some "AugAssign" | some "AnnAssign" | some "For" =>
        match json.getObjVal? "target" with
        | .ok target => targetRootName target == some name
        | _ => false
    | some "Call" =>
        match json.getObjVal? "func" with
        | .ok func =>
            (jsonNodeType? func == some "Attribute" &&
              (match func.getObjValAs? String "attr" with
               | .ok attr => mutatingMethodName attr
               | _ => false) &&
              (match func.getObjVal? "value" with
               | .ok recv => targetRootName recv == some name
               | _ => false))
            || (jsonNodeType? func == some "Name" &&
                (match func.getObjValAs? String "id" with | .ok id => mutatingFreeFn id | _ => false) &&
                (match json.getObjValAs? (Array Json) "args" with
                 | .ok args => (args[0]?).any (targetRootName · == some name)
                 | _ => false))
        | _ => false
    | _ => false
  if here then true
  else match json with
    | .arr elems => elems.any (jsonMutatesCapture · name)
    | .obj fields => fields.toList.any (fun (_, v) => jsonMutatesCapture v name)
    | _ => false

/-- Does the assign target `t` mutate `name` IN PLACE — `name[i] = …` / `name.f = …`, or a tuple of
those (`arr[i], arr[j] = …`)? A bare `name = …` is a local REBIND, which for a parameter never reaches
the caller, so it is excluded (unlike `jsonMutatesCapture`, where a rebound nonlocal must thread). -/
private partial def targetInPlaceMutates (target : Json) (name : String) : Bool :=
  match jsonNodeType? target with
  | some "Subscript" | some "Attribute" => targetRootName target == some name
  | some "Tuple" | some "List" =>
      ((target.getObjValAs? (Array Json) "elts").toOption.getD #[]).any (targetInPlaceMutates · name)
  | _ => false

/-- Does `json` mutate `name` IN PLACE (`name[i]=v`, `name.append(…)`, `heappush(name,…)`) — the only
mutations that a mutated PARAMETER propagates to its caller (a bare rebind does not). -/
partial def jsonMutatesInPlace (json : Json) (name : String) : Bool :=
  let here :=
    match jsonNodeType? json with
    | some "Assign" | some "AugAssign" | some "AnnAssign" =>
        (json.getObjVal? "target").toOption.any (targetInPlaceMutates · name)
    | some "Call" =>
        match json.getObjVal? "func" with
        | .ok func =>
            (jsonNodeType? func == some "Attribute" &&
              (match func.getObjValAs? String "attr" with | .ok a => mutatingMethodName a | _ => false) &&
              (match func.getObjVal? "value" with | .ok r => targetRootName r == some name | _ => false))
            || (jsonNodeType? func == some "Name" &&
                (match func.getObjValAs? String "id" with | .ok id => mutatingFreeFn id | _ => false) &&
                (match json.getObjValAs? (Array Json) "args" with
                 | .ok args => (args[0]?).any (targetRootName · == some name) | _ => false))
        | _ => false
    | _ => false
  if here then true
  else match json with
    | .arr elems => elems.any (jsonMutatesInPlace · name)
    | .obj fields => fields.toList.any (fun (_, v) => jsonMutatesInPlace v name)
    | _ => false

/-- A `Name` load node. -/
private def nameNode (id : String) : Json :=
  Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str id)]

/-- An `arg` node, carrying `annotation` when the capture's type is known. -/
private def argNode (name : String) (annotation : Option Json) : Json :=
  Json.mkObj [("node_type", Json.str "arg"), ("arg", Json.str name),
              ("annotation", annotation.getD Json.null)]

/-- A `Name` call-arg node for a capture, stamped `_heap_cell_arg` when `name` is a `--heap` cell
capture (passed by raw `Ref` into its own sibling, so codegen must NOT deref it). -/
private def capArgNode (cellSet : Array String) (name : String) : Json :=
  let n := nameNode name
  if cellSet.contains name then n.setObjVal! "_heap_cell_arg" (Json.bool true) else n

/-- The `PyAny` type annotation node — the total fallback for a param we cannot otherwise type. -/
private def pyAnyAnnotation : Json := Json.mkObj [("node_type", Json.str "Name"), ("id", Json.str "PyAny")]

/-- Stamp `_ty = PyAny` on every parameter of `fn` that has neither an annotation nor an inferred
`_ty`. Used when a read-only helper ESCAPES as a value: its wrapper `fun (p : T) ↦ new p caps` needs
each `T`, so an un-inferred one falls back to `PyAny` (total) rather than blocking the whole closure. -/
private def stampUnannotatedParamsPyAny (fn : Json) : Json :=
  match fn.getObjVal? "args" with
  | .ok argsObj =>
      match argsObj.getObjValAs? (Array Json) "args" with
      | .ok argsArr =>
          let argsArr := argsArr.map fun a =>
            let typed := (match a.getObjVal? "annotation" with | .ok x => !x.isNull | _ => false)
              || (jsonFieldOption a "_ty").isSome
            if typed then a else a.setObjVal! "_ty" pyAnyAnnotation
          fn.setObjVal! "args" (argsObj.setObjVal! "args" (Json.arr argsArr))
      | _ => fn
  | _ => fn

/-- The value form of a CAPTURING helper passed as a value (`sort(key=helper)`): a `Lambda`
`fun params ↦ new(params…, caps…)`, partially applying the captured args (which come after the
helper's own params). -/
private def captureWrapperLambda (new : String) (origParams : Array (String × Option Json))
    (captures : Array String) (cellSet : Array String) : Json :=
  -- An un-inferred wrapper param falls back to `PyAny` (the sibling is stamped `PyAny` to match).
  let paramArgs := origParams.map (fun (n, ann?) => argNode n (ann?.orElse (fun _ => some pyAnyAnnotation)))
  let callArgs := (origParams.map (·.1)).map nameNode ++ captures.map (capArgNode cellSet)
  let call := Json.mkObj [("node_type", Json.str "Call"), ("func", nameNode new),
                          ("args", Json.arr callArgs), ("keywords", Json.mkObj [])]
  Json.mkObj [("node_type", Json.str "Lambda"),
              ("args", Json.mkObj [("node_type", Json.str "arguments"), ("args", Json.arr paramArgs)]),
              ("body", call)]

/-- Rewrite every call `old(args…)` into `new(args…, captures…)`. A bare reference to `old` outside
call position (`sort(key=old)`) becomes a partial-application `fun p ↦ new p captures` when it
captures; a capture-free helper is just `new`. `origParams` are `old`'s own parameter names. -/
partial def rewriteHelperCalls (old new : String) (origParams : Array (String × Option Json))
    (captures : Array String) (cellSet : Array String) (heapCall : Bool) (json : Json) :
    PygenM Json := do
  match json with
  | .arr elems =>
      return Json.arr (← elems.mapM (rewriteHelperCalls old new origParams captures cellSet heapCall))
  | .obj fields =>
      if jsonNodeType? json == some "Call" then
        if let .ok func := json.getObjVal? "func" then
          if jsonNodeType? func == some "Name" && func.getObjValAs? String "id" == .ok old then
            let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
            let args ← args.mapM (rewriteHelperCalls old new origParams captures cellSet heapCall)
            let args := args ++ captures.map (capArgNode cellSet)
            let keywords ← match json.getObjVal? "keywords" with
              | .ok kw => rewriteHelperCalls old new origParams captures cellSet heapCall kw
              | _ => pure (Json.mkObj [])
            let call := (json.setObjVal! "func" (nameNode new)).setObjVal! "args" (Json.arr args)
              |>.setObjVal! "keywords" keywords
            -- A cell-capturing sibling is forced into `HeapM`, so its call site must await.
            return if heapCall then call.setObjVal! "_heap_call" (Json.bool true) else call
      -- `old` as a VALUE (`sort(key=old)`, `return old`): capture-free → the lifted name; a capturing
      -- one becomes `fun p ↦ new p caps` (`captureWrapperLambda`). This needs each wrapper param typed:
      -- a RETURNED closure's un-inferred params were stamped `PyAny` in `liftHelper` (so `origParams`
      -- carries them); a closure passed to a FOREIGN numeric callback (`odeint(system, …)`) was left
      -- un-stamped on purpose — `PyAny` would wreck its numeric/provable semantics — so it still errors.
      if jsonNodeType? json == some "Name" && json.getObjValAs? String "id" == .ok old then
        if captures.isEmpty then return nameNode new
        else if origParams.all (·.2.isSome) then
          return captureWrapperLambda new origParams captures cellSet
        else throwError s!"nested function '{old}' captures variables and is used as a value, and \
          its parameters have no inferred types to give the wrapper; only direct calls are supported."
      let rewritten ← fields.toList.mapM fun (k, v) => do
        return (k, ← rewriteHelperCalls old new origParams captures cellSet heapCall v)
      return Json.mkObj rewritten
  | _ => return json


/-! ### State threading

A helper cannot mutate a captured variable — Lean closures are pure. So a capture it rebinds
(`nonlocal ans`) or mutates in place (`grid[i][j] = v`, `xs.append(x)`) is **threaded**: appended to
the parameter list *and* returned, with every call site rebinding it.
-/

/-- `Tuple` of `elts`, or the single element itself (so one threaded name stays a plain name). -/
private def tupleNode (elts : Array Json) : Json :=
  if elts.size == 1 then elts[0]!
  else Json.mkObj [("node_type", Json.str "Tuple"), ("elts", Json.arr elts)]

private def assignNode (target value : Json) : Json :=
  Json.mkObj [("node_type", Json.str "Assign"), ("target", target), ("value", value)]

private def returnNode (value : Option Json) : Json :=
  Json.mkObj [("node_type", Json.str "Return"), ("value", value.getD Json.null)]


/-- The `Nonlocal` names declared anywhere in `json`. -/
partial def nonlocalNames (json : Json) : Array String :=
  let here := if jsonNodeType? json == some "Nonlocal" then
      (json.getObjValAs? (Array String) "names").toOption.getD #[]
    else #[]
  match json with
  | .arr elems => elems.foldl (fun acc e => appendUnique acc (nonlocalNames e)) here
  | .obj fields => fields.toList.foldl (fun acc (_, v) => appendUnique acc (nonlocalNames v)) here
  | _ => here

/-- The statement-list fields of a node. -/
private def blockFields : Array String := #["body", "orelse", "finalbody"]

/-- Rewrite every statement list in `json` with `f`, innermost first. -/
partial def mapStatementLists (f : Array Json → Array Json) (json : Json) : Json :=
  match json with
  | .arr elems => Json.arr (elems.map (mapStatementLists f))
  | .obj fields =>
      Json.mkObj (fields.toList.map fun (key, value) =>
        let value := mapStatementLists f value
        if blockFields.contains key then
          match value with
          | .arr stmts => (key, Json.arr (f stmts))
          | _ => (key, value)
        else (key, value))
  | _ => json

/-- Drop `nonlocal` declarations; the names they refer to become threaded parameters. -/
def stripNonlocal (json : Json) : Json :=
  mapStatementLists (fun stmts => stmts.filter (jsonNodeType? · != some "Nonlocal")) json

/-- Stamp `_heap_cell_def` on the FIRST assignment (pre-order) to each `--heap` cell name, so codegen
allocates the shared `Ref` cell there; later assignments to the same name rebind it (`writeRefM`).
Does not descend into nested `FunctionDef`s (a sibling's own `Ref` param, not a fresh cell). -/
private partial def stampCellDefsAux (cellNames : Array String) (json : Json) :
    StateM (Array String) Json := do
  match json with
  | .arr elems => return Json.arr (← elems.mapM (stampCellDefsAux cellNames))
  | .obj fields =>
      if jsonNodeType? json == some "FunctionDef" then return json
      if jsonNodeType? json == some "Assign" then
        if let some tgt := (json.getObjVal? "target").toOption then
          if jsonNodeType? tgt == some "Name" then
            if let .ok id := tgt.getObjValAs? String "id" then
              if cellNames.contains id && !(← get).contains id then
                modify (·.push id)
                return json.setObjVal! "_heap_cell_def" (Json.bool true)
      return Json.mkObj (← fields.toList.mapM fun (k, v) => do
        return (k, ← stampCellDefsAux cellNames v))
  | _ => return json

def stampCellDefs (cellNames : Array String) (json : Json) : Json :=
  if cellNames.isEmpty then json else (stampCellDefsAux cellNames json).run' #[]

/-- Is `json` a call to `name`? -/
private def isCallTo (name : String) (json : Json) : Bool :=
  jsonNodeType? json == some "Call" &&
    (match json.getObjVal? "func" with
     | .ok func => jsonNodeType? func == some "Name" && func.getObjValAs? String "id" == .ok name
     | _ => false)

/-- Does `json` contain a call to `name` anywhere? -/
partial def containsCallTo (name : String) (json : Json) : Bool :=
  if isCallTo name json then true
  else match json with
    | .arr elems => elems.any (containsCallTo name)
    | .obj fields => fields.toList.any (fun (_, v) => containsCallTo name v)
    | _ => false

/-- Is `name` called INSIDE a node whose type is one of `contexts` (a `Lambda`, `ListComp`, …)?
Distinct from "the statement merely contains such a node" — `for … in sorted(xs, key=lambda …): …
find(u) …` has a lambda AND a `find`, but the `find` is in the loop body, not the lambda, so it threads
fine and must NOT be rejected. -/
partial def callInsideContexts (name : String) (contexts : List String) (json : Json) : Bool :=
  (contexts.contains ((jsonNodeType? json).getD "") && containsCallTo name json)
  || (match json with
      | .arr elems => elems.any (callInsideContexts name contexts)
      | .obj fields => fields.toList.any (fun (_, v) => callInsideContexts name contexts v)
      | _ => false)

/-- `Return` nodes carrying a value, anywhere outside a nested definition. -/
partial def hasValuedReturn (json : Json) : Bool :=
  if jsonNodeType? json == some "FunctionDef" then false
  else if jsonNodeType? json == some "Return" then
    match json.getObjVal? "value" with
    | .ok value => !value.isNull
    | _ => false
  else match json with
    | .arr elems => elems.any hasValuedReturn
    | .obj fields => fields.toList.any (fun (_, v) => hasValuedReturn v)
    | _ => false

/-- A `Return` with no value, anywhere outside a nested definition. -/
partial def hasBareReturn (json : Json) : Bool :=
  if jsonNodeType? json == some "FunctionDef" then false
  else if jsonNodeType? json == some "Return" then
    match json.getObjVal? "value" with
    | .ok value => value.isNull
    | _ => true
  else match json with
    | .arr elems => elems.any hasBareReturn
    | .obj fields => fields.toList.any (fun (_, v) => hasBareReturn v)
    | _ => false

/-- Every `return e` also yields the threaded names, and a helper that falls off the end returns
them too. -/
partial def threadReturns (threaded : Array String) (hasValue : Bool) (json : Json) : Json :=
  if jsonNodeType? json == some "FunctionDef" then json
  else if jsonNodeType? json == some "Return" then
    let threadedNodes := threaded.map nameNode
    match json.getObjVal? "value" with
    | .ok value =>
        if hasValue && !value.isNull then returnNode (tupleNode (#[value] ++ threadedNodes))
        else returnNode (tupleNode threadedNodes)
    | _ => returnNode (tupleNode threadedNodes)
  else match json with
    | .arr elems => Json.arr (elems.map (threadReturns threaded hasValue))
    | .obj fields =>
        Json.mkObj (fields.toList.map fun (k, v) => (k, threadReturns threaded hasValue v))
    | _ => json

/-- Build `new(args…, captures…)` from a call to `old`, after rewriting its arguments. -/
private def retargetCall (new : String) (captures : Array String) (call : Json)
    (rewrittenArgs : Array Json) : Json :=
  ((call.setObjVal! "func" (nameNode new)).setObjVal!
    "args" (Json.arr (rewrittenArgs ++ captures.map nameNode)))

/-- Is `old` referenced anywhere other than as the callee of a direct call? -/
partial def usedAsValue (old : String) (json : Json) : Bool :=
  match json with
  | .arr elems => elems.any (usedAsValue old)
  | .obj fields =>
      if isCallTo old json then
        fields.toList.any (fun (key, value) => key != "func" && usedAsValue old value)
      else if jsonNodeType? json == some "Name" && json.getObjValAs? String "id" == .ok old then true
      else fields.toList.any (fun (_, value) => usedAsValue old value)
  | _ => false

/-- Is `old` RETURNED as a value (`return old`, `return (old, …)`)? Distinguished from being passed to
another call (`odeint(old, …)`): only a returned closure gets the `PyAny`-param fallback — a closure
handed to a foreign numeric callback keeps its (possibly-degrading) typed treatment. -/
partial def returnedAsValue (old : String) (json : Json) : Bool :=
  match json with
  | .arr elems => elems.any (returnedAsValue old)
  | .obj fields =>
      if jsonNodeType? json == some "Return" then
        (json.getObjVal? "value").toOption.any (usedAsValue old)
      else fields.toList.any (fun (_, value) => returnedAsValue old value)
  | _ => false

private def emptyListNode : Json := Json.mkObj [("node_type", Json.str "List"), ("elts", Json.arr #[])]
private def emptyDictNode : Json :=
  Json.mkObj [("node_type", Json.str "Dict"), ("keys", Json.arr #[]), ("values", Json.arr #[])]

private def attrNode (value : Json) (attr : String) : Json :=
  Json.mkObj [("node_type", Json.str "Attribute"), ("value", value), ("attr", Json.str attr)]

private def callNode (func : Json) (args : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "Call"), ("func", func), ("args", Json.arr args),
    ("keywords", Json.mkObj [])]

private def exprStmt (value : Json) : Json :=
  Json.mkObj [("node_type", Json.str "Expr"), ("value", value)]

private def forNode (target iter : Json) (body : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "For"), ("target", target), ("iter", iter),
    ("body", Json.arr body), ("orelse", Json.arr #[])]

private def ifNode (test : Json) (body : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "If"), ("test", test), ("body", Json.arr body),
    ("orelse", Json.arr #[])]

private def ifElseNode (test : Json) (body orelse : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "If"), ("test", test), ("body", Json.arr body),
    ("orelse", Json.arr orelse)]

private def notNode (operand : Json) : Json :=
  Json.mkObj [("node_type", Json.str "UnaryOp"), ("op", Json.str "not"), ("operand", operand)]

private def breakNode : Json := Json.mkObj [("node_type", Json.str "Break")]

private def trueNode : Json := Json.mkObj [("node_type", Json.str "Constant"), ("value", Json.bool true)]

private def whileNode (test : Json) (body : Array Json) : Json :=
  Json.mkObj [("node_type", Json.str "While"), ("test", test), ("body", Json.arr body),
    ("orelse", Json.arr #[])]

private def ifExpNode (test body orelse : Json) : Json :=
  Json.mkObj [("node_type", Json.str "IfExp"), ("test", test), ("body", body), ("orelse", orelse)]

private def boolOpNode (op : String) (values : Array Json) : Json :=
  if values.size == 1 then values[0]!
  else Json.mkObj [("node_type", Json.str "BoolOp"), ("op", Json.str op), ("values", Json.arr values)]

private def subscriptNode (value slice : Json) : Json :=
  Json.mkObj [("node_type", Json.str "Subscript"), ("value", value), ("slice", slice)]

/-- Builtins that fully consume a generator, so `f(x for …)` equals `f([x for …])` — building the
list first is semantics-preserving. -/
private def genConsumers : List String :=
  ["sum", "max", "min", "any", "all", "prod", "list", "set", "tuple", "sorted"]

/-- The comprehension a `return`/assign value is (once its consuming call, if any, is peeled): the
element expression(s) that must be evaluated per item, the generators, how to seed the accumulator,
how to append one item, and how to turn the finished accumulator into the result value. -/
private structure ComprShape where
  elts    : Array Json                 -- expressions evaluated per item (elt, or key+value)
  gens    : Array Json
  init    : Json                       -- `items = <empty collection>`
  body    : Json → Json                -- `items.append(elt)` / `items[k] = v`, given the items name
  result  : Json → Json                -- final value from the items name

/-- Recognise the comprehension a value denotes: a bare `[…]`/`{…}`/`{k:v …}`, or one wrapped in a
generator-consuming builtin (`sum`/`list`/`sorted`/…). -/
private def comprShapeOf? (value : Json) : Option ComprShape :=
  let listy (elt : Json) (gens : Array Json) (result : Json → Json) : ComprShape :=
    { elts := #[elt], gens, init := emptyListNode,
      body := fun items => exprStmt (callNode (attrNode items "append") #[elt]), result }
  match jsonNodeType? value with
  | some "ListComp" => do
      let elt ← (value.getObjVal? "elt").toOption
      some (listy elt ((value.getObjValAs? (Array Json) "generators").toOption.getD #[]) id)
  | some "SetComp" => do
      let elt ← (value.getObjVal? "elt").toOption
      some (listy elt ((value.getObjValAs? (Array Json) "generators").toOption.getD #[])
        (fun items => callNode (nameNode "set") #[items]))
  | some "DictComp" => do
      let key ← (value.getObjVal? "key").toOption
      let v ← (value.getObjVal? "value").toOption
      some { elts := #[key, v],
             gens := (value.getObjValAs? (Array Json) "generators").toOption.getD #[],
             init := emptyDictNode,
             body := fun items => assignNode (subscriptNode items key) v,
             result := id }
  | some "GeneratorExp" => do
      let elt ← (value.getObjVal? "elt").toOption
      some (listy elt ((value.getObjValAs? (Array Json) "generators").toOption.getD #[]) id)
  | some "Call" => do
      let func ← (value.getObjVal? "func").toOption
      guard (jsonNodeType? func == some "Name")
      let name ← (func.getObjValAs? String "id").toOption
      guard (genConsumers.contains name)
      let args := (value.getObjValAs? (Array Json) "args").toOption.getD #[]
      guard (args.size == 1 && jsonNodeType? args[0]! == some "GeneratorExp")
      let elt ← (args[0]!.getObjVal? "elt").toOption
      some (listy elt ((args[0]!.getObjValAs? (Array Json) "generators").toOption.getD #[])
        (fun items => callNode func #[items]))
  | _ => none

/-- The short-circuit op (`and`/`or`) of a single-element comprehension `A and dfs(…)` / `A or dfs(…)`
where the threaded call is in the SECOND, guarded operand (first `dfs`-free), else `none`. -/
private def shortCircuitOpOf? (old : String) (shape : ComprShape) : Option String :=
  if shape.elts.size != 1 || jsonNodeType? shape.elts[0]! != some "BoolOp" then none else
  match (shape.elts[0]!.getObjValAs? String "op").toOption with
  | some op =>
      let vals := (shape.elts[0]!.getObjValAs? (Array Json) "values").toOption.getD #[]
      if vals.size == 2 && !containsCallTo old vals[0]! && containsCallTo old vals[1]! then some op else none
  | none => none

/-- A conditional element `X if (A or … or dfs_expr) else Y` whose threaded call sits ONLY in the
condition — an `and`/`or`-chain with `old` in its LAST operand — lowered into per-item statements that
preserve the short-circuit: bind `cond` to the (dfs-free) prefix, run the threaded last operand only in
the guarded branch (`if not cond`/`if cond`), then append `X if cond else Y`. `none` if it isn't this
shape (e.g. `old` in a branch, or not a chain), leaving it on the rejecting path. -/
private def ifExpCondLower? (old : String) (elt items : Json) : Option (Array Json) :=
  if jsonNodeType? elt != some "IfExp" then none else
  match elt.getObjVal? "test", elt.getObjVal? "body", elt.getObjVal? "orelse" with
  | .ok cond, .ok x, .ok y =>
      if containsCallTo old x || containsCallTo old y || !containsCallTo old cond then none
      else if jsonNodeType? cond != some "BoolOp" then none
      else match (cond.getObjValAs? String "op").toOption, (cond.getObjValAs? (Array Json) "values").toOption with
        | some op, some vals =>
            if vals.size < 2 || vals.pop.any (containsCallTo old) || !containsCallTo old vals.back! then none
            else
              let condName := nameNode s!"{(items.getObjValAs? String "id").toOption.getD "p'_cc"}cond"
              let guardTest := if op == "or" then notNode condName else condName
              some #[assignNode condName (boolOpNode op vals.pop),
                     ifNode guardTest #[assignNode condName vals.back!],
                     exprStmt (callNode (attrNode items "append") #[ifExpNode condName x y])]
        | _, _ => none
  | _, _, _ => none

/-- The per-item accumulator STATEMENTS. A short-circuit element `A and dfs(…)` becomes an `if A` that
runs the threaded call only in its branch; a conditional `X if (… or dfs) else Y` is lowered by
`ifExpCondLower?`; anything else uses the shape's own append body. -/
private def comprPerItem (old : String) (shape : ComprShape) (items : Json) : Array Json :=
  match shortCircuitOpOf? old shape with
  | some op =>
      let vals := (shape.elts[0]!.getObjValAs? (Array Json) "values").toOption.getD #[]
      let a := vals[0]!; let b := vals[1]!
      let append := fun (x : Json) => exprStmt (callNode (attrNode items "append") #[x])
      -- `A and B` → B if A truthy else A; `A or B` → A if A truthy else B.
      if op == "and" then #[ifElseNode a #[append b] #[append a]]
      else #[ifElseNode a #[append a] #[append b]]
  | none =>
      match (if shape.elts.size == 1 then ifExpCondLower? old shape.elts[0]! items else none) with
      | some stmts => stmts
      | none => #[shape.body items]

/-- A comprehension whose threaded call can be lowered to an accumulator loop: the call is
UNCONDITIONAL (no `and`/`or`/`if-else`), a supported short-circuit, or a supported `IfExp`-condition;
and no generator filter calls `old` (a filter would change *when* the mutation runs). -/
private def comprThreadable (old : String) (shape : ComprShape) : Bool :=
  shape.elts.any (containsCallTo old)
    && ((shortCircuitOpOf? old shape).isSome
        || (shape.elts.size == 1 && (ifExpCondLower? old shape.elts[0]! (nameNode "__x")).isSome)
        || !shape.elts.any (jsonContainsNodeType · ["BoolOp", "IfExp"]))
    && !shape.gens.any (fun g =>
        ((g.getObjValAs? (Array Json) "ifs").toOption.getD #[]).any (containsCallTo old))

/-- Seed + per-item loop for a comprehension's accumulator (the shared spine of both the top-level
expand and the nested hoist); the caller finishes with the result/rebuild step. -/
private def comprLoopStmts (old : String) (shape : ComprShape) (items : Json) : Array Json :=
  let loop := shape.gens.foldr (fun g inner =>
    let target := (g.getObjVal? "target").toOption.getD (nameNode "_")
    let iter := (g.getObjVal? "iter").toOption.getD emptyListNode
    let ifs := (g.getObjValAs? (Array Json) "ifs").toOption.getD #[]
    let guarded := ifs.foldr (fun cond acc => #[ifNode cond acc]) inner
    #[forNode target iter guarded]) (comprPerItem old shape items)
  #[assignNode items shape.init] ++ loop

/-- `<return/assign> <comprehension>` whose per-item expression calls the threaded helper `old` →
rewrite the comprehension to its explicit accumulator loop, so the threaded call lands in statement
position where the existing hoist/thread machinery carries the mutated state across iterations. A
comprehension is exactly this loop by definition, so the rewrite is semantics-preserving. -/
private def expandThreadedComprehension? (old : String) (counter : IO.Ref Nat) (stmt : Json) :
    IO (Option (Array Json)) := do
  let rebuild? : Option ((Json → Json) × Json) :=
    match jsonNodeType? stmt with
    | some "Return" => ((stmt.getObjVal? "value").toOption).map fun v => ((returnNode ∘ some), v)
    | some "Assign" => do
        let v ← (stmt.getObjVal? "value").toOption
        let t ← (stmt.getObjVal? "target").toOption
        some ((assignNode t ·), v)
    | _ => none
  let some (rebuild, value) := rebuild? | return none
  let some shape := comprShapeOf? value | return none
  unless comprThreadable old shape do return none
  let n ← counter.modifyGet (fun n => (n, n + 1))
  let items := nameNode s!"p'_cc{n + 1}"
  return some (comprLoopStmts old shape items ++ #[rebuild (shape.result items)])

/-- Replace every comprehension sub-expression of `expr` that calls the threaded helper `old` with a
fresh temporary, returning the accumulator-loop statements that must run first — the nested version
of `expandThreadedComprehension?` (`return 1 + sum(dfs(j) for j)`, `x = a + max(dfs(…) for …)`). Does
NOT descend into `and`/`or`/`if-else`, so a short-circuited comprehension is left for the (rejecting)
path — hoisting it would run the mutation unconditionally. -/
private partial def hoistThreadedComprs (old : String) (counter : IO.Ref Nat) (expr : Json) :
    IO (Json × Array Json) := do
  if jsonNodeType? expr == some "BoolOp" || jsonNodeType? expr == some "IfExp" then
    return (expr, #[])
  if let some shape := comprShapeOf? expr then
    if comprThreadable old shape then
      let n ← counter.modifyGet (fun n => (n, n + 1))
      let items := nameNode s!"p'_cc{n + 1}"
      let tmp := nameNode s!"p'_cv{n + 1}"
      return (tmp, comprLoopStmts old shape items ++ #[assignNode tmp (shape.result items)])
  match expr with
  | .arr xs =>
      let mut out := #[]; let mut pre := #[]
      for x in xs do
        let (x', p) ← hoistThreadedComprs old counter x
        out := out.push x'; pre := pre ++ p
      return (Json.arr out, pre)
  | .obj fs =>
      let mut rewritten := []; let mut pre := #[]
      for (k, v) in fs.toList do
        let (v', p) ← hoistThreadedComprs old counter v
        pre := pre ++ p; rewritten := rewritten ++ [(k, v')]
      return (Json.mkObj rewritten, pre)
  | _ => return (expr, #[])

/-- What a lifted, state-threading helper looks like to its CALLERS: a call to `name` becomes a call
to `helperName` with `ordered` extra capture args, rebinding `threaded` (a `hasValue` helper also
yields a value). A sibling that calls it (union-find's `union` → `find`) uses this to thread it. -/
structure ThreadedSpec where
  name : String
  helperName : String
  ordered : Array String
  threaded : Array String
  /-- The helper's ORIGINAL parameter names (before capture params are appended). A threaded name that
  is one of these is a mutated *parameter* (`push(pq,x)` mutates `pq`): at a call site it rebinds the
  ARGUMENT in that position (`heap := _push heap x`), not a same-named capture. -/
  origParams : Array String
  hasValue : Bool

/-- The rebind targets for a threaded call: a threaded name that is an original parameter rebinds the
call's argument at that position (a mutated param maps to its caller's argument); any other threaded
name is a shared capture, rebound by its own name. -/
def threadedTargetsFor (threaded origParams : Array String) (callArgs : Array Json) : Array Json :=
  threaded.map fun name =>
    match origParams.findIdx? (· == name) with
    | some i =>
        match callArgs[i]? with
        -- Only an lvalue (Name / Subscript / Attribute) can be rebound. A threaded parameter passed a
        -- FRESH value (`dfs(deque(s))`, `dfs(src, tgt, set())`) discards its mutation into `_` — matches
        -- Python, where mutating a freshly-constructed argument never reaches the caller.
        | some arg =>
            if #["Name", "Subscript", "Attribute"].contains ((jsonNodeType? arg).getD "") then arg
            else nameNode "_"
        | none => nameNode name
    | none => nameNode name

mutual

/-- Replace each threaded call inside an expression with a temporary, returning the assignments
that must run first. A helper with no return value cannot appear in a value position. -/
partial def hoistThreadedCalls (old new : String) (captures threaded origParams : Array String)
    (hasValue : Bool) (counter : IO.Ref Nat) (expr : Json) : PygenM (Json × Array Json) := do
  if isCallTo old expr then
    let args := (expr.getObjValAs? (Array Json) "args").toOption.getD #[]
    let mut rewrittenArgs := #[]
    let mut prelude := #[]
    for arg in args do
      let (arg, pre) ← hoistThreadedCalls old new captures threaded origParams hasValue counter arg
      rewrittenArgs := rewrittenArgs.push arg
      prelude := prelude ++ pre
    let call := retargetCall new captures expr rewrittenArgs
    unless hasValue do
      throwError s!"nested function '{old}' returns no value but is used as one."
    let n ← counter.modifyGet (fun n => (n, n + 1))
    let temp := s!"p'_thread_t{n + 1}"
    let target := tupleNode (#[nameNode temp] ++ threadedTargetsFor threaded origParams rewrittenArgs)
    return (nameNode temp, prelude.push (assignNode target call))
  match expr with
  | .arr elems =>
      let mut out := #[]
      let mut prelude := #[]
      for elem in elems do
        let (elem, pre) ← hoistThreadedCalls old new captures threaded origParams hasValue counter elem
        out := out.push elem
        prelude := prelude ++ pre
      return (Json.arr out, prelude)
  | .obj fields =>
      let mut rewritten := []
      let mut prelude := #[]
      for (key, value) in fields.toList do
        let (value, pre) ← hoistThreadedCalls old new captures threaded origParams hasValue counter value
        prelude := prelude ++ pre
        rewritten := rewritten ++ [(key, value)]
      return (Json.mkObj rewritten, prelude)
  | _ => return (expr, #[])

/-- Rewrite the calls to `old` in a statement list, rebinding the threaded names at each one. -/
partial def rewriteThreadedStmts (old new : String) (captures threaded origParams : Array String)
    (hasValue : Bool) (counter : IO.Ref Nat) (stmts : Array Json) : PygenM (Array Json) := do
  let mut out := #[]
  for stmt in stmts do
    -- A sibling nested `def` is a separate scope: leave it verbatim (its own calls to `old` are
    -- threaded when IT is lifted, via its `ThreadedSpec`), never thread through it here.
    if jsonNodeType? stmt == some "FunctionDef" then
      out := out.push stmt
      continue
    unless containsCallTo old stmt do
      out := out.push stmt
      continue
    -- A state-threading call inside a comprehension (`return sum(dfs(…) for …)`, `xs = [f(i) for i]`,
    -- …): expand the comprehension to its accumulator loop so the call lands in statement position,
    -- then thread the expansion.
    if let some expanded ← expandThreadedComprehension? old counter stmt then
      out := out ++ (← rewriteThreadedStmts old new captures threaded origParams hasValue counter expanded)
      continue
    -- The comprehension nested inside a larger expression (`return 1 + sum(dfs(j) for j)`): hoist it
    -- to a temporary, threading the accumulator loop, then process the simplified statement.
    if ["Return", "Assign", "AugAssign", "Expr"].contains ((jsonNodeType? stmt).getD "") then
      if let .ok value := stmt.getObjVal? "value" then
        let (value', prelude) ← hoistThreadedComprs old counter value
        if !prelude.isEmpty then
          let stmt := stmt.setObjVal! "value" value'
          out := out ++ (← rewriteThreadedStmts old new captures threaded origParams hasValue counter
            (prelude ++ #[stmt]))
          continue
    -- An `if any(dfs(v) for v):` test: hoist the comprehension to a temp BEFORE the `if` (its
    -- accumulator loop threads the state once), then the simplified `if <temp>:` recurses normally.
    -- A `while` test can't (it re-evaluates each iteration) — that stays rejected below.
    if jsonNodeType? stmt == some "If" then
      if let .ok test := stmt.getObjVal? "test" then
        let (test', prelude) ← hoistThreadedComprs old counter test
        if !prelude.isEmpty then
          let stmt := stmt.setObjVal! "test" test'
          out := out ++ (← rewriteThreadedStmts old new captures threaded origParams hasValue counter
            (prelude ++ #[stmt]))
          continue
    -- `while find(a) != find(b):` — the test threads state and re-runs each iteration, so it can't be
    -- hoisted ONCE. Rewrite to `while True: <hoist test>; if not test': break; <body>`, so the threaded
    -- calls run (and rebind) at the top of every iteration.
    if jsonNodeType? stmt == some "While" then
      if let .ok test := stmt.getObjVal? "test" then
        if containsCallTo old test then
          let (test', prelude) ← hoistThreadedCalls old new captures threaded origParams hasValue counter test
          let body := (stmt.getObjValAs? (Array Json) "body").toOption.getD #[]
          let newBody := prelude ++ #[ifNode (notNode test') #[breakNode]] ++ body
          let newBody ← rewriteThreadedStmts old new captures threaded origParams hasValue counter newBody
          out := out.push (whileNode trueNode newBody)
          continue
    if callInsideContexts old ["Lambda", "ListComp", "SetComp", "DictComp", "GeneratorExp"] stmt then
      throwError s!"call to '{old}' inside a comprehension or lambda cannot rebind the threaded state."

    -- `dfs(i, j)` as a statement: keep only the rebinding.
    if jsonNodeType? stmt == some "Expr" then
      if let .ok value := stmt.getObjVal? "value" then
        if isCallTo old value then
          let args := (value.getObjValAs? (Array Json) "args").toOption.getD #[]
          let call := retargetCall new captures value args
          let threadedNodes := threadedTargetsFor threaded origParams args
          let targets ←
            if hasValue then do
              let n ← counter.modifyGet (fun n => (n, n + 1))
              pure (#[nameNode s!"p'_thread_t{n + 1}"] ++ threadedNodes)
            else pure threadedNodes
          out := out.push (assignNode (tupleNode targets) call)
          continue
    -- `x = dfs(i, j)`: bind the value and the threaded names together.
    if jsonNodeType? stmt == some "Assign" then
      if let .ok value := stmt.getObjVal? "value" then
        if isCallTo old value then
          unless hasValue do
            throwError s!"nested function '{old}' returns no value but its result is assigned."
          let .ok target := stmt.getObjVal? "target" | throwError "Assign is missing a 'target'"
          -- A subscript target may itself contain a threaded call in its index (`p[find(x)] = find(y)`);
          -- hoist those to temporaries first so the index is threaded too, not left as a bare call.
          let (target, tgtPre) ← hoistThreadedCalls old new captures threaded origParams hasValue counter target
          let args := (value.getObjValAs? (Array Json) "args").toOption.getD #[]
          let call := retargetCall new captures value args
          let threadedNodes := threadedTargetsFor threaded origParams args
          -- The threaded return is a fully-`Prod` tuple, so a nested target (`(ls, ln), ans`) unpacks
          -- with `Prod` at every level; `_thread_unpack` tells codegen to use `Prod`, not list access.
          let tgt := (tupleNode (#[target] ++ threadedNodes)).setObjVal! "_thread_unpack" (Json.bool true)
          out := out ++ tgtPre
          out := out.push (assignNode tgt call)
          continue

    -- Anywhere else the call sits inside an expression: hoist it to a temporary first.
    let mut stmt := stmt
    let mut prelude := #[]
    for (key, value) in (stmt.getObj?.toOption.getD ∅).toList do
      unless blockFields.contains key || key == "handlers" do
        if containsCallTo old value then
          let (value, pre) ← hoistThreadedCalls old new captures threaded origParams hasValue counter value
          prelude := prelude ++ pre
          stmt := stmt.setObjVal! key value
    for key in blockFields do
      if let .ok block := stmt.getObjValAs? (Array Json) key then
        let block ← rewriteThreadedStmts old new captures threaded origParams hasValue counter block
        stmt := stmt.setObjVal! key (Json.arr block)
    out := out ++ prelude
    out := out.push stmt
  return out

end

/-- Lift one nested `FunctionDef` out of `outerJson`, returning the lifted helper and the rewritten
outer function.

Captures the helper only reads become extra parameters. Captures it rebinds (`nonlocal`) or mutates
in place are **threaded**: extra parameters that the helper also returns, with each call site
rebinding them. -/
private def liftHelper (outerName : String) (outerJson innerJson : Json)
    (siblingSpecs : Array ThreadedSpec := #[]) :
    PygenM (Json × Json × Option ThreadedSpec) := do
  let .ok innerName := innerJson.getObjValAs? String "name" | throwError
    s!"nested FunctionDef is missing a 'name': {innerJson}"
  let .ok outerBody := outerJson.getObjValAs? (Array Json) "body" | throwError
    s!"FunctionDef is missing a 'body': {outerJson}"

  let declaredNonlocal := nonlocalNames innerJson
  let inner := stripNonlocal innerJson
  let innerBody := (inner.getObjValAs? (Array Json) "body").toOption.getD #[]

  -- A capture is a name the helper reads that the enclosing function binds. Intersecting with the
  -- outer scope keeps builtins (`len`, `range`) and globals out of the parameter list. A `nonlocal`
  -- name is rebound inside the helper, so it looks local — add it back explicitly.
  let outerBound := appendUnique (functionParamNames outerJson) (bodyBoundNames outerBody)
  let innerBound := appendUnique (appendUnique (functionParamNames inner) (bodyBoundNames innerBody))
    (comprehensionBoundNames (Json.arr innerBody))
  let innerUsed := jsonNameIds inner
  let directCaptures := outerBound.filter fun name =>
    name != innerName &&
      ((innerUsed.contains name && !innerBound.contains name) || declaredNonlocal.contains name)

  -- Siblings this helper CALLS (union-find's `union` calls `find`; `eval` calls `parseVar`). It must
  -- ALSO capture every capture of a called sibling, even ones it never names directly, to FORWARD them
  -- (`eval` passes `parseVar`'s `n`). Their threaded captures (`p`, `i`) are threaded through here too
  -- — a rebind from a sibling call has to land somewhere.
  let calledSiblings := siblingSpecs.filter fun s => containsCallTo s.name inner
  let siblingCaps := calledSiblings.foldl (fun acc s => appendUnique acc (s.ordered.filter outerBound.contains)) #[]
  let captures := appendUnique directCaptures siblingCaps
  let siblingThreaded := calledSiblings.foldl (fun acc s => appendUnique acc (s.threaded.filter captures.contains)) #[]
  -- Mutated CAPTURES: nonlocal / mutated-in-place captures, plus a called sibling's threaded state.
  let mutatedCaptures := (captures.filter fun c => declaredNonlocal.contains c || jsonMutatesCapture inner c)
    |> (appendUnique · siblingThreaded)
  let origParamNames := functionParamNames inner
  let readOnly := captures.filter fun c => !mutatedCaptures.contains c
  -- Under `--heap`, a mutated capture becomes a shared `Ref` CELL passed by reference into the sibling
  -- (faithful aliasing, can escape) instead of being value-threaded through a return tuple. So the
  -- value-threading machinery is bypassed (`threaded`/`threadedParams` empty) and cells ride `ordered`.
  -- In value mode: mutated captures thread through a return tuple, alongside mutated params.
  let heap ← getHeapMode
  let cellCaptures := if heap then mutatedCaptures else #[]
  -- Threaded CAPTURES (value mode only): nonlocal/mutated captures + a called sibling's threaded state.
  let threadedCaptures := if heap then #[] else mutatedCaptures
  -- Threaded PARAMETERS (value mode only): an original parameter the body mutates in place
  -- (`push(pq, x)` heappushes pq). Already a parameter, so threaded only on the RETURN.
  let threadedParams := if heap then #[] else origParamNames.filter fun p => jsonMutatesInPlace inner p
  -- Extra params appended = read-only + heap cells + threaded CAPTURES (mutated params already exist).
  let ordered := readOnly ++ cellCaptures ++ threadedCaptures
  -- Names handed back on the threaded return tuple: mutated params, then threaded captures.
  let threaded := threadedParams ++ threadedCaptures

  -- A helper used as a value (`sort(key=f)`): capture-free → a plain reference; read-only captures →
  -- a `fun p ↦ new p caps` wrapper (in `rewriteHelperCalls`). Only a THREADED (mutated) capture used
  -- as a value is genuinely unsupported — a value lambda can't rebind the threaded state.
  let escapesAsValue := usedAsValue innerName inner || usedAsValue innerName (Json.arr outerBody)
  if escapesAsValue && !threaded.isEmpty then
    throwError s!"nested function '{innerName}' mutates a captured variable and is used as a value; unsupported."
  -- A read-only closure RETURNED as a value gets a typed wrapper `fun (p : T) ↦ new p caps`; default
  -- any un-inferred param to `PyAny` on the SIBLING here so it matches the wrapper. Only for RETURNED
  -- closures — one passed to a foreign numeric callback (`odeint`) must keep concrete types or degrade.
  let inner := if returnedAsValue innerName (Json.arr outerBody) then stampUnannotatedParamsPyAny inner
               else inner

  let hasValue := hasValuedReturn (Json.arr innerBody)
  unless threaded.isEmpty do
    -- A helper that sometimes returns a value and sometimes falls through would have to return an
    -- `Option`, which its callers do not expect.
    if hasValue && hasBareReturn (Json.arr innerBody) then
      throwError s!"nested function '{innerName}' mixes `return <value>` with a bare `return`; \
        threading its state would need an `Option` result."
    if hasValue && !statementListDefinitelyReturns innerBody.toList then
      throwError s!"nested function '{innerName}' can fall off the end while threading state; \
        give it an explicit `return`."

  let helperName := s!"_{outerName}'{innerName}"
  -- References to a user function are suffixed in the `'rn` twin; the helper is a user function too.
  userNamesRef.modify (helperName :: ·)

  -- Parameter annotations win; a local's type is inferred from its first assignment.
  let annotations := (localAnnotations outerBody).fold
    (fun m k v => if m.contains k then m else m.insert k v) (functionParamAnnotations outerJson)
  let .ok innerArgs := inner.getObjVal? "args" | throwError
    s!"nested FunctionDef is missing 'args': {inner}"
  let innerArgsArray := (innerArgs.getObjValAs? (Array Json) "args").toOption.getD #[]
  -- Captures become extra params AFTER the originals; mark them `_capture` so a memoized (`@cache`)
  -- helper keys its cache on the ORIGINAL params only — a capture is constant across the recursion
  -- (the cache is seeded fresh per top-level call), and may be a non-hashable container. A `--heap`
  -- cell capture is additionally marked `_heap_cell_param` (passed by raw ref, not value).
  let extraArgs := ordered.map fun c =>
    let a := (argNode c (annotations[c]?)).setObjVal! "_capture" (Json.bool true)
    if cellCaptures.contains c then a.setObjVal! "_heap_cell_param" (Json.bool true) else a
  let innerArgs := innerArgs.setObjVal! "args" (Json.arr (innerArgsArray ++ extraArgs))

  let remaining := outerBody.filter fun stmt =>
    !(jsonNodeType? stmt == some "FunctionDef"
      && stmt.getObjValAs? String "name" == .ok innerName)

  let origParams := functionParamTypedNames inner
  let counter ← IO.mkRef 0
  -- Thread calls to already-lifted threaded siblings (`union`'s `find(a)`) into rebinding statements
  -- first; the self-threading below then flows the shared state through them. A helper that calls
  -- such a sibling always threads (its shared capture was folded into `threaded` above).
  let mut innerBody := innerBody
  for s in calledSiblings do
    innerBody ← rewriteThreadedStmts s.name s.helperName s.ordered s.threaded s.origParams s.hasValue counter innerBody
  let heapCall := heap && !cellCaptures.isEmpty
  let (helperBody, rewrittenOuter) ←
    if threaded.isEmpty then do
      let body ← rewriteHelperCalls innerName helperName origParams ordered cellCaptures heapCall (Json.arr innerBody)
      let outer ← rewriteHelperCalls innerName helperName origParams ordered cellCaptures heapCall (Json.arr remaining)
      pure (body, outer)
    else do
      let body ← rewriteThreadedStmts innerName helperName ordered threaded origParamNames hasValue counter innerBody
      let body := threadReturns threaded hasValue (Json.arr body)
      -- A helper that returns nothing still has to hand the threaded state back on every path.
      let body := match body with
        | .arr stmts =>
            if statementListDefinitelyReturns stmts.toList then Json.arr stmts
            else Json.arr (stmts.push (returnNode (tupleNode (threaded.map nameNode))))
        | other => other
      let outer ← rewriteThreadedStmts innerName helperName ordered threaded origParamNames hasValue counter remaining
      pure (body, Json.arr outer)

  let helper := ((inner.setObjVal! "name" (Json.str helperName)).setObjVal! "args" innerArgs)
    |>.setObjVal! "body" helperBody
  -- Threading changes the result into a tuple, so the declared return annotation no longer holds.
  let helper := if threaded.isEmpty then helper else helper.setObjVal! "returns" Json.null
  let spec? : Option ThreadedSpec :=
    if threaded.isEmpty then none
    else some { name := innerName, helperName, ordered, threaded, origParams := origParamNames, hasValue }
  -- Mark where each `--heap` cell is first defined in the outer scope, so codegen `allocM`s it there.
  let rewrittenOuter := stampCellDefs cellCaptures rewrittenOuter
  return (helper, outerJson.setObjVal! "body" rewrittenOuter, spec?)

/-- Group nested defs into clusters that each become one lift. A cluster is a **strongly-connected
component** of the DIRECTED sibling-*call* graph (`i → j` if def `i` references def `j`'s name) — so
only a genuine reference *cycle* (`a` calls `b` and `b` calls `a`) forms a multi-member cluster needing
a `mutual` block. A one-directional reference (union-find's `union` calls `find`, `find` never calls
`union`) is a DAG, not a cycle, so each stays its own singleton and lifts through the normal
threading-capable path. Clusters come out callee-before-caller (topological on the condensation) so a
lifted helper referencing a sibling sees it already emitted; ties break by source order. -/
def nestedRefComponents (nested : Array Json) : Array (Array Json) := Id.run do
  let names := nested.filterMap (·.getObjValAs? String "name" |>.toOption)
  let n := nested.size
  if names.size != n then return nested.map (#[·])   -- an unnamed def: no grouping, all singletons
  -- Directed reachability: `reach i j` iff def `i` can reach def `j` through the call graph.
  let used := nested.map jsonNameIds
  let mut reach : Array (Array Bool) := (Array.range n).map fun i =>
    (Array.range n).map fun j => i == j || (i != j && used[i]!.contains names[j]!)
  for k in [0:n] do
    for i in [0:n] do
      if (reach[i]!)[k]! then
        for j in [0:n] do
          if (reach[k]!)[j]! then reach := reach.modify i (·.set! j true)
  -- SCC: `i`, `j` share a cluster iff each reaches the other. Group in first-seen (source) order.
  let mut comp : Array (Option Nat) := Array.replicate n none
  let mut rawGroups : Array (Array Nat) := #[]
  for i in [0:n] do
    if comp[i]!.isNone then
      let members := (Array.range n).filter fun j => (reach[i]!)[j]! && (reach[j]!)[i]!
      for j in members do comp := comp.set! j (some rawGroups.size)
      rawGroups := rawGroups.push members
  -- Emit callee-clusters before caller-clusters: cluster A precedes B if A calls into B (A depends on
  -- B, so B must exist first). Repeatedly take a cluster none of whose UNEMITTED peers it still calls.
  let callsGroup := fun (a b : Nat) => (rawGroups[a]!).any fun i => (rawGroups[b]!).any fun j => (reach[i]!)[j]!
  let mut order : Array Nat := #[]
  let mut done : Array Bool := Array.replicate rawGroups.size false
  for _ in [0:rawGroups.size] do
    let mut pick : Option Nat := none
    for g in [0:rawGroups.size] do
      if !done[g]! && pick.isNone then
        let blocked := (Array.range rawGroups.size).any fun h => h != g && !done[h]! && callsGroup g h
        if !blocked then pick := some g
    match pick with
    | some g => order := order.push g; done := done.set! g true
    | none => for g in [0:rawGroups.size] do if !done[g]! then order := order.push g; done := done.set! g true
  return order.map fun g => rawGroups[g]!.map (nested[·]!)

/-- Lift a cluster of mutually-referencing nested defs together. Every member gets the *shared*
capture set (the union of the members' captures) as extra parameters, so a call to any sibling can
supply them; the lifted defs reference each other and are emitted in one `mutual` block. Threaded
(`nonlocal`/mutated) captures across a mutual cluster are not supported yet — rejected loudly. -/
private def liftMutualGroup (outerName : String) (outerJson : Json) (members : Array Json) :
    PygenM (Array Json × Json) := do
  let .ok outerBody := outerJson.getObjValAs? (Array Json) "body" | throwError
    s!"FunctionDef is missing a 'body': {outerJson}"
  let memberNames := members.filterMap (·.getObjValAs? String "name" |>.toOption)
  let outerBound := appendUnique (functionParamNames outerJson) (bodyBoundNames outerBody)

  -- Each member's captures = names it reads that the outer scope binds, minus the siblings (those
  -- become mutual references, not parameters). The shared set is their union.
  let mut shared : Array String := #[]
  for m in members do
    let .ok mName := m.getObjValAs? String "name" | throwError s!"member is missing a 'name': {m}"
    unless (nonlocalNames m).isEmpty do
      throwError s!"mutually-recursive nested function '{mName}' uses `nonlocal`; threading state \
        across a mutual cluster is not supported yet."
    let mBody := (m.getObjValAs? (Array Json) "body").toOption.getD #[]
    let mBound := appendUnique (functionParamNames m) (bodyBoundNames mBody)
    let mUsed := jsonNameIds m
    let caps := outerBound.filter fun name =>
      name != mName && !memberNames.contains name && mUsed.contains name && !mBound.contains name
    for c in caps do
      if jsonMutatesCapture m c then
        throwError s!"mutually-recursive nested function '{mName}' mutates captured '{c}'; not \
          supported yet."
    shared := appendUnique shared caps

  let annotations := (localAnnotations outerBody).fold
    (fun m k v => if m.contains k then m else m.insert k v) (functionParamAnnotations outerJson)
  let extraArgs := shared.map fun c => argNode c (annotations[c]?)
  let helperNameOf := fun (nm : String) => s!"_{outerName}'{nm}"
  for nm in memberNames do
    userNamesRef.modify (helperNameOf nm :: ·)

  let mut helpers := #[]
  for m in members do
    let .ok mName := m.getObjValAs? String "name" | throwError s!"member is missing a 'name': {m}"
    let .ok mArgs := m.getObjVal? "args" | throwError s!"member is missing 'args': {m}"
    let mArgsArray := (mArgs.getObjValAs? (Array Json) "args").toOption.getD #[]
    let mArgs := mArgs.setObjVal! "args" (Json.arr (mArgsArray ++ extraArgs))
    -- Rewrite every call to any sibling (self included) to the lifted name + shared captures.
    let mut body := (m.getObjVal? "body").toOption.getD (Json.arr #[])
    for sibName in memberNames do
      let sibParams := (members.find? (·.getObjValAs? String "name" == .ok sibName)).elim #[] functionParamTypedNames
      body ← rewriteHelperCalls sibName (helperNameOf sibName) sibParams shared #[] false body
    let helper := ((m.setObjVal! "name" (Json.str (helperNameOf mName))).setObjVal! "args" mArgs)
      |>.setObjVal! "body" body
    helpers := helpers.push helper

  let remaining := outerBody.filter fun stmt =>
    !(jsonNodeType? stmt == some "FunctionDef"
      && memberNames.contains ((stmt.getObjValAs? String "name").toOption.getD ""))
  let mut outerBodyJson := Json.arr remaining
  for sibName in memberNames do
    let sibParams := (members.find? (·.getObjValAs? String "name" == .ok sibName)).elim #[] functionParamTypedNames
    outerBodyJson ← rewriteHelperCalls sibName (helperNameOf sibName) sibParams shared #[] false outerBodyJson
  return (helpers, outerJson.setObjVal! "body" outerBodyJson)

/-- Lift every nested `def` out of `fnJson`, outermost-first. Returns helper **groups** (each a lone
helper, or a mutual cluster to be emitted in one `mutual` block) and the rewritten function. -/
partial def closureConvertFunction (fnJson : Json) : PygenM (Array (Array Json) × Json) := do
  let .ok _ := fnJson.getObjValAs? (Array Json) "body" | return (#[], fnJson)
  let .ok outerName := fnJson.getObjValAs? String "name" | return (#[], fnJson)
  let nested := ((fnJson.getObjValAs? (Array Json) "body").toOption.getD #[]).filter
    (jsonNodeType? · == some "FunctionDef")
  if nested.isEmpty then return (#[], fnJson)

  let mut groups : Array (Array Json) := #[]
  let mut current := fnJson
  -- Specs of already-lifted threaded siblings, so a later cluster (union-find's `union`) threads its
  -- calls to an earlier one (`find`). Clusters arrive callee-before-caller, so the spec exists in time.
  let mut threadedSpecs : Array ThreadedSpec := #[]
  for cluster in nestedRefComponents nested do
    -- Re-read each cluster member from `current`, not from the stale `nested` snapshot: an earlier
    -- cluster's lift already rewrote calls to it inside THIS cluster's still-nested body (a read-only
    -- sibling `check` became `_solve'check` in `dfs`), and that edit lives only in `current`.
    let curBody := (current.getObjValAs? (Array Json) "body").toOption.getD #[]
    let cluster := cluster.filterMap fun m =>
      (m.getObjValAs? String "name").toOption.bind fun nm =>
        curBody.find? (fun s => jsonNodeType? s == some "FunctionDef" && s.getObjValAs? String "name" == .ok nm)
    if cluster.size == 1 then
      -- Outermost-first: lift `inner` here, so the names it captures from *this* scope become its
      -- parameters. Only then convert its own nested defs, which can now capture those parameters.
      let (helper, rewritten, spec?) ← liftHelper outerName current cluster[0]! threadedSpecs
      if let some spec := spec? then threadedSpecs := threadedSpecs.push spec
      let (subGroups, helper) ← closureConvertFunction helper
      groups := (groups ++ subGroups).push #[helper]
      current := rewritten
    else
      let (helpers, rewritten) ← liftMutualGroup outerName current cluster
      let mut mutualMembers := #[]
      for helper in helpers do
        let (subGroups, helper) ← closureConvertFunction helper
        groups := groups ++ subGroups
        mutualMembers := mutualMembers.push helper
      groups := groups.push mutualMembers
      current := rewritten
  return (groups, current)

end PastaLean
