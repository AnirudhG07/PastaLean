import TypeInfer.Solve.Usage

namespace TypeInfer

open Lean


/-- Every `FunctionDef` reachable in `json` (the function itself + nested helpers) → its parameters'
ANNOTATED types (unannotated ⇒ `.unknown`). Lets `usageType` type an argument from the callee's
annotation: `digits(x: int)` ⇒ a value passed to `digits` is `int`. -/
partial def collectFnParams (json : Json) : Std.HashMap String (Array PyType) := Id.run do
  let mut m : Std.HashMap String (Array PyType) := {}
  let here : Option (String × Array PyType) := do
    guard (nodeTypeOf json == some "FunctionDef")
    let nm ← (json.getObjValAs? String "name").toOption
    let args ← ((json.getObjVal? "args").toOption).bind (fun a => (a.getObjValAs? (Array Json) "args").toOption)
    let ptys := args.map fun a => match getField a "annotation" with
      | some ann => if ann.isNull then PyType.unknown else ofAnnotation ann
      | none => PyType.unknown
    some (nm, ptys)
  if let some (nm, ptys) := here then m := m.insert nm ptys
  match json with
  | .arr xs => for x in xs do m := (collectFnParams x).fold (fun a k v => a.insert k v) m
  | .obj fs => for (_, v) in fs do m := (collectFnParams v).fold (fun a k v => a.insert k v) m
  | _ => pure ()
  return m

