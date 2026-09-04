import TypeInfer.Solve.Stamp

namespace TypeInfer

open Lean

/-! ### Interprocedural: return types flow to call sites, argument types flow to parameters -/

/-- Inferred type of each parameter of each user function, by position. -/
abbrev ParamSigs := Std.HashMap String (Array PyType)

/-- Every top-level `FunctionDef` in a module or mutual group, in order. -/
def topFunctions (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter
    (nodeTypeOf · == some "FunctionDef")

/-- Module top-level statements that are not function defs (e.g. `print(add(3, 4))` at module scope):
their call sites refine callee params too, so `add` boxes whether it is called from a def or not. -/
def topLevelStmts (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter
    (nodeTypeOf · != some "FunctionDef")

/-- Top-level `ClassDef`s of a module. -/
def classDefsOf (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter (nodeTypeOf · == some "ClassDef")

/-- The `FunctionDef` methods of a class (stored under `methods`, or `body` on older nodes). -/
def methodsOf (classDef : Json) : Array Json :=
  (#["methods", "body"].foldl (fun acc key =>
    acc ++ (classDef.getObjValAs? (Array Json) key).toOption.getD #[]) #[]).filter
    (nodeTypeOf · == some "FunctionDef")

/-- Names of every class defined at module top level. -/
def classNamesOf (module : Json) : Std.HashSet String :=
  (classDefsOf module).foldl (fun s c => (c.getObjValAs? String "name").toOption.elim s s.insert) {}

/-- True when `fn`'s first parameter is `self` — an instance method, as opposed to a `@staticmethod`. -/
def isInstanceMethod (fn : Json) : Bool := (paramNames fn)[0]? == some "self"

/-- Collect `Class.method(...)` call sites for method-parameter inference, keyed `"Class.method"` (a
dot no Python function name has). Two shapes resolve a class: a qualified call on a class *name*
(`BinaryIndexedTree.lowbit(x)`, static or explicit-`self`) and an instance call whose receiver types
to `.cls C` (`tree.update(a, b)`, `self.query(x)`). An instance method's arg list is prefixed with the
receiver's `.cls C` so it aligns with the `self` parameter. Skips nested defs' own scopes only in that
`env` is the enclosing one; the walk itself is exhaustive. -/
partial def collectMethodCalls (sigs : Sigs) (env : Env) (classNames : Std.HashSet String)
    (methodSelf : Std.HashMap String Bool) (json : Json) : Array (String × Array PyType) :=
  let here : Array (String × Array PyType) :=
    match nodeTypeOf json, getField json "func" with
    | some "Call", some func =>
        -- A constructor call `C(args)` (func is the class NAME) refines `C.__init__`'s params, with a
        -- leading `self : .cls C` — so `Rectangle(5, 10)` types `__init__(self, width, height)`.
        if nodeTypeOf func == some "Name" then
          match (nameId? func).filter classNames.contains with
          | some cname =>
              let args := ((json.getObjValAs? (Array Json) "args").toOption.getD #[]).map (typeOfExpr sigs env)
              #[(s!"{cname}.__init__", #[PyType.cls cname] ++ args)]
          | none => #[]
        else if nodeTypeOf func != some "Attribute" then #[] else
        match (func.getObjValAs? String "attr").toOption, getField func "value" with
        | some attr, some recv =>
            let args := ((json.getObjValAs? (Array Json) "args").toOption.getD #[]).map (typeOfExpr sigs env)
            match nameId? recv with
            -- Qualified on a class name: static (args as-is) or explicit-self (prefix `.cls C`).
            | some rname =>
                if classNames.contains rname then
                  let key := s!"{rname}.{attr}"
                  let args := if (methodSelf.get? key).getD false then #[PyType.cls rname] ++ args else args
                  #[(key, args)]
                else instanceCall attr recv args
            | none => instanceCall attr recv args
        | _, _ => #[]
    | _, _ => #[]
  here ++ (match json with
    | .arr xs => xs.foldl (fun acc x => acc ++ collectMethodCalls sigs env classNames methodSelf x) #[]
    | .obj fs => fs.toList.foldl (fun acc (_, v) => acc ++ collectMethodCalls sigs env classNames methodSelf v) #[]
    | _ => #[])
where
  /-- An instance call `recv.attr(args)` where `recv : .cls C` → `C.attr` with the args prefixed by
  the receiver's `.cls C` (the `self` slot). -/
  instanceCall (attr : String) (recv : Json) (args : Array PyType) : Array (String × Array PyType) :=
    match (typeOfExpr sigs env recv).classNameOf? with
    | some c => #[(s!"{c}.{attr}", #[PyType.cls c] ++ args)]
    | none => #[]

/-- The hint environment for the parameters named in `fn`, drawn from `params[key]` (its inferred
per-position types). `key` is the callee's name — a bare function name, or `"Class.method"` for a
class method. -/
def hintsForKey (params : ParamSigs) (fn : Json) (key : String) : Env := Id.run do
  let names := paramNames fn
  let types := (params.get? key).getD #[]
  let mut env : Env := {}
  for i in [0:names.size] do
    if let some t := types[i]? then if t != .unknown then env := env.insert names[i]! t
  return env

/-- The hint environment for `fn`'s parameters from `params` (its inferred per-position types). -/
def hintsFor (params : ParamSigs) (fn : Json) : Env :=
  hintsForKey params fn ((fn.getObjValAs? String "name").toOption.getD "")

/-- Collect `(calleeName, argumentTypes)` for every direct call `foo(a, b, …)` in `json`, typing the
arguments under `env`. Nested calls are included; method calls are ignored (no positional callee). -/
partial def collectCalls (sigs : Sigs) (env : Env) (json : Json) : Array (String × Array PyType) :=
  let here : Array (String × Array PyType) :=
    if nodeTypeOf json == some "Call" then
      match getField json "func" with
      | some func =>
          match (nodeTypeOf func, (func.getObjValAs? String "id").toOption) with
          | (some "Name", some name) =>
              let args := ((json.getObjValAs? (Array Json) "args").toOption.getD #[]).map (typeOfExpr sigs env)
              #[(name, args)]
          | _ => #[]
      | none => #[]
    else #[]
  let sub := match json with
    | .arr xs => xs.foldl (fun acc x => acc ++ collectCalls sigs env x) #[]
    | .obj fs => fs.toList.foldl (fun acc (_, v) => acc ++ collectCalls sigs env v) #[]
    | _ => #[]
  here ++ sub

/-- The `Name` decorators of a `FunctionDef`, e.g. `@double` → `"double"`. Attribute/Call decorators
(`@a.b`, `@lru_cache(...)`) are skipped — a user decorator whose type we can unify is a bare name. -/
def decoratorNamesOf (fn : Json) : Array String :=
  ((fn.getObjValAs? (Array Json) "decorator_list").toOption.getD #[]).filterMap fun d =>
    if nodeTypeOf d == some "Name" then nameId? d else none

/-- Join `argTypes` into `params[name]` position-by-position (missing positions start `unknown`). -/
def refineParams (params : ParamSigs) (name : String) (arity : Nat) (argTypes : Array PyType) : ParamSigs :=
  let cur := (params.get? name).getD (Array.replicate arity .unknown)
  let next := (Array.range cur.size).map fun i =>
    (cur[i]!).join (argTypes[i]?.getD .unknown)
  params.insert name next

/-- Field types of every class in the module, keyed `"Class.field"` so `typeOfExpr` can type a field
access. Mirrors the struct codegen: an explicit annotation wins; otherwise an `__init__` param
defaulting to `None` types the field `Option Class` (the recursive `TreeNode.left`/`ListNode.next`
pattern); otherwise the initialising param's annotation or the type of its default. -/
def classFieldSigs (module : Json) (params : ParamSigs := {}) : Sigs := Id.run do
  let mut out : Sigs := {}
  for st in topLevelStmts module do
    if nodeTypeOf st != some "ClassDef" then continue
    let .ok cls := st.getObjValAs? String "name" | continue
    let methods := (st.getObjValAs? (Array Json) "methods").toOption.getD #[]
    -- `__init__` params: their declared/default type, and which ones default to `None`.
    let mut ptype : Env := {}
    let mut noneParams : List String := []
    if let some init := methods.find? (·.getObjValAs? String "name" == .ok "__init__") then
      -- Seed from inferred call-site param types (`Rectangle(5, 10)` ⇒ `width, height : int`), so a
      -- field `self.width = width` on an UNannotated param still gets a concrete type.
      let initNames := paramNames init
      let initInferred := (params.get? s!"{cls}.__init__").getD #[]
      for i in [0:initNames.size] do
        if let some t := initInferred[i]? then
          if t != .unknown then ptype := ptype.insert initNames[i]! t
      let argsJson := (getField init "args").getD Json.null
      let argsArr := (argsJson.getObjValAs? (Array Json) "args").toOption.getD #[]
      let defaults := (argsJson.getObjValAs? (Array Json) "defaults").toOption.getD #[]
      let offset := argsArr.size - defaults.size
      for i in [0:argsArr.size] do
        if let .ok nm := argsArr[i]!.getObjValAs? String "arg" then
          if let some ann := getField argsArr[i]! "annotation" then
            if !ann.isNull then ptype := ptype.insert nm (ofAnnotation ann)
          if i ≥ offset then
            let d := defaults[i - offset]!
            if nodeTypeOf d == some "Constant" && (getField d "value") == some Json.null then
              noneParams := nm :: noneParams
            else if !ptype.contains nm then ptype := ptype.insert nm (ofValue d)
    for f in (st.getObjValAs? (Array Json) "fields").toOption.getD #[] do
      if let .ok fname := f.getObjValAs? String "name" then
        let annT := match getField f "annotation" with
          | some ann => if ann.isNull then .unknown else ofAnnotation ann
          | none => .unknown
        -- A class-level variable (`class_var = 0`) has a `default` value but no `self.x = …` init.
        let fromDefault : PyType := match getField f "default" with
          | some d => if d.isNull then .unknown else ofValue d
          | none => .unknown
        let t := if annT != .unknown then annT else
          match getField f "init" with
          | some init =>
              if init.isNull then fromDefault else
              -- `self.left = left` where `left` defaults to `None` → the recursive node pattern.
              match nameId? init with
              | some p =>
                  if noneParams.contains p then .opt (.cls cls) else (ptype.get? p).getD .unknown
              -- A DIRECT `self.x = None` → `Option C`; `self.x = [None]*k` → `List (Option C)` — the
              -- recursive-node child pointer / children array. (These stay class-mentioning so
              -- `stampClassFields` leaves them unannotated for the struct codegen to type.)
              | none =>
                  if isNoneConst init then .opt (.cls cls)
                  else if isListOfNone init then .list (.opt (.cls cls))
                  -- Otherwise type the initialiser itself, under the `__init__` params
                  -- (`self.p = list(range(n))` → `list[int]`, which `ofValue` alone cannot see).
                  else typeOfExpr {} ptype init
          | none => fromDefault
        if t != .unknown then out := out.insert s!"{cls}.{fname}" t
  return out

/-- True when a type names a user class anywhere. Such a type must NOT be written back as an
annotation: the run twin renames `TreeNode` to `TreeNode'rn`, and only the struct codegen's own
class-name path applies that suffix — a literal annotation would pin the unsuffixed name. -/
partial def mentionsClass : PyType → Bool
  | .cls _ => true
  | .list e | .set e | .opt e => mentionsClass e
  | .dict k v => mentionsClass k || mentionsClass v
  | .tuple es => es.any mentionsClass
  | .fn as r => as.any mentionsClass || mentionsClass r
  | _ => false

/-- Write each class field's inferred type into its (empty) `annotation` slot, which the struct
codegen already prefers over its own literal-shape guess — so a container field stops silently
defaulting to `Int`. -/
def stampClassFields (fields : Sigs) (cls : String) (st : Json) : Json :=
  match st.getObjValAs? (Array Json) "fields" with
  | .ok fs => st.setObjVal! "fields" (Json.arr (fs.map fun f =>
      match f.getObjValAs? String "name" with
      | .ok fname =>
          let unannotated := match getField f "annotation" with
            | some ann => ann.isNull
            | none => true
          match unannotated, (fields.get? s!"{cls}.{fname}").filter (!mentionsClass ·) |>.bind toAnnotation? with
          | true, some ann => f.setObjVal! "annotation" ann
          | _, _ => f
      | _ => f))
  | _ => st

/-- Co-evolve every function's return type AND its parameter types to a fixpoint: a callee's return
flows to its callers, and a caller's argument types flow to the callee's parameters. Both only climb
the lattice, so this settles. -/
partial def collectSigs (module : Json) : Sigs × ParamSigs := Id.run do
  let fns := topFunctions module
  -- Seed each function's parameters with their annotations (unknown where unannotated).
  let mut params : ParamSigs := {}
  for fn in fns do
    if let .ok name := fn.getObjValAs? String "name" then
      let seed := paramSeed fn
      params := params.insert name ((paramNames fn).map fun p => (seed.get? p).getD .unknown)
  -- Class methods join the same table under `"Class.method"` keys (a dot no function name has), so
  -- their params are refined from call sites just like a free function's. `methodSelf` records which
  -- take a leading `self` (an instance method) vs a `@staticmethod`, so a qualified `Class.m(...)` call
  -- prefixes the receiver type only for the former.
  let classNames := classNamesOf module
  let methodEntries : Array (String × String × Json) := (classDefsOf module).foldl (fun acc cd =>
    match (cd.getObjValAs? String "name").toOption with
    | some cls => acc ++ (methodsOf cd).filterMap (fun m =>
        (m.getObjValAs? String "name").toOption.map (fun mn => (cls, mn, m)))
    | none => acc) #[]
  let mut methodSelf : Std.HashMap String Bool := {}
  for (cls, mn, m) in methodEntries do
    let key := s!"{cls}.{mn}"
    let seed := paramSeed m
    params := params.insert key ((paramNames m).map fun p => (seed.get? p).getD .unknown)
    methodSelf := methodSelf.insert key (isInstanceMethod m)
  -- Class field types share the `sigs` table under `"Class.field"` keys; a bare class name maps to
  -- `.cls C`, so a `t = C(...)` constructor call types `t` (letting `t.method(...)` resolve `C.method`).
  let mut sigs : Sigs := classFieldSigs module
  for cls in classNames.toList do sigs := sigs.insert cls (.cls cls)
  -- Hints for a method, with `self : .cls C` seeded (an instance method's receiver).
  let methodHints (params : ParamSigs) (cls key : String) (m : Json) : Env :=
    let h := hintsForKey params m key
    if isInstanceMethod m then h.insert "self" (.cls cls) else h
  for _ in [0:6] do
    -- Refresh class field types from the current (refined) `__init__` params so a field on an
    -- unannotated ctor param (`self.width = width`, `width` learned as `int` from `Rectangle(5,10)`)
    -- gets a concrete type — which then types `self.width * self.height` in a method's return.
    sigs := (classFieldSigs module params).fold (fun acc k v => acc.insert k v) sigs
    let mut nextSigs := sigs
    let mut nextParams := params
    let refineFrom (nextParams : ParamSigs) (calls : Array (String × Array PyType)) : ParamSigs :=
      calls.foldl (fun p (callee, argTypes) =>
        if params.contains callee then refineParams p callee argTypes.size argTypes else p) nextParams
    -- Function VALUES (`.fn` with inferred returns): a `g = some_func` / `return some_func` reads as
    -- `callable`, a `func(param_func)` refines `func`'s callback param, and a higher-order
    -- `def func(a): return a()` specialises its return per call.
    let fnEnv : Env := fns.foldl (fun e fn =>
      match fn.getObjValAs? String "name" with
      | .ok nm => (match functionSignatureType fn with
                   | .fn as _ => e.insert nm (.fn as ((sigs.get? nm).getD .unknown))
                   | t => e.insert nm t)
      | _ => e) {}
    for fn in fns do
      if let .ok name := fn.getObjValAs? String "name" then
        let hints := hintsFor params fn
        nextSigs := nextSigs.insert name (returnTypeOf sigs hints fn fnEnv)
        -- refine callees' params from this function's call sites, typed under its own env.
        let env := inferFunction sigs fnEnv hints fn
        nextParams := refineFrom nextParams (collectCalls sigs env fn)
        nextParams := refineFrom nextParams (collectMethodCalls sigs env classNames methodSelf fn)
    -- Class methods: refine callees from each method body, with `self` typed to its class.
    for (cls, mn, m) in methodEntries do
      let key := s!"{cls}.{mn}"
      let hints := methodHints params cls key m
      nextSigs := nextSigs.insert key (returnTypeOf sigs hints m fnEnv)
      let env := inferFunction sigs fnEnv hints m
      nextParams := refineFrom nextParams (collectCalls sigs env m)
      nextParams := refineFrom nextParams (collectMethodCalls sigs env classNames methodSelf m)
    -- Module top-level call sites (outside any def), typed under `fnEnv` (see above).
    for stmt in topLevelStmts module do
      nextParams := refineFrom nextParams (collectCalls sigs fnEnv stmt)
      nextParams := refineFrom nextParams (collectMethodCalls sigs fnEnv classNames methodSelf stmt)
    -- Decorator unification: `@d def g` is `g = d(g_raw)`, so g's type and d's wrapped-parameter
    -- type are the same. Flow each into the other: g's `.fn` type refines d's parameter 0 (so a
    -- decorator's `f` is learned from the function it wraps), and d's parameter 0 — if a function
    -- type — refines g's parameters (so an int-typed decorator pins an otherwise-unknown g's params).
    for fn in fns do
      if let .ok gname := fn.getObjValAs? String "name" then
        for d in decoratorNamesOf fn do
          if nextParams.contains d then
            let gParams := (nextParams.get? gname).getD #[]
            let gRet := (nextSigs.get? gname).getD .unknown
            nextParams := refineParams nextParams d 1 #[PyType.fn gParams.toList gRet]
            match ((nextParams.get? d).getD #[])[0]? with
            | some (PyType.fn argTs _) =>
                nextParams := refineParams nextParams gname gParams.size argTs.toArray
            | _ => pure ()
    let stable := nextSigs.size == sigs.size
      && nextSigs.fold (fun ok k v => ok && (sigs.get? k |>.getD .unknown) == v) true
      && nextParams.fold (fun ok k v => ok && (params.get? k |>.getD #[]) == v) true
    sigs := nextSigs; params := nextParams
    if stable then break
  return (sigs, params)

/-- Stamp ONLY tuple-unpack shapes (`_tuple_unpack`/`_list_unpack`/`_unpack_container_mask`) across a
statement tree, driven by interprocedural `sigs`/`env`. Used for the `__main__` guard body: it runs at
module scope but — unlike a function body — must NOT get the full `stampStmt` treatment, whose
`stampTarget` value-type ascriptions would perturb byte-identical value-mode output (the guard was
historically unstamped). Single-value container returns are already handled by the driver's
`_returns_container` pass; only the per-element unpack mask (nothing else supplies it) is needed so
`xs, ys = make_pair()` registers each target as a container-ref under `--heap`. -/
partial def stampUnpackShapes (sigs : Sigs) (env : Env) (s : Json) : Json :=
  if nodeTypeOf s == some "FunctionDef" then s
  else Id.run do
    let mut s := s
    if nodeTypeOf s == some "For" then
      match getField s "target", getField s "iter" with
      | some target, some iter =>
          if nodeTypeOf target == some "Tuple" then
            s := s.setObjVal! "target" (stampUnpackShape target (typeOfExpr sigs env iter).elemType)
      | _, _ => pure ()
    if nodeTypeOf s == some "Assign" then
      match getField s "target", getField s "value" with
      | some target, some value =>
          if nodeTypeOf target == some "Tuple" then
            s := s.setObjVal! "target" (stampUnpackShape target (typeOfExpr sigs env value))
      | _, _ => pure ()
    for f in #["body", "orelse", "finalbody"] do
      if let .ok elems := s.getObjValAs? (Array Json) f then
        s := s.setObjVal! f (Json.arr (elems.map (stampUnpackShapes sigs env)))
    return s

/-- Benchmark-only: stamp `_bench_ty` on a target — a Name from its `globals` type, or a tuple/list
target by distributing the value type `ty` over its leaves (nested unpack included). Codegen never
reads `_bench_ty`, so this is inert for translation. -/
partial def stampBenchTarget (globals : Env) (ty : PyType) : Json → Json
  | t =>
    match nodeTypeOf t with
    | some "Name" =>
        match ((nameId? t).bind globals.get?).bind (fun gt => toAnnotation? (containerFillAny gt)) with
        | some ann => t.setObjVal! "_bench_ty" ann
        | none => match toAnnotation? (containerFillAny ty) with
                  | some ann => t.setObjVal! "_bench_ty" ann
                  | none => t
    | some "Starred" =>
        match getField t "value" with
        | some inner => t.setObjVal! "value" (stampBenchTarget globals (.list ty.elemType) inner)
        | none => t
    | some "Tuple" | some "List" =>
        match t.getObjValAs? (Array Json) "elts" with
        | .ok elts =>
            let elemTypes : Nat → PyType := match ty with
              | .tuple es => fun i => es[i]?.getD .unknown
              | _ => fun _ => ty.elemType
            t.setObjVal! "elts" (Json.arr ((Array.range elts.size).map fun i =>
              stampBenchTarget globals (elemTypes i) elts[i]!))
        | _ => t
    | _ => t

/-- Stamp `_ty` across one top-level node, resolving calls with `sigs` and seeding each function's
unannotated params from `params`. The driver sends one statement per request; a `FunctionDef`, a
`ClassDef` (each method) or a `Module` (a mutual group) is stamped, anything else is unchanged. -/
partial def stampNodeWith (sigs : Sigs) (params : ParamSigs) (globals : Env) (s : Json) : Json :=
  -- Seed a function with module-level globals, minus any name its own parameters shadow (params win).
  let outerFor (fn : Json) : Env := (paramNames fn).foldl (·.erase ·) globals
  match nodeTypeOf s with
  | some "FunctionDef" => stampFunction sigs (outerFor s) (hintsFor params s) s
  | some "ClassDef" =>
      let cls := (s.getObjValAs? String "name").toOption.getD ""
      let s := if cls.isEmpty then s else stampClassFields sigs cls s
      -- A class keeps its methods under "methods"; older nodes use "body". Each method's params are
      -- keyed `"Class.method"` in `params` (from call-site inference), and `self : .cls Class` seeds
      -- the outer env so `self.field`/`self.method(...)` resolve.
      #["methods", "body"].foldl (fun s key =>
        match s.getObjValAs? (Array Json) key with
        | .ok ms => s.setObjVal! key (Json.arr (ms.map fun m =>
            if nodeTypeOf m == some "FunctionDef" then
              let mn := (m.getObjValAs? String "name").toOption.getD ""
              let outer := if isInstanceMethod m then (outerFor m).insert "self" (.cls cls) else outerFor m
              let stamped := stampFunction sigs outer (hintsForKey params m s!"{cls}.{mn}") m
              -- Method return types live in `sigs` under the qualified `Class.method` key, which
              -- stampFunction's bare-name lookup misses; fill `_ret_ty` here when unstamped/unboxed.
              if (getField stamped "_ret_ty").isNone && (getField stamped "_box_return").isNone then
                match (sigs.get? s!"{cls}.{mn}").bind (fun t => toAnnotation? (containerFillAny t)) with
                | some ann => stamped.setObjVal! "_ret_ty" ann
                | none => stamped
              else stamped
            else m))
        | _ => s) s
  | some "Module" =>
      match s.getObjValAs? (Array Json) "body" with
      | .ok body => s.setObjVal! "body" (Json.arr (body.map (stampNodeWith sigs params globals)))
      | _ => s
  | some "If" =>
      -- The `__main__` guard lowers to Lean's `def main`; its body runs at module scope but is only
      -- reached by the intraprocedural per-request fallback (empty `sigs`), which resolves every call
      -- to `.unknown` and so misses the tuple-unpack container mask for `xs, ys = make_pair()`. Stamp
      -- just the unpack shapes here with the full interprocedural `sigs` — NOT the full `stampStmt`,
      -- whose value-type ascriptions would perturb byte-identical value-mode output.
      if (s.getObjValAs? Bool "is_main_guard").toOption == some true then
        let genv := inferFunction sigs globals {} s
        let stampBlock (key : String) (s : Json) : Json :=
          match s.getObjValAs? (Array Json) key with
          | .ok body => s.setObjVal! key (Json.arr (body.map (stampUnpackShapes sigs genv)))
          | _ => s
        stampBlock "orelse" (stampBlock "body" s)
      else s
  | some "Assign" | some "AnnAssign" | some "AugAssign" | some "For" =>
      -- Benchmark-only: stamp a module-level target's inferred type as `_bench_ty` (codegen ignores
      -- it) so the harness sees top-level variable inferences. Never writes `_ty`, so byte-identical
      -- value-mode codegen is unperturbed. A tuple/list target distributes the value's type over its
      -- leaves (nested unpack included), mirroring `bindTargetType`.
      match getField s "target" with
      | some t =>
          -- The type a Name leaf gets: its own `globals` type (flow-insensitive final), which for a
          -- unique unpack target is exactly what the value distributes.
          let valTy := (getField s "value").elim .unknown (typeOfExpr sigs globals)
          s.setObjVal! "target" (stampBenchTarget globals valTy t)
      | none => s
  | _ => s

/-- Intraprocedural stamping of a single node (no cross-function info). Used per-request as a
fallback; `inferModule` supersedes it when the whole module is available. -/
partial def stampNode (s : Json) : Json := stampNodeWith {} {} {} s

/-- Whole-module inference: co-evolve return and parameter types to a fixpoint, then stamp each
top-level node with that knowledge. This is what the `inferTypes` backend task runs. -/
def inferModule (module : Json) : Json :=
  let (sigs, params) := collectSigs module
  -- Module-level globals (`inf = float('inf')`, config constants) seed every function so a body that
  -- reads a global sees its type — e.g. `f = [[inf]*k for _ in range(n)]` becomes `list[list[float]]`.
  -- Top-level function names are seeded as their `.fn` value type so a `g = some_func` reference (a
  -- function value) reads as `callable`; `topLevelStmts` drops the defs themselves.
  let fnSeed : Env := (topFunctions module).foldl (fun e fn =>
    match fn.getObjValAs? String "name" with
    | .ok nm =>
        -- Use the INFERRED return (from `sigs`) for the function value, not just its annotation, so a
        -- `g = some_func; g()` resolves `g()` to `some_func`'s real return type.
        let sig := match functionSignatureType fn with
          | .fn as _ => .fn as ((sigs.get? nm).getD .unknown)
          | t => t
        e.insert nm sig
    | _ => e) {}
  let globals : Env := (topLevelStmts module).foldl (applyStmt sigs) fnSeed
  -- Mark each statement `_inferred` so the per-request fallback pass (which lacks module context and
  -- would re-derive worse types, e.g. a global-fed `float` local mis-stamped `int`) skips it.
  let mark (s : Json) : Json := (stampNodeWith sigs params globals s).setObjVal! "_inferred" (Json.bool true)
  match module.getObjValAs? (Array Json) "body" with
  | .ok body => module.setObjVal! "body" (Json.arr (body.map mark))
  | _ => mark module


end TypeInfer