/-- Seed each unannotated parameter from unambiguous body usage (`p.split()` → str, `p.append()` →
list, `p.keys()` → dict). This is the safe part of the use-based inference the old Python pre-pass did. -/
def paramUsageSeed (fn : Json) : Env := Id.run do
  let body := fn.getObjValAs? (Array Json) "body" |>.toOption.getD #[]
  let fnParams := collectFnParams fn
  -- Known scalar types of names, for the ordered-comparison anchor: param annotations plus any local
  -- assigned a literal (`ans = ""` ⇒ str, `lo = 0` ⇒ int), so `word < ans` pins `word` to `str` and
  -- `x < lo` pins `x` to `int` — soundly (ordered comparison needs order-compatible operands).
  let mut known : Env := paramSeed fn
  let learnLit (m : Env) (tgt : Json) (val : Option Json) : Env :=
    match nameId? tgt, val.bind literalType? with
    | some nm, some t => if t == .unknown then m else m.insert nm ((m.get? nm |>.getD .unknown).join t)
    | _, _ => m
  for s in flatStmts body.toList do
    if nodeTypeOf s == some "Assign" then
      let val := getField s "value"
      for tgt in (getField s "targets").elim #[] (fun t => (t.getArr?).toOption.getD #[]) do
        match nodeTypeOf tgt, val.bind (fun v => getField v "elts") with
        -- `a, b = 0, ""`: zip tuple targets with tuple-literal values.
        | some "Tuple", some (.arr vs) =>
            for (te, ve) in ((tgt.getObjValAs? (Array Json) "elts").toOption.getD #[]).zip vs do
              known := learnLit known te (some ve)
        | _, _ => known := learnLit known tgt val
  let mut env : Env := {}
  for name in paramNames fn do
    -- fuel 1: loop-variable inference may fire at the top level but not nest (see `usageType`).
    let t := usageType fnParams known 1 name (Json.arr body)
    if t != .unknown then env := env.insert name t
  return env

/-- Names `fn` binds directly — params plus `=`/`for`/annotated targets in its own body (through
`if`/`for` blocks, not into deeper nested defs). A name used in `fn` but NOT here is a capture of an
enclosing scope. -/
def localAssignNames (fn : Json) : List String := Id.run do
  let mut names := (paramNames fn).toList
  for s in flatStmts ((fn.getObjValAs? (Array Json) "body").toOption.getD #[]).toList do
    match nodeTypeOf s with
    | some "Assign" =>
        for t in (s.getObjValAs? (Array Json) "targets").toOption.getD #[] do
          if let some n := nameId? t then names := n :: names
    | some "AnnAssign" | some "AugAssign" | some "For" =>
        if let some n := (getField s "target").bind nameId? then names := n :: names
    | _ => pure ()
  return names

/-- The container name a teaching METHOD mutation (`xs.append(v)`, `s.add(v)`) targets, for the
capture pass. Only `recv.method(...)` receivers — a free `heappush(h, v)` capture is rarer and left to
the enclosing-scope pass. -/
def mutationReceiverName? (value : Json) : Option String :=
  if nodeTypeOf value != some "Call" then none else
  match getField value "func" with
  | some func =>
      if nodeTypeOf func == some "Attribute" then
        match getField func "value" with
        | some recv =>
            if ((Libraries.methodBehaviour? ((func.getObjValAs? String "attr").toOption.getD "")).bind (·.teaches?)).isSome
            then match nameId? recv with
              | some n => some n
              -- `nums[i].append(v)`: the mutated container is the subscript BASE (`nums`).
              | none => if nodeTypeOf recv == some "Subscript" then (getField recv "value").bind nameId? else none
            else none
        | none => none
      else none
  | none => none

/-- Every positional argument list of a call `name(...)` anywhere in `json`. -/
partial def collectCallArgLists (name : String) (json : Json) : Array (Array Json) :=
  let here := if nodeTypeOf json == some "Call" && (getField json "func").bind nameId? == some name
    then #[(json.getObjValAs? (Array Json) "args").toOption.getD #[]] else #[]
  let rest := match json with
    | .arr xs => xs.foldl (fun acc e => acc ++ collectCallArgLists name e) #[]
    | .obj fs => fs.toList.foldl (fun acc (_, v) => acc ++ collectCallArgLists name v) #[]
    | _ => #[]
  here ++ rest

/-- Param-type hints for a nested def `fn` from the arg types at every call to it in `roots`. Two
passes so a recursive arg (`dfs(node.left)`) is re-typed once its param is seeded from the first,
non-recursive call (`dfs(root)`) — the join is what makes a tree `dfs` param `Optional[TreeNode]`. -/
def nestedParamHints (sigs : Sigs) (env : Env) (fn : Json) (roots : Array Json) : Env := Id.run do
  let name := (fn.getObjValAs? String "name").toOption.getD ""
  let params := paramNames fn
  if name == "" || params.isEmpty then return {}
  let callLists := roots.foldl (fun acc r => acc ++ collectCallArgLists name r) #[]
  if callLists.isEmpty then return {}
  let mut hints : Env := {}
  for _ in [0:2] do
    let env2 := hints.fold (fun m k v => m.insert k v) env
    for args in callLists do
      for i in [0:min params.size args.size] do
        let t := typeOfExpr sigs env2 args[i]!
        if t != .unknown then
          hints := hints.insert params[i]! (((hints.get? params[i]!).getD .unknown).join t)
  return hints

/-- The combined parameter types of every nested `def` in `body`, from their call sites (`roots` is
the enclosing body). Lets a captured `d[param].append(v)` INSIDE a nested def teach the OUTER `d`'s
key from `param`'s type — which lives only in the inner scope. -/
def nestedDefParamEnv (sigs : Sigs) (env : Env) (body : Array Json) (roots : Array Json) : Env :=
  body.foldl (fun e nf =>
    if nodeTypeOf nf == some "FunctionDef"
    then (nestedParamHints sigs env nf roots).fold (fun m k v => m.insert k v) e
    else e) {}

/-- Apply container-teaching mutations found INSIDE nested defs to the enclosing `env`, so a capture
learns its element type across scopes (`nums = []` here, `nums.append(x)` in a sibling `def dfs`, then
`nums[i]` in `def build` — all one `List Int`). A name a nested def binds itself (param or `=`) is a
shadow, not a capture, so it is skipped; only names already in `env` are refined (join-only, never a
downgrade). `paramEnv` carries the enclosing nested def's parameter types so `d[param]` inside it can
pin the captured `d`'s key. The enclosing scope's own mutations are handled by `applyStmt`. -/
partial def applyCaptureMutations (sigs : Sigs) (shadowed : List String) (paramEnv : Env)
    (insideDef : Bool) (env : Env) (json : Json) : Env := Id.run do
  let entering := nodeTypeOf json == some "FunctionDef"
  let shadowed := if entering then shadowed ++ localAssignNames json else shadowed
  let inside := insideDef || entering
  let mut env := env
  if inside then
    if let some cname := mutationReceiverName? json then
      if !shadowed.contains cname && (env.get? cname).isSome then
        -- Type the mutation with the enclosing nested def's params visible (`d[offset]` needs
        -- `offset : int`), but write back ONLY the receiver so those inner params never leak out.
        let typingEnv := paramEnv.fold (fun m k v => m.insert k v) env
        match (applyMutation sigs typingEnv json).get? cname with
        | some t => env := env.insert cname t
        | none => pure ()
  match json with
  | .arr xs => return xs.foldl (applyCaptureMutations sigs shadowed paramEnv inside) env
  | .obj fs => return fs.toList.foldl (fun e (_, v) => applyCaptureMutations sigs shadowed paramEnv inside e v) env
  | _ => return env

/-- Every `(container-name, index-type)` from a subscript READ `base[idx]` anywhere in `json` (`base`
a plain Name, not a slice). Container writes already teach element types (`applyStmt`/`applyMutation`),
but the KEY of a dict is only pinned by *usage* — `d = defaultdict(int)` knows its value type yet
leaves the key `unknown` until a `d[k]` read fixes it. This is the read side of Python's
"infer from all usages". -/
partial def collectSubscriptKeys (sigs : Sigs) (env : Env) (json : Json) : Array (String × PyType) :=
  let here : Array (String × PyType) :=
    if nodeTypeOf json == some "Subscript" then
      match (getField json "value").bind nameId?, getField json "slice" with
      | some cname, some slice =>
          if nodeTypeOf slice == some "Slice" then #[] else #[(cname, typeOfExpr sigs env slice)]
      | _, _ => #[]
    else #[]
  let rest := match json with
    | .arr xs => xs.foldl (fun acc e => acc ++ collectSubscriptKeys sigs env e) #[]
    | .obj fs => fs.toList.foldl (fun acc (_, v) => acc ++ collectSubscriptKeys sigs env v) #[]
    | _ => #[]
  here ++ rest

/-- Pin a dict's KEY type from every subscript-read `d[k]`, joining `typeof(k)` into the key. Only
touches names ALREADY typed as a dict (so a list `xs[i]` is never mis-widened to a dict); a genuinely
undetermined container stays undetermined here — the write side decides list-vs-dict. -/
def learnFromReads (sigs : Sigs) (env : Env) (json : Json) : Env :=
  (collectSubscriptKeys sigs env json).foldl (fun e (cname, kt) =>
    if kt == .unknown then e else
    match e.get? cname |>.getD .unknown with
    | .dict k v => e.insert cname (.dict (k.join kt) v)
    | _ => e) env

/-- Collect `(dictName, keyType, valType)` from every dict-method call `d.pop(k, default)` /
`d.get(k, default)` / `d.setdefault(k, v)` — the key is arg 0, the value the (optional) arg 1. `.pop`
is also a LIST method (`xs.pop(i)`), so the caller must guard on `d` already being dict-typed. -/
partial def collectDictKV (sigs : Sigs) (env : Env) (json : Json) : Array (String × PyType × PyType) :=
  let here : Array (String × PyType × PyType) :=
    if nodeTypeOf json == some "Call" then
      match getField json "func" with
      | some func =>
          if nodeTypeOf func == some "Attribute"
              && ["pop", "get", "setdefault"].contains ((func.getObjValAs? String "attr").toOption.getD "") then
            match (getField func "value").bind nameId? with
            | some dname =>
                let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
                let kt := if args.size ≥ 1 then typeOfExpr sigs env args[0]! else .unknown
                let vt := if args.size ≥ 2 then typeOfExpr sigs env args[1]! else .unknown
                #[(dname, kt, vt)]
            | none => #[]
          else #[]
      | none => #[]
    else #[]
  let rest := match json with
    | .arr xs => xs.foldl (fun acc e => acc ++ collectDictKV sigs env e) #[]
    | .obj fs => fs.toList.foldl (fun acc (_, v) => acc ++ collectDictKV sigs env v) #[]
    | _ => #[]
  here ++ rest

/-- Refine a dict's key/value from `d.pop`/`.get`/`.setdefault` calls (see `collectDictKV`). Only
touches names ALREADY dict-typed — a bare `dict` param seeds as `dict[⊥,⊥]`, so a `counts.pop(k, -1)`
fills its key/value in and it materialises as a concrete `Std.HashMap`, not a stuck metavariable. -/
def learnFromDictMethods (sigs : Sigs) (env : Env) (json : Json) : Env :=
  (collectDictKV sigs env json).foldl (fun e (cname, kt, vt) =>
    match e.get? cname |>.getD .unknown with
    | .dict k v => e.insert cname (.dict (if kt == .unknown then k else k.join kt)
                                         (if vt == .unknown then v else v.join vt))
    | _ => e) env

/-- Infer a type for every local in `fn`, reflowing to a fixpoint. `outer` seeds the environment
with the enclosing scope so a nested def's captures start typed; `hints` seeds unannotated
parameters with types learned from call sites; `sigs` resolves calls to user functions. Precedence:
enclosing captures > annotations > call-site hints > body-usage. -/
partial def inferFunction (sigs : Sigs) (outer hints : Env) (fn : Json) : Env := Id.run do
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let stmts := flatStmts body.toList
  -- Weakest → strongest: body-usage, enclosing captures, call-site hints, annotations. Hints and
  -- annotations override captures because a parameter shadows an outer name of the same name (a
  -- nested `def dfs(root)` inside a scope with its own `root` must use its call-site type).
  -- A bare container from an annotation/hint (`list`/`set`/`dict` with `.any`/`.unknown` element)
  -- keeps a concrete element that body-usage found: `l: list` + `[x+1 for x in l]` ⇒ `list[int]`.
  -- Shape and concretely-named elements still win over usage.
  let refineElem (ann usage : PyType) : PyType :=
    let pick (a u : PyType) : PyType := if a == .any || a == .unknown then (if u.isKnown then u else a) else a
    match ann, usage with
    | .list a, .list u => .list (pick a u)
    | .set a, .set u => .set (pick a u)
    | .dict ak av, .dict uk uv => .dict (pick ak uk) (pick av uv)
    | _, _ => ann
  let mergeRefining (src : Env) (env : Env) : Env :=
    src.fold (fun m k v => m.insert k (refineElem v (m.get? k |>.getD .unknown))) env
  let mut env := paramUsageSeed fn
  env := mergeRefining outer env
  env := mergeRefining hints env
  env := mergeRefining (paramSeed fn) env
  let bodyJson := Json.arr body
  -- Reflow until stable. The lattice climbs, so a small cap is a sound floor, not a correctness risk.
  for _ in [0:8] do
    -- `compBindings` types comprehension targets so a call inside a comprehension can hint the callee
    -- (`[f(point) for point in data]`). It binds only FRESH names — a comprehension target that
    -- shadows an outer variable owns a separate scope (Python-3), so clobbering the outer type (a
    -- loop `v : int` vs a comprehension `v : list[int]` → `any`) would poison it. Fresh-only respects
    -- that: never downgrade an outer binding.
    let paramEnv := nestedDefParamEnv sigs env body #[bodyJson]
    let stepped := applyCaptureMutations sigs [] paramEnv false (stmts.foldl (applyStmt sigs) env) bodyJson
    let stepped := learnFromReads sigs stepped bodyJson
    let stepped := learnFromDictMethods sigs stepped bodyJson
    let next := compBindings sigs stepped bodyJson
    if next.size == env.size && next.fold (fun ok k v => ok && (env.get? k |>.getD .unknown) == v) true then
      env := next
      break
    env := next
  return env

/-- The type `fn` returns: the join of every `return <e>` under its inferred environment. A bare
`return` (no value) or falling off the end contributes `None`. -/
partial def returnTypeOf (sigs : Sigs) (hints : Env) (fn : Json) : PyType := Id.run do
  let env := inferFunction sigs {} hints fn
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let mut ret : PyType := .unknown
  for s in flatStmts body.toList do
    if nodeTypeOf s == some "Return" then
      match getField s "value" with
      | some v => if !v.isNull then ret := ret.join (typeOfExpr sigs env v) else ret := ret.join .none
      | none => ret := ret.join .none
  return ret


end TypeInfer
