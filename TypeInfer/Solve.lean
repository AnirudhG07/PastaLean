import TypeInfer.Rules

/-!
# The intraprocedural fixpoint

`inferFunction` works out a type for every local in one function: seed the parameters from their
annotations, then walk the body over and over — learning a little more each pass — until nothing
changes. Because every update only `join`s upward, the environment can only climb the lattice, so
it settles.

`stampTypes` then writes each settled type back onto the IR as a `_ty` field on the binder
(parameters, assignment targets, `for` targets), where the code generator reads it.

Nested `def`s are handled by seeding their inference with the enclosing function's environment, so a
captured variable already has a type when the helper is lifted out.
-/

namespace TypeInfer

open Lean

private def nodeTypeOf (j : Json) : Option String := (j.getObjValAs? String "node_type").toOption
private def getField (j : Json) (k : String) : Option Json := (j.getObjVal? k).toOption
private def nameId? (j : Json) : Option String :=
  if nodeTypeOf j == some "Name" then (j.getObjValAs? String "id").toOption else none

/-- For a (possibly nested) subscript target `f[h][i][j]`, the base name `f` and the nesting depth
(here `3`), so codegen can learn `f : list[list[list[<v>]]]` from a deep `f[h][i][j] = v`. -/
private partial def subscriptBaseDepth (target : Json) : Option (String × Nat) :=
  if nodeTypeOf target == some "Subscript" then
    match getField target "value" with
    | some v => match nameId? v with
        | some n => some (n, 1)
        | none => (subscriptBaseDepth v).map (fun (b, d) => (b, d + 1))
    | none => none
  else none

/-- The statement lists nested directly in `s` (`if`/`for`/`while`/`with`/`try` blocks), not
descending into a nested `def`/`class` (those have their own scope). -/
private def childBlocks (s : Json) : List (List Json) := Id.run do
  if nodeTypeOf s == some "FunctionDef" || nodeTypeOf s == some "ClassDef" then return []
  let mut blocks := #[]
  for f in #["body", "orelse", "finalbody"] do
    if let .ok elems := s.getObjValAs? (Array Json) f then blocks := blocks.push elems.toList
  if let .ok handlers := s.getObjValAs? (Array Json) "handlers" then
    for h in handlers do
      if let .ok elems := h.getObjValAs? (Array Json) "body" then blocks := blocks.push elems.toList
  return blocks.toList

/-- A bare `container.append/add(v)` statement, teaching the container's element type. The receiver
may itself be an index (`graph[k].append(v)` on a `defaultdict(list)`), which teaches the OUTER
container's value type instead. -/
def applyMutation (sigs : Sigs) (env : Env) (value : Json) : Env :=
  if nodeTypeOf value != some "Call" then env else
  match getField value "func" with
  | some func =>
      let args := ((value.getObjValAs? (Array Json) "args").toOption.getD #[]).toList
      -- A method's RECEIVER is effective argument 0, so `xs.append(v)` and `heappush(h, v)` share one
      -- path — the member's `Behaviour.teaches?` says which effective arg is the container and which
      -- is the element, and how (list / set / spliced-elements). The engine hardcodes no member name.
      let behArgs? : Option (Libraries.Behaviour × List Json) := match nodeTypeOf func with
        | some "Name" =>
            (Libraries.bareBehaviour? ((func.getObjValAs? String "id").toOption.getD "")).map (·, args)
        | some "Attribute" => match getField func "value" with
            | some recv =>
                (Libraries.methodBehaviour? ((func.getObjValAs? String "attr").toOption.getD "")).map (·, recv :: args)
            | none => none
        | _ => none
      match behArgs?.bind (fun (b, ea) => b.teaches?.map (·, ea)) with
      | some (teach, ea) =>
          let typeAt (i : Nat) : PyType := (ea[i]?).elim .unknown (typeOfExpr sigs env)
          let (cIdx, learned) : Nat × PyType := match teach with
            | .pushList c e => (c, .list (typeAt e))
            | .pushSet c e => (c, .set (typeAt e))
            | .extendList c e => (c, match typeAt e with | .list x => .list x | _ => .unknown)
          if learned == .unknown then env else
          let join1 (n : String) (t : PyType) : Env := env.insert n ((env.get? n |>.getD .unknown).join t)
          match ea[cIdx]? with
          | some target => match nameId? target with
              | some cname => join1 cname learned
              -- `graph[k].append(v)`: the mutated value is at `k`, so `graph` is a dict/list of it.
              | none => if nodeTypeOf target == some "Subscript" then
                  match (getField target "value").bind nameId? with
                  | some base =>
                      let kt := (getField target "slice").elim .unknown (typeOfExpr sigs env)
                      let outer := match env.get? base |>.getD .unknown with
                        | .list _ => .list learned | _ => .dict kt learned
                      join1 base outer
                  | none => env
                else env
          | none => env
      | none => env
  | none => env

/-- Bind an assignment/loop/comprehension target to type `t`, distributing a tuple type over a
tuple target (`a, b = pair`). Only joins known facts in. -/
partial def bindTargetType (env : Env) (target : Json) (t : PyType) : Env :=
  match nodeTypeOf target with
  | some "Name" =>
      match nameId? target with
      | some n => if t == .unknown then env else env.insert n ((env.get? n |>.getD .unknown).join t)
      | none => env
  | some "Tuple" | some "List" =>
      let elts := (target.getObjValAs? (Array Json) "elts").toOption.getD #[]
      match t with
      | .tuple es => (Array.range elts.size).foldl (fun e i => bindTargetType e elts[i]! (es[i]?.getD .unknown)) env
      | _ => elts.foldl (fun e elt => bindTargetType e elt t.elemType) env
  | _ => env

/-- A `FunctionDef`'s type as a value: `fn[param annotations] → return annotation` (un-annotated
slots are `unknown`). Lets a nested def referenced by name (`return mul`, `key=mul`) be typed as a
function, so a higher-order caller's callback param is refined from the call site. -/
private def functionSignatureType (fn : Json) : PyType :=
  let args := ((getField fn "args").bind (fun a => (a.getObjValAs? (Array Json) "args").toOption)).getD #[]
  let argTypes := args.toList.map fun a =>
    match getField a "annotation" with
    | some ann => if ann.isNull then PyType.unknown else ofAnnotation ann
    | none => PyType.unknown
  let ret := match getField fn "returns" with
    | some r => if r.isNull then PyType.unknown else ofAnnotation r
    | none => PyType.unknown
  PyType.fn argTypes ret

/-- Update the environment with what one statement teaches us. Only ever `join`s facts in. -/
def applyStmt (sigs : Sigs) (env : Env) (s : Json) : Env :=
  let learn (env : Env) (name : String) (t : PyType) : Env :=
    if t == .unknown then env else env.insert name ((env.get? name |>.getD .unknown).join t)
  match nodeTypeOf s with
  -- A nested `def foo(...)` binds `foo` to its function type, so `return foo` / `key=foo` is typed.
  | some "FunctionDef" =>
      match s.getObjValAs? String "name" with
      | .ok nm => env.insert nm (functionSignatureType s)
      | _ => env
  | some "AnnAssign" =>
      match (getField s "target").bind nameId?, getField s "annotation" with
      | some name, some ann => env.insert name (ofAnnotation ann)   -- an explicit annotation wins
      | _, _ => env
  | some "Assign" =>
      match getField s "target", getField s "value" with
      | some target, some value =>
          match nameId? target with
          | some name => learn env name (typeOfExpr sigs env value)
          -- `xs[i] = v` teaches the element/value type of the container `xs`.
          | none =>
              -- A TUPLE target distributes, exactly as in a `for` (`a, (b, c) = …` after desugaring
              -- leaves `b, c = tmp`, whose element types are what pick tuple- over list-unpacking).
              if nodeTypeOf target == some "Tuple" || nodeTypeOf target == some "List" then
                bindTargetType env target (typeOfExpr sigs env value)
              else if nodeTypeOf target == some "Subscript" then
                match (getField target "value").bind nameId? with
                | some cname =>
                    let vt := typeOfExpr sigs env value
                    -- A SLICE target (`t[a:b] = xs`) replaces a run with a LIST, so `t` and the RHS
                    -- share a type; an INDEX target (`t[i] = v`) makes `t` a list OF `v`'s type.
                    let isSlice := (getField target "slice").any (nodeTypeOf · == some "Slice")
                    let learned := match env.get? cname |>.getD .unknown with
                      | .dict _ _ => .dict ((getField target "slice").elim .unknown (typeOfExpr sigs env)) vt
                      | _ => if isSlice then vt else .list vt
                    learn env cname learned
                -- Nested `f[h][i][j] = v` teaches `f : list[list[list[<v>]]]` (grid/tensor DP).
                | none => match subscriptBaseDepth target with
                    | some (base, depth) =>
                        learn env base ((List.range depth).foldl (fun t _ => PyType.list t) (typeOfExpr sigs env value))
                    | none => env
              else env
      | _, _ => env
  | some "AugAssign" =>
      match getField s "target", getField s "value" with
      | some target, some value =>
          match nameId? target with
          | some name => learn env name (arith (env.get? name |>.getD .unknown) (typeOfExpr sigs env value))
          -- `counts[k] += 1` teaches both sides of `counts` (a `Counter()` starts fully unknown).
          | none =>
              if nodeTypeOf target == some "Subscript" then
                match (getField target "value").bind nameId? with
                | some cname =>
                    let vt := typeOfExpr sigs env value
                    let isSlice := (getField target "slice").any (nodeTypeOf · == some "Slice")
                    let learned := match env.get? cname |>.getD .unknown with
                      | .dict _ v => .dict ((getField target "slice").elim .unknown (typeOfExpr sigs env)) (arith v vt)
                      | _ => if isSlice then vt else .list vt
                    learn env cname learned
                -- Nested `f[h][i][j] += v` widens the deep element (`join` at that depth).
                | none => match subscriptBaseDepth target with
                    | some (base, depth) =>
                        learn env base ((List.range depth).foldl (fun t _ => PyType.list t) (typeOfExpr sigs env value))
                    | none => env
              else env
      | _, _ => env
  | some "For" =>
      match getField s "target", getField s "iter" with
      -- `bindTargetType` also distributes over a TUPLE target (`for a, b in pairs`), which a plain
      -- name lookup misses — leaving `a`/`b` untyped, and anything they index untyped in turn.
      | some target, some iter => bindTargetType env target (typeOfExpr sigs env iter).elemType
      | _, _ => env
  -- `xs.append(v)` / `xs.add(v)` teaches that `xs` holds values of `v`'s type.
  | some "Expr" =>
      match getField s "value" with
      | some value => applyMutation sigs env value
      | none => env
  | _ => env

/-- Bind a comprehension target's names, but ONLY where the name is not already bound in `outer` — a
comprehension target that shadows an outer variable owns a separate (Python-3) scope, so it must not
overwrite the outer type. Fresh names are bound (harmless, and lets a call inside the comprehension
hint the callee); shadowing names are left as the outer binding. -/
private partial def bindCompTargetFresh (outer : Env) (env : Env) (target : Json) (t : PyType) : Env :=
  match nodeTypeOf target with
  | some "Name" =>
      match nameId? target with
      | some n => if outer.contains n || t == .unknown then env else env.insert n t
      | none => env
  | some "Tuple" | some "List" =>
      let elts := (target.getObjValAs? (Array Json) "elts").toOption.getD #[]
      match t with
      | .tuple es => (Array.range elts.size).foldl (fun e i => bindCompTargetFresh outer e elts[i]! (es[i]?.getD .unknown)) env
      | _ => elts.foldl (fun e elt => bindCompTargetFresh outer e elt t.elemType) env
  | _ => env

/-- Bind every comprehension target in `json` (`[… for x in xs]`, `for a,b in zip(...)`) from its
iterable's element type, so a call inside the comprehension sees the target typed. Fresh names only:
a target shadowing an outer variable keeps the outer binding (see `bindCompTargetFresh`). -/
partial def compBindings (sigs : Sigs) (env : Env) (json : Json) : Env :=
  let env :=
    if ["ListComp", "SetComp", "DictComp", "GeneratorExp"].contains (nodeTypeOf json |>.getD "") then
      let gens := (json.getObjValAs? (Array Json) "generators").toOption.getD #[]
      gens.foldl (fun e gen =>
        match getField gen "target", getField gen "iter" with
        | some target, some iter => bindCompTargetFresh env e target (typeOfExpr sigs e iter).elemType
        | _, _ => e) env
    else env
  match json with
  | .arr xs => xs.foldl (compBindings sigs) env
  | .obj fs => fs.toList.foldl (fun e (_, v) => compBindings sigs e v) env
  | _ => env

/-- Every statement in a body, flattened through nested blocks but not into nested `def`s. -/
private partial def flatStmts (stmts : List Json) : List Json :=
  stmts.foldl (fun acc s => acc ++ [s] ++ (childBlocks s).flatMap flatStmts) []

/-- The declared parameter names of `fn`, in order. -/
def paramNames (fn : Json) : Array String := Id.run do
  let mut names := #[]
  let .ok args := fn.getObjVal? "args" | return names
  let .ok argsArr := args.getObjValAs? (Array Json) "args" | return names
  for arg in argsArr do
    if let .ok name := arg.getObjValAs? String "arg" then names := names.push name
  return names

/-- A `None` literal (`Constant` whose value is JSON null). -/
private def isNoneConst (j : Json) : Bool :=
  nodeTypeOf j == some "Constant" && (getField j "value" == some Json.null)

/-- A list of all `None` — `[None, None]` or `[None] * k` — the initial value of a recursive node's
child array (a Trie's `children`, a segment tree's kids). -/
private partial def isListOfNone (j : Json) : Bool :=
  match nodeTypeOf j with
  | some "List" =>
      let elts := (j.getObjValAs? (Array Json) "elts").toOption.getD #[]
      !elts.isEmpty && elts.all isNoneConst
  | some "BinOp" =>
      j.getObjValAs? String "op" == .ok "mul"
        && ((getField j "left").any isListOfNone || (getField j "right").any isListOfNone)
  | some "ListComp" => (getField j "elt").any isNoneConst
  | _ => false

/-- Does the body test `name` against `None` (`x is None`, `x == None`, `if not x`)? Such a test
proves the parameter is nullable, so a bare node-class annotation (LeetCode writes `root: TreeNode`
but the base case `if root is None: return` means `Optional[TreeNode]`) should widen to `Optional`. -/
private partial def nameIsNoneTested (name : String) (json : Json) : Bool :=
  -- Do NOT descend into a nested `def` — a same-named param there (`def dfs(root)` inside `def
  -- convertBST(root)`) is a DIFFERENT, shadowing variable, and its `if root is None` must not widen
  -- this scope's param.
  if nodeTypeOf json == some "FunctionDef" then false else
  let here : Bool :=
    match nodeTypeOf json with
    | some "Compare" =>
        (["is", "is_not", "eq", "not_eq"].contains ((json.getObjValAs? String "op").toOption.getD "")) &&
        (((getField json "left").bind nameId? == some name && (getField json "right").any isNoneConst) ||
         ((getField json "right").bind nameId? == some name && (getField json "left").any isNoneConst))
    | some "UnaryOp" =>
        (json.getObjValAs? String "op").toOption == some "not" && (getField json "operand").bind nameId? == some name
    | _ => false
  here || (match json with
    | .arr xs => xs.any (nameIsNoneTested name)
    | .obj fs => fs.toList.any (fun (_, v) => nameIsNoneTested name v)
    | _ => false)

/-- Is `name` ever an assignment / aug-assign / `for` target (a `Name` target) in `json`, not
descending into a nested def? A reassigned nullable node param is a mut-cursor (`node = node.next`,
handled by a `_mut_opt` shadow); one only read + recursed on (`dfs(root.left)`) needs its param TYPE
itself widened to `Optional`. -/
private partial def nameReassigned (name : String) (json : Json) : Bool :=
  if nodeTypeOf json == some "FunctionDef" then false
  else
    let hits (t : Json) : Bool := nameId? t == some name
    let here : Bool := match nodeTypeOf json with
      | some "Assign" =>
          match getField json "targets" with | some (.arr ts) => ts.any hits | _ => false
      | some "AugAssign" | some "AnnAssign" => (getField json "target").any hits
      | some "For" => (getField json "target").any hits
      | _ => false
    here || (match json with
      | .arr xs => xs.any (nameReassigned name)
      | .obj fs => fs.toList.any (fun (_, v) => nameReassigned name v)
      | _ => false)

/-- Parameter name → annotated type for a `FunctionDef` (annotated params only). A bare node-class
param the body tests against `None` is widened to `Optional` (see `nameIsNoneTested`). -/
private def paramSeed (fn : Json) : Env := Id.run do
  let mut env : Env := {}
  let body := Json.arr (fn.getObjValAs? (Array Json) "body" |>.toOption.getD #[])
  let .ok args := fn.getObjVal? "args" | return env
  let .ok argsArr := args.getObjValAs? (Array Json) "args" | return env
  for arg in argsArr do
    if let .ok name := arg.getObjValAs? String "arg" then
      match getField arg "annotation" with
      | some ann => if !ann.isNull then
          let t := match ofAnnotation ann with
            | .cls c => if nameIsNoneTested name body then .opt (.cls c) else .cls c
            | other => other
          env := env.insert name t
      | none => pure ()
  return env

/-- What `name`'s usage in one expression unambiguously tells us — enumerated exhaustively over the
Python signals that pin exactly one type: a type-exclusive method on it (`p.split()` → str), an
int-only operator over it (`p << 1`, `p >> 1`, `~p` — bitwise `& | ^` are int OR set, so NOT here),
or a type-fixing builtin arg (`ord(p)` → str, `chr(p)` → int). Genuinely ambiguous uses (`p[i]`,
`for x in p`, `len(p)`, `p + q`) stay `unknown` — the fixpoint fills them in. -/
private partial def usageType (name : String) (json : Json) : PyType :=
  let isName (j : Option Json) : Bool := j.bind nameId? == some name
  let here : PyType :=
    match nodeTypeOf json with
    | some "Call" =>
        match getField json "func" with
        -- `p.method(...)`: a type-exclusive method pins `p`.
        | some func =>
            if nodeTypeOf func == some "Attribute" then
              if isName (getField func "value") then
                (func.getObjValAs? String "attr").toOption.elim .unknown Libraries.builtinMethodReceiver?
              else .unknown
            -- `ord(p)` → p is a one-char str; `chr(p)` → p is an int.
            else match nameId? func with
              | some fn =>
                  let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
                  -- `p(...)` — the param is CALLED, so it is a function of this arity (a higher-order
                  -- callback); the arg/return types are refined from the call site interprocedurally.
                  if fn == name then .fn (List.replicate args.size .unknown) .unknown
                  else if args.any (fun a => nameId? a == some name) then
                    if fn == "ord" then .str else if fn == "chr" then .int else .unknown
                  else .unknown
              | none => .unknown
        | none => .unknown
    -- Shift is int-only in Python (`p << 1`); `& | ^` also work on sets, so they pin nothing.
    | some "BinOp" =>
        match (json.getObjValAs? String "op").toOption with
        | some op =>
            if ["lshift", "rshift"].contains op
               && (isName (getField json "left") || isName (getField json "right")) then .int
            else .unknown
        | none => .unknown
    -- `~p` (bitwise NOT) is int-only.
    | some "UnaryOp" =>
        if (json.getObjValAs? String "op").toOption == some "invert" && isName (getField json "operand")
        then .int else .unknown
    | _ => .unknown
  let sub := match json with
    | .arr xs => PyType.joinAll (xs.toList.map (usageType name))
    | .obj fs => PyType.joinAll (fs.toList.map (fun (_, v) => usageType name v))
    | _ => .unknown
  here.join sub

/-- Seed each unannotated parameter from unambiguous body usage (`p.split()` → str, `p.append()` →
list, `p.keys()` → dict). This is the safe part of the use-based inference the old Python pre-pass
did. -/
private def paramUsageSeed (fn : Json) : Env := Id.run do
  let body := fn.getObjValAs? (Array Json) "body" |>.toOption.getD #[]
  let mut env : Env := {}
  for name in paramNames fn do
    let t := usageType name (Json.arr body)
    if t != .unknown then env := env.insert name t
  return env

/-- Names `fn` binds directly — params plus `=`/`for`/annotated targets in its own body (through
`if`/`for` blocks, not into deeper nested defs). A name used in `fn` but NOT here is a capture of an
enclosing scope. -/
private def localAssignNames (fn : Json) : List String := Id.run do
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
private def mutationReceiverName? (value : Json) : Option String :=
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

/-- Apply container-teaching mutations found INSIDE nested defs to the enclosing `env`, so a capture
learns its element type across scopes (`nums = []` here, `nums.append(x)` in a sibling `def dfs`, then
`nums[i]` in `def build` — all one `List Int`). A name a nested def binds itself (param or `=`) is a
shadow, not a capture, so it is skipped; only names already in `env` are refined (join-only, never a
downgrade). The enclosing scope's own mutations are already handled by `applyStmt`, so refinement only
fires `insideDef`. -/
private partial def applyCaptureMutations (sigs : Sigs) (shadowed : List String) (insideDef : Bool)
    (env : Env) (json : Json) : Env := Id.run do
  let entering := nodeTypeOf json == some "FunctionDef"
  let shadowed := if entering then shadowed ++ localAssignNames json else shadowed
  let inside := insideDef || entering
  let mut env := env
  if inside then
    if let some cname := mutationReceiverName? json then
      if !shadowed.contains cname && (env.get? cname).isSome then
        env := applyMutation sigs env json
  match json with
  | .arr xs => return xs.foldl (applyCaptureMutations sigs shadowed inside) env
  | .obj fs => return fs.toList.foldl (fun e (_, v) => applyCaptureMutations sigs shadowed inside e v) env
  | _ => return env

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
  let mut env := paramUsageSeed fn
  env := outer.fold (fun m k v => m.insert k v) env
  env := hints.fold (fun m k v => m.insert k v) env
  env := (paramSeed fn).fold (fun m k v => m.insert k v) env
  let bodyJson := Json.arr body
  -- Reflow until stable. The lattice climbs, so a small cap is a sound floor, not a correctness risk.
  for _ in [0:8] do
    -- `compBindings` types comprehension targets so a call inside a comprehension can hint the callee
    -- (`[f(point) for point in data]`). It binds only FRESH names — a comprehension target that
    -- shadows an outer variable owns a separate scope (Python-3), so clobbering the outer type (a
    -- loop `v : int` vs a comprehension `v : list[int]` → `any`) would poison it. Fresh-only respects
    -- that: never downgrade an outer binding.
    let stepped := applyCaptureMutations sigs [] false (stmts.foldl (applyStmt sigs) env) bodyJson
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

/-! ### Writing the inferred types back onto the IR as `_ty` -/

/-- A `defaultdict[k, v]` annotation node, for a dict whose runtime backing is `PyDefaultDict`. -/
private def defaultDictAnnotation? (k v : PyType) : Option Json := do
  let kj ← toAnnotation? k
  let vj ← toAnnotation? v
  return Json.mkObj [("node_type", .str "Subscript"),
    ("value", Json.mkObj [("node_type", .str "Name"), ("id", .str "defaultdict")]),
    ("slice", Json.mkObj [("node_type", .str "Tuple"), ("elts", Json.arr #[kj, vj])])]

/-- Stamp `_ty` (an annotation node) on a target if we know a fully-determined type for it, unless a
`_ty` is already present (the interprocedural pass stamps first; a later intraprocedural pass must
not clobber its richer result). Tuple targets stamp each element. -/
partial def stampTarget (env : Env) (target : Json) (allowDict : Bool := true) : Json :=
  match nodeTypeOf target with
  | some "Name" =>
      if (getField target "_ty").isSome then target
      else
        -- Only ascribe a local when Lean cannot infer it from the assignment's RHS on its own — i.e.
        -- an empty/none-shaped container (`xs = []`, `d = {}`) whose element type is otherwise stuck.
        -- For a determined RHS (a numpy/division result, a literal), ascribing would *force* a type
        -- (e.g. `ℚ`) that fights what the RHS actually elaborates to (e.g. `Float`); leave it to Lean.
        match (nameId? target).filter (· != "_") |>.bind (env.get? ·) with
        -- A variable that is two incompatible types across paths (`y = 10/x` then `y = 0`) is boxed
        -- as `PyAny`, so the reassignments coerce instead of clashing.
        | some .any =>
            target.setObjVal! "_ty" (Json.mkObj [("node_type", .str "Name"), ("id", .str "PyAny")])
        | some t =>
            -- A dict from a `defaultdict`/`Counter` call is backed by `PyDefaultDict`, not the
            -- `Std.HashMap` a plain `dict[_, _]` annotation emits, so it is stamped as
            -- `defaultdict[k, v]` — which the codegen annotation reader maps to the library type.
            let ann? := match t, allowDict with
              | .dict k v, false => defaultDictAnnotation? k v
              | _, _ => toAnnotation? t
            if t.needsAscription then
              match ann? with
              | some ann => target.setObjVal! "_ty" ann
              | none => target
            else target
        | none => target
  | some "Tuple" | some "List" =>
      match target.getObjValAs? (Array Json) "elts" with
      | .ok elts => target.setObjVal! "elts" (Json.arr (elts.map (stampTarget env · allowDict)))
      | _ => target
  | _ => target

/-- Does parameter `name` appear in a position that `PyAny` can serve but an un-inferred type
leaves Lean's instance search stuck on? Containers — `x[i]`, `x[i]=v`, `for _ in x`, `len(x)` — and
truthy contexts — `x and y`, `not x`, `if x`, `while x` (all `PyTruthy`). Boxing such a param as
`PyAny` (which delegates to the runtime tag) turns a compile error into a total, running program.
Does not descend into nested defs (separate scope). -/
partial def usedInPyAnyPosition (name : String) (json : Json) : Bool :=
  if nodeTypeOf json == some "FunctionDef" then false
  else
    let isName (field : String) : Bool := (getField json field).bind nameId? == some name
    let hitHere : Bool := match nodeTypeOf json with
      | some "Subscript" => isName "value"
      | some "For" => isName "iter"
      | some "If" | some "While" => isName "test"
      | some "UnaryOp" => (json.getObjValAs? String "op").toOption == some "not" && isName "operand"
      | some "BoolOp" =>
          ((json.getObjValAs? (Array Json) "values").toOption.getD #[]).any (fun v => nameId? v == some name)
      | some "Call" =>
          (getField json "func").bind nameId? == some "len" &&
            ((json.getObjValAs? (Array Json) "args").toOption.getD #[]).any (fun a => nameId? a == some name)
      -- `x is None` / `x is not None` on an otherwise-unknown `x`: box it so `pyIsNone x` resolves
      -- (`PyIsNone PyAny`) instead of leaving `x` an untyped binder that forces `Option _`.
      | some "Compare" =>
          let op := (json.getObjValAs? String "op").toOption
          let isNoneJson : Option Json → Bool := fun
            | some j => nodeTypeOf j == some "Constant" && (j.getObjVal? "value").toOption == some Json.null
            | none => false
          (op == some "is" || op == some "isnot") &&
            ((isName "left" && isNoneJson (getField json "right")) ||
             (isName "right" && isNoneJson (getField json "left")))
      | _ => false
    hitHere || (match json with
      | .arr xs => xs.any (usedInPyAnyPosition name)
      | .obj fs => fs.toList.any (fun (_, v) => usedInPyAnyPosition name v)
      | _ => false)

/-- Add `_ty` to each unannotated parameter we could type (a nested capture, or a rare
un-hinted param). An explicit annotation, or an existing `_ty`, always wins. -/
private def stampParams (env : Env) (fn : Json) : Json :=
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let pyAnyTy := Json.mkObj [("node_type", .str "Name"), ("id", .str "PyAny")]
  match fn.getObjVal? "args" with
  | .ok args =>
      match args.getObjValAs? (Array Json) "args" with
      | .ok argsArr =>
          let argsArr := argsArr.map fun arg =>
            match arg.getObjValAs? String "arg" with
            | .ok name =>
                let annotated := match getField arg "annotation" with
                  | some a => !a.isNull
                  | none => false
                if annotated || (getField arg "_ty").isSome then
                  -- A node param annotated `ListNode`/`TreeNode` (non-optional) that the body reassigns
                  -- from a `.next`/`.left` (Option) — so `env` widened it to `.opt (.cls c)` — is really
                  -- nullable. Mark `_mut_opt` so codegen seeds its mut shadow as `Option c` (`some p`),
                  -- letting `while node`, `node.field` (Option-unwrap), and `node = node.next` line up
                  -- WITHOUT changing the param's type (callers still pass a plain `c`).
                  match env.get? name, getField arg "annotation" with
                  | some (.opt (.cls c)), some ann =>
                      if ofAnnotation ann == .cls c then
                        -- Reassigned (`node = node.next`): keep the param type `c`, shadow it as
                        -- `Option c` via `_mut_opt` (callers pass a plain `c`). Only read + recursed
                        -- on (`dfs(root.left)`): widen the PARAM TYPE to `Optional c` so an Option arg
                        -- lines up, via a `_ty` override of the bare annotation.
                        if nameReassigned name (Json.arr body) then arg.setObjVal! "_mut_opt" (Json.str c)
                        else match toAnnotation? (PyType.opt (.cls c)) with
                          | some optAnn => arg.setObjVal! "_ty" optAnn
                          | none => arg.setObjVal! "_mut_opt" (Json.str c)
                      else arg
                  | _, _ => arg
                else
                  -- A residual-unknown param is boxed as `PyAny` only when it is used in a
                  -- container-dispatch position (else it would compile-error); otherwise it is left
                  -- bare for Lean's own body unification, which keeps it provable.
                  let boxIfStuck := fun () =>
                    if body.any (usedInPyAnyPosition name) then arg.setObjVal! "_ty" pyAnyTy else arg
                  match env.get? name with
                  -- A parameter used at genuinely different types (`.any`, e.g. `add(a,b)` called
                  -- with ints and strings) is always boxed so one definition dispatches on the tag.
                  | some (.any) => arg.setObjVal! "_ty" pyAnyTy
                  | some t =>
                      if t.isKnown then
                        match toAnnotation? t with
                        | some ann => arg.setObjVal! "_ty" ann
                        | none => arg
                      else boxIfStuck ()
                  | none => boxIfStuck ()
            | _ => arg
          fn.setObjVal! "args" (args.setObjVal! "args" (Json.arr argsArr))
      | _ => fn
  | _ => fn

/-- Mark every `t[k]` where `t` is a tuple-typed name (`tuple[a, b, …]`) with its arity
(`_PastaLean_tuple_arity`), so the subscript codegen static-projects the exact slot instead of
`pyGetItem` (which has no instance for a heterogeneous product). Does not descend into a nested `def`
(separate scope, its own env). -/
partial def markTuples (env : Env) (json : Json) : Json :=
  if nodeTypeOf json == some "FunctionDef" then json
  else
    let json :=
      if nodeTypeOf json == some "Subscript" then
        match getField json "value" with
        | some v =>
            match (nameId? v).bind (env.get? ·) with
            | some (.tuple es) =>
                json.setObjVal! "value"
                  (v.setObjVal! "_PastaLean_tuple_arity" (Json.num (JsonNumber.mk (Int.ofNat es.length) 0)))
            | some (.dict _ _) =>
                -- `d[i, j]` on a dict is a single tuple-KEY access (`d[(i, j)]`), NOT numpy-style
                -- multi-index (`d[i][j]`). Mark the slice so codegen forms the tuple key.
                match getField json "slice" with
                | some s =>
                    if nodeTypeOf s == some "Tuple" then
                      json.setObjVal! "slice" (s.setObjVal! "_dict_tuple_key" (Json.bool true))
                    else json
                | none => json
            | _ => json
        | none => json
      else json
    match json with
    | .arr xs => Json.arr (xs.map (markTuples env))
    | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, markTuples env v)))
    | _ => json

/-- Mark every `x.attr` whose receiver `x` is `Option`-typed with
`_unwrap_opt`, so the field codegen emits `(x.getD default).attr` instead of the invalid
`Option.attr` projection. Covers the tree/linked-list traversal case (`root.val`, `root.left`).
Skips nested defs (own scope). -/
partial def markOptAttrs (sigs : Sigs) (env : Env) (json : Json) : Json :=
  if nodeTypeOf json == some "FunctionDef" then json
  else
    let json :=
      if nodeTypeOf json == some "Attribute" then
        match (getField json "value").map (typeOfExpr sigs env) with
        | some (.opt _) => json.setObjVal! "_unwrap_opt" (Json.bool true)
        | _ => json
      -- `root1 == root2` / `root1 is root2` between two user-class (node) values: mark `_class_cmp`
      -- so codegen compares through `BEq` (`==`) even in the exact twin — nodes have no `DecidableEq`
      -- for a propositional `=`.
      else if nodeTypeOf json == some "Compare" then
        let isClassish := fun (side : String) => match (getField json side).map (typeOfExpr sigs env) with
          | some (.cls _) | some (.opt (.cls _)) => true
          | _ => false
        if isClassish "left" || isClassish "right" then json.setObjVal! "_class_cmp" (Json.bool true) else json
      else json
    match json with
    | .arr xs => Json.arr (xs.map (markOptAttrs sigs env))
    | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, markOptAttrs sigs env v)))
    | _ => json

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

/-- Stamp an int-literal `Constant` with `_ty = float` (so codegen emits `(0 : ℚ)`). -/
private def stampIfIntConst (e : Json) : Json :=
  if nodeTypeOf e == some "Constant" && (getField e "_ty").isNone
     && e.getObjValAs? String "python_literal_kind" != .ok "float"
     && (match (e.getObjVal? "value").toOption with | some (.num ⟨_, 0⟩) => true | _ => false) then
    match toAnnotation? .float with | some ann => e.setObjVal! "_ty" ann | none => e
  else e

/-- A container whose innermost element is `float` (`list[float]`, `list[list[list[float]]]`, …). -/
private partial def deepFloatContainer : PyType → Bool
  | .list .float | .set .float => true
  | .list e | .set e => deepFloatContainer e
  | _ => false

/-- A list/set literal or a `[x] * n` repeat — a value whose element type an ascription can fix.
Also a comprehension whose ELEMENT is itself such a container (`[[inf]*m for …]`), so the outer
float container is ascribed and the polymorphic `inf` seed pins to the mode float. A comprehension
of scalars (`[pow(a-b, 2) for …]`) is deliberately NOT matched: ascribing it would force the int
subexpressions inside each element to ℚ (`PyHSub ℤ ℤ ℚ`). -/
private partial def isListLitOrRepeat (v : Json) : Bool :=
  match nodeTypeOf v with
  | some "List" | some "Set" => true
  | some "BinOp" => (v.getObjValAs? String "op").toOption == some "mul"
      && ((getField v "left").any (fun l => nodeTypeOf l == some "List")
          || (getField v "right").any (fun r => nodeTypeOf r == some "List"))
  | some "ListComp" | some "GeneratorExp" | some "SetComp" =>
      (getField v "elt").any isListLitOrRepeat
  | _ => false

/-- For a float-typed container assigned `value`, coerce its int-literal ELEMENTS to float. Descends
list/set literals, the `[x] * n` repeat, and comprehensions — so a nested `[[[0]*n for _] for _]`
DP grid (`list[list[list[float]]]`) coerces its innermost `0` to `(0 : ℚ)`. -/
private partial def stampFloatListElems (value : Json) : Json :=
  match nodeTypeOf value with
  | some "Constant" => stampIfIntConst value
  | some "List" | some "Set" =>
      match value.getObjValAs? (Array Json) "elts" with
      | .ok elts => value.setObjVal! "elts" (Json.arr (elts.map stampFloatListElems))
      | _ => value
  | some "BinOp" =>
      -- `[x] * n` (or `n * [x]`): descend ONLY into the list operand, never the count `n` (whose
      -- constants — e.g. the `1` in `n + 1` — must stay `Int`).
      let descendIfList (side : String) (v : Json) : Json :=
        (getField v side).elim v fun o =>
          if nodeTypeOf o == some "List" then v.setObjVal! side (stampFloatListElems o) else v
      descendIfList "right" (descendIfList "left" value)
  | some "ListComp" | some "SetComp" | some "GeneratorExp" =>
      (getField value "elt").elim value (fun e => value.setObjVal! "elt" (stampFloatListElems e))
  | some "DictComp" =>
      (getField value "value").elim value (fun e => value.setObjVal! "value" (stampFloatListElems e))
  | _ => value

/-! ### Array-backing eligibility (runnable twin)

A `list` local whose every use is `Array`-portable is stamped `_seq: "array"` so codegen backs it
with `Array` (O(1) append/index) in the runnable twin; everything else stays `List`. -/

/-- Does `v` occur as a `Name` anywhere in `j`? (for the for-target rebind guard). -/
partial def refsListName (v : String) (j : Json) : Bool :=
  nameId? j == some v ||
    (match j with
     | .arr xs => xs.any (refsListName v)
     | .obj fs => fs.toList.any (fun (_, x) => refsListName v x)
     | _ => false)

/-- Does the assignment target `t` have root name `v` (`v = …`, `v[i] = …`, `v.f = …`, or a tuple
unpack binding `v`)? -/
private partial def targetRootIs (v : String) (t : Json) : Bool :=
  match nodeTypeOf t with
  | some "Name" => nameId? t == some v
  | some "Subscript" | some "Attribute" => (getField t "value").any (targetRootIs v)
  | some "Tuple" | some "List" => ((t.getObjValAs? (Array Json) "elts").toOption.getD #[]).any (targetRootIs v)
  | _ => false

/-- Is `v` MUTATED anywhere in `json` — reassigned/`v[i]=`/`v.f=`, or the receiver of a mutating method
(`append`/`pop`/…)? Used to keep a captured-and-mutated list off `Array` backing: such a var is
THREADED through nested defs as a `List`, so an `Array` binder would clash. -/
private partial def mutatesNameWithin (v : String) (json : Json) : Bool :=
  let here : Bool := match nodeTypeOf json with
    | some "Assign" | some "AugAssign" | some "AnnAssign" =>
        (getField json "target").any (targetRootIs v)
    | some "Call" =>
        (getField json "func").any fun f =>
          nodeTypeOf f == some "Attribute"
            && ((getField f "value").bind nameId? == some v)
            && ["append", "extend", "pop", "insert", "remove", "sort", "reverse", "appendleft",
                "popleft", "add", "clear", "discard", "update"].contains
                  ((f.getObjValAs? String "attr").toOption.getD "")
    | _ => false
  here || (match json with
    | .arr xs => xs.any (mutatesNameWithin v)
    | .obj fs => fs.toList.any (fun (_, x) => mutatesNameWithin v x)
    | _ => false)

/-- A use of list variable `v` that `Array`-backing supports with the identical generated surface:
integer-index `v[i]` (read/write), `len(v)`, `for _ in v`, `(re)binding v`, and — only when
`allowAppend` — a bare `v.append(x)`. Returns `false` on ANY other use — a slice `v[a:b]`, another
method (`v.sort()`/`v.pop()`), a nested `v[i].append(...)`, passing `v` to a function, returning it,
storing it — so an ineligible value safely stays `List`. `allowAppend` is off for NESTED lists: the
appended row's own backing can't be guaranteed to match, so a nested list is only eligible when it is
a full literal accessed by index (no append). Conservative: an unrecognised context recurses into
every child and a bare `Name v` reached there fails. Skips nested defs/lambdas (separate scope). -/
partial def listUsePorted (v : String) (allowAppend : Bool) (json : Json) : Bool :=
  match nodeTypeOf json with
  | some "Name" => nameId? json != some v
  -- A nested def that only READS `v` keeps it portable (the capture is forwarded at its own type);
  -- one that MUTATES `v` threads it as a `List`, so `v` must not be `Array`-backed.
  | some "FunctionDef" | some "ClassDef" | some "Lambda" => !(mutatesNameWithin v json)
  | some "Subscript" =>
      let val := (getField json "value").getD Json.null
      let slice := (getField json "slice").getD Json.null
      if nameId? val == some v then
        if nodeTypeOf slice == some "Slice" then false else listUsePorted v allowAppend slice
      else listUsePorted v allowAppend val && listUsePorted v allowAppend slice
  | some "Call" =>
      let func := (getField json "func").getD Json.null
      let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
      let kws := (json.getObjValAs? (Array Json) "keywords").toOption.getD #[]
      -- an `.append(...)` whose receiver mentions v (covers `v.append` and `v[i].append`)
      let appendRecvV := nodeTypeOf func == some "Attribute"
        && (func.getObjValAs? String "attr" == .ok "append")
        && ((getField func "value").any (refsListName v))
      let isLen := nameId? func == some "len"
      if appendRecvV then
        -- only a bare `v.append(x)` on an append-allowed (flat scalar) list is ported
        if allowAppend && ((getField func "value").any (fun r => nameId? r == some v)) then
          args.all (listUsePorted v allowAppend) && kws.all (listUsePorted v allowAppend)
        else false
      else if isLen then
        args.all (fun a => nameId? a == some v || listUsePorted v allowAppend a)
          && kws.all (listUsePorted v allowAppend)
      else listUsePorted v allowAppend func && args.all (listUsePorted v allowAppend)
        && kws.all (listUsePorted v allowAppend)
  | some "For" =>
      let target := (getField json "target").getD Json.null
      let iter := (getField json "iter").getD Json.null
      let body := (json.getObjValAs? (Array Json) "body").toOption.getD #[]
      let orelse := (json.getObjValAs? (Array Json) "orelse").toOption.getD #[]
      if refsListName v target then false
      else (nameId? iter == some v || listUsePorted v allowAppend iter)
        && body.all (listUsePorted v allowAppend) && orelse.all (listUsePorted v allowAppend)
  | some "Assign" | some "AnnAssign" | some "AugAssign" =>
      let value := (getField json "value").getD Json.null
      let tgt := (getField json "target").getD Json.null
      let tgtOk :=
        match nodeTypeOf tgt with
        | some "Name" => true
        | some "Subscript" =>
            let tv := (getField tgt "value").getD Json.null
            let ts := (getField tgt "slice").getD Json.null
            if nameId? tv == some v then (nodeTypeOf ts != some "Slice") && listUsePorted v allowAppend ts
            else listUsePorted v allowAppend tv && listUsePorted v allowAppend ts
        | _ => listUsePorted v allowAppend tgt
      tgtOk && listUsePorted v allowAppend value
  | _ =>
      match json with
      | .arr xs => xs.all (listUsePorted v allowAppend)
      | .obj fs => fs.toList.all (fun (_, x) => listUsePorted v allowAppend x)
      | _ => true

-- A flat list of scalars: `list[int]` / `list[float]` / `list[str]` / `list[bool]`. Append is safe
-- (scalar elements are always consistently backed), so these are eligible even when built by append.
private def isFlatScalarList : PyType → Bool
  | .list .int | .list .bool | .list .float | .list .str => true
  | _ => false

-- A NESTED list of scalars: `list[list[int]]`, `list[list[list[float]]]`, … . Backed `Array (Array
-- …)` but only when a full literal accessed by index (no append — see `listUsePorted`).
private partial def isNestedScalarList : PyType → Bool
  | .list (.list e) => isNestedScalarList (.list e) || isFlatScalarList (.list e)
  | _ => false

/-- The init value matches `ty`'s list nesting: every list LEVEL is a literal (markable as `Array`),
scalar leaves may be any expression. With `full`, each list level must be NON-EMPTY (a nested list is
only eligible fully-populated — an empty `[]` that is later appended to can't be safely backed). -/
private partial def litMatchesNesting (full : Bool) (ty : PyType) (v : Json) : Bool :=
  match ty with
  | .list inner =>
      nodeTypeOf v == some "List"
        && (let elts := (v.getObjValAs? (Array Json) "elts").toOption.getD #[]
            (!full || !elts.isEmpty) && elts.all (litMatchesNesting full inner))
  | _ => true

/-- Every bare-`Name` assignment to `name` is a nesting-matching `List` literal (and there is at
least one) — so the variable is only initialised from literals, never aliased to another list. -/
private def initsAreLits (stmts : List Json) (name : String) (ty : PyType) (full : Bool) : Bool := Id.run do
  let mut sawOne := false
  for s in stmts do
    if nodeTypeOf s == some "Assign" || nodeTypeOf s == some "AnnAssign" then
      if let some tgt := getField s "target" then
        if nameId? tgt == some name then
          sawOne := true
          if !litMatchesNesting full ty ((getField s "value").getD Json.null) then return false
  return sawOne

/-- Local list variables codegen may back with `Array` in the runnable twin: a FLAT scalar list whose
uses are ported (append allowed), or a NESTED scalar list that is a full literal accessed by index
(no append). Everything else stays `List`. -/
def arrayEligibleVars (env : Env) (fn : Json) : Std.HashSet String := Id.run do
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let stmts := flatStmts body.toList
  let params := paramNames fn
  let mut result : Std.HashSet String := {}
  for (name, ty) in env.toList do
    if params.contains name then
      pure ()
    else if isFlatScalarList ty then
      if initsAreLits stmts name ty false && body.all (listUsePorted name true) then
        result := result.insert name
    else if isNestedScalarList ty then
      if initsAreLits stmts name ty true && body.all (listUsePorted name false) then
        result := result.insert name
  return result

/-- Mark `_seq: "array"` on EVERY `list[...]` level of a type annotation (so `list[list[int]]` →
`Array (Array Int)`, not `Array (List Int)`). -/
private partial def markSeqAnn (ann : Json) : Json :=
  if ann.getObjValAs? String "node_type" == .ok "Subscript"
     && ((ann.getObjVal? "value").toOption.any (·.getObjValAs? String "id" |>.toOption |>.any (· == "list"))) then
    let ann := ann.setObjVal! "_seq" (Json.str "array")
    match ann.getObjVal? "slice" with
    | .ok inner => ann.setObjVal! "slice" (markSeqAnn inner)
    | _ => ann
  else ann

/-- Mark `_seq: "array"` on a nested `List` literal at every level (`[[..],[..]]` → `#[#[..],#[..]]`). -/
private partial def markSeqLit (v : Json) : Json :=
  if nodeTypeOf v == some "List" then
    let v := v.setObjVal! "_seq" (Json.str "array")
    match v.getObjValAs? (Array Json) "elts" with
    | .ok elts => v.setObjVal! "elts" (Json.arr (elts.map markSeqLit))
    | _ => v
  else v

/-- A var assigned inside an `if`/`for`/`while`/`try` block is hoisted to a `let mut x : T := default`
at the function top, with `T` from a `<block>_assigned_types` map (stamped from `env`, so no `_seq`).
Mark the `array_ok` names there too, else the hoisted `List` type clashes with the `Array` literal. -/
private def markHoistTypeMaps (eligible : Std.HashSet String) (json : Json) : Json := Id.run do
  let mut j := json
  for key in #["if_assigned_types", "try_assigned_types", "for_assigned_types", "while_assigned_types"] do
    if let some tmap := getField j key then
      let mut newMap := tmap
      for nm in eligible.toList do
        if let some ann := (tmap.getObjVal? nm).toOption then
          newMap := newMap.setObjVal! nm (markSeqAnn ann)
      j := j.setObjVal! key newMap
  return j

/-- Stamp `_seq: "array"` on a `v.append(x)` / `v.extend(x)` call whose receiver `v` is `array_ok`, so
codegen emits the O(1) `pyArrayAppend`/`pyArrayExtend` instead of the `List` `pyAppend`/`pyExtend`. -/
private def markAppendCall (eligible : Std.HashSet String) (json : Json) : Json :=
  match getField json "func" with
  | some func =>
      let attr := (func.getObjValAs? String "attr").toOption
      if nodeTypeOf func == some "Attribute" && (attr == some "append" || attr == some "extend")
         && ((getField func "value").any (fun r => (nameId? r).any eligible.contains)) then
        json.setObjVal! "_seq" (Json.str "array")
      else json
  | none => json

/-- Stamp `_seq: "array"` on an `array_ok` local's declaring binder type (`_ty`), its nested list
literals at every level, and its hoisted-type-map entries; codegen then emits `Array`/`#[…]` in the
runnable twin. Only the declaration needs it — append/index/len/iter dispatch by the resulting type.
Does not descend into nested defs. -/
partial def stampArraySeqs (eligible : Std.HashSet String) (json : Json) : Json :=
  if nodeTypeOf json == some "FunctionDef" || nodeTypeOf json == some "ClassDef" then json
  else
    let json := markHoistTypeMaps eligible json
    let json := if nodeTypeOf json == some "Call" then markAppendCall eligible json else json
    let recurse : Json :=
      match json with
      | .arr xs => Json.arr (xs.map (stampArraySeqs eligible))
      | .obj fs => Json.mkObj (fs.toList.map (fun (k, x) => (k, stampArraySeqs eligible x)))
      | _ => json
    if nodeTypeOf json == some "Assign" || nodeTypeOf json == some "AnnAssign" then
      let tgt := (getField json "target").getD Json.null
      if (nameId? tgt).any eligible.contains then
        let json := match getField tgt "_ty" with
          | some ty => json.setObjVal! "target" (tgt.setObjVal! "_ty" (markSeqAnn ty))
          | none => json
        match getField json "value" with
        | some v =>
            -- mark the literal (`#[…]`) AND the value's own `_ty` ascription (`(… : Array …)`), which
            -- codegen adds from `stampedTypeSyntax? value` for numeric-container element pinning.
            let v := markSeqLit v
            let v := match getField v "_ty" with
              | some ty => v.setObjVal! "_ty" (markSeqAnn ty)
              | none => v
            json.setObjVal! "value" v
        | none => json
      else recurse
    else recurse


mutual

/-- The types of a value's *branch leaves*, descending through `IfExp`/`BoolOp` (whose result is one
of its operands). `return -1 if v >= inf else v` yields `[int, float]`, so a single mixed ternary
return is seen as mixing `int` and `float` — the same reconciliation a `return 0` / `return ans`
pair gets — not just its `float` join. -/
partial def returnBranchTypes (sigs : Sigs) (env : Env) (v : Json) : List PyType :=
  match nodeTypeOf v with
  | some "IfExp" =>
      (getField v "body").elim [] (returnBranchTypes sigs env)
        ++ (getField v "orelse").elim [] (returnBranchTypes sigs env)
  | some "BoolOp" =>
      ((v.getObjValAs? (Array Json) "values").toOption.getD #[]).toList.flatMap (returnBranchTypes sigs env)
  | _ => [typeOfExpr sigs env v]

/-- Infer types for `fn` (seeded by `outer` captures and `hints` for unannotated params, resolving
calls with `sigs`), stamp its params and every binder in its body, and recurse into nested defs.
A function whose returns disagree (`.any`) and that has no return annotation is marked `_box_return`
so codegen boxes its result as `PyAny`. -/
partial def stampFunction (sigs : Sigs) (outer hints : Env) (fn : Json) : Json :=
  let env1 := inferFunction sigs outer hints fn
  -- Second pass: a param that pass 1 leaves `unknown` but that is used in a `PyAny`-dispatch position
  -- WILL be boxed to `PyAny` by codegen. Seed those as `.any` and re-infer, so `PyAny` propagates
  -- through the body (`for x in nums: total += x*2` → `total : PyAny`) and matches what codegen emits;
  -- otherwise `total` stays `Int` and the `total := <PyAny>` reassignment fails to type-check.
  let body := (fn.getObjValAs? (Array Json) "body").toOption.getD #[]
  let pyAnySeed : Env := (paramNames fn).foldl (fun m name =>
    if (env1.get? name).getD .unknown == .unknown && body.any (usedInPyAnyPosition name)
    then m.insert name .any else m) hints
  let env := if pyAnySeed.size == hints.size then env1 else inferFunction sigs outer pyAnySeed fn
  let fn := stampParams env fn
  let fn := match fn.getObjValAs? String "name" with
    | .ok name =>
        -- The return type from its annotation if it has one (a union like `int | str` reads as
        -- `.any`), else the inferred one. `.any` means the returns genuinely disagree → box; a fully
        -- known type is stamped as `_ret_ty` so codegen can ascribe it (a recursive or effectful def
        -- needs its return type in the signature — this is what annotate_python's `-> T` provided).
        let annotated := match getField fn "returns" with | some r => !r.isNull | none => false
        let retType := if annotated then ofAnnotation ((getField fn "returns").getD Json.null)
                       else (sigs.get? name).getD .unknown
        -- Flag a body that mixes `int` and `float` return statements (types read under the
        -- *global-seeded* `env` — `sigs`/`returnTypeOf` run globals-free and miss a global `inf`).
        -- ONLY a mix needs it: the first `return <int>` would pin the `Id.run` codomain to `ℤ`, then a
        -- later `return <float>` fails; codegen ascribes the codomain to `ℚ`/`Float` (gated on
        -- `!_real_fn`) so both coerce. A pure-`float` body needs no ascription (Lean infers it).
        -- `sawOther` covers `int`/`bool` and `unknown` (a `return t` whose `t` TypeInfer left unknown
        -- but Lean will infer `ℤ`) — anything that could pin the codomain to `ℤ` ahead of the float.
        let (sawOther, sawFloat) : Bool × Bool := Id.run do
          let mut so := false; let mut sf := false
          for st in flatStmts ((fn.getObjValAs? (Array Json) "body").toOption.getD #[]).toList do
            if nodeTypeOf st == some "Return" then
              match getField st "value" with
              | some v =>
                  unless v.isNull do
                    for t in returnBranchTypes sigs env v do
                      match t with
                      | .float => sf := true
                      | .int | .bool | .unknown => so := true
                      | _ => pure ()
              | none => pure ()
          return (so, sf)
        let fn := if sawOther && sawFloat then fn.setObjVal! "_ret_float" (Json.bool true) else fn
        if retType == (.any : PyType) then fn.setObjVal! "_box_return" (Json.bool true)
        else if !annotated && retType.isKnown then
          match toAnnotation? retType with
          | some ann => fn.setObjVal! "_ret_ty" ann
          | none => fn
        else fn
    | _ => fn
  let eligible := arrayEligibleVars env fn
  match fn.getObjValAs? (Array Json) "body" with
  | .ok body => fn.setObjVal! "body"
      (Json.arr ((((((body.map (stampStmt sigs env body)).map (markTuples env)).map (markOptAttrs sigs env)).map
        (stampArraySeqs eligible)).map (stampCompTargets sigs env)).map (stampKeyLambdas sigs env)))
  | _ => fn

/-- Stamp a (possibly nested) tuple-unpack target with the list-vs-`Prod` access mode at EVERY level,
driven by the type `ty` of the value it unpacks. `for k, (l, r) in enumerate(queries)` unpacks a
`(int, list[int])`: the outer level is a `Prod` but the inner `(l, r)` unpacks a `list[int]`, so it
must be indexed, not projected. A flat marker on the outer target alone misses the inner level. -/
partial def stampUnpackShape (target : Json) (ty : PyType) : Json :=
  if nodeTypeOf target == some "Tuple" then
    match target.getObjValAs? (Array Json) "elts" with
    | .ok elts => Id.run do
        let childTy : Nat → PyType := fun i => match ty with
          | .list e => e
          | .tuple ts => ts.getD i .unknown
          | _ => .unknown
        let mut newElts := #[]
        for i in [0:elts.size] do
          newElts := newElts.push (stampUnpackShape elts[i]! (childTy i))
        let t := target.setObjVal! "elts" (Json.arr newElts)
        -- Stamp the whole element's type so a comprehension's lambda param `_pair` is ascribed —
        -- otherwise Lean infers it from the body (`c*ₚv` → `ℤ×ℤ`) and clashes with the real element.
        let t := match toAnnotation? ty with | some ann => t.setObjVal! "_pair_ty" ann | none => t
        match ty with
        | .list _ => return t.setObjVal! "_list_unpack" (Json.bool true)
        | .tuple _ => return t.setObjVal! "_tuple_unpack" (Json.bool true)
        | _ => return t
    | _ => target
  else target

/-- Is `name` assigned from a `Counter(...)`/`defaultdict(...)` call anywhere in `json` (bare or
module-qualified)? Such a var is backed by `PyDefaultDict`, not the `Std.HashMap` a plain `.dict`
annotation emits, so its hoisted binder must use the defaultdict annotation — otherwise the
`pyCounter` reassignment clashes with the `Std.HashMap` declaration. Skips nested defs. -/
partial def assignedFromDefaultDict (name : String) (json : Json) : Bool :=
  if nodeTypeOf json == some "FunctionDef" then false
  else
    let hitHere : Bool :=
      nodeTypeOf json == some "Assign"
        && ((getField json "target").bind nameId? == some name)
        && (match getField json "value" with
            | some v =>
                nodeTypeOf v == some "Call" &&
                (match getField v "func" with
                 | some f =>
                     match (nameId? f).orElse (fun _ => (f.getObjValAs? String "attr").toOption) with
                     | some n => n == "Counter" || n == "defaultdict"
                     | none => false
                 | none => false)
            | none => false)
    hitHere || (match json with
      | .arr xs => xs.any (assignedFromDefaultDict name)
      | .obj fs => fs.toList.any (fun (_, v) => assignedFromDefaultDict name v)
      | _ => false)

/-- Stamp `<typesKey>`: for each name a block leaks out (listed under `namesKey`, e.g.
`if_assigned_names`) that we can type, its annotation — so codegen ascribes the hoisted
`let mut x : T := default`. A genuinely dynamic var (`.any`) yields `PyAny`; an `unknown` one is
omitted (`toAnnotation?` → none), leaving codegen's untyped `let mut x := default` for Lean to infer. -/
private partial def stampHoistTypes (env : Env) (namesKey typesKey : String) (s : Json) : Json :=
  match s.getObjValAs? (Array String) namesKey with
  | .ok names =>
      -- Only ascribe where it is safe (`needsAscription`): a `.float` binder must stay unascribed, or
      -- a `ℚ` ascription fights a real-context `ℝ` branch value; `.any` DOES need it (→ `PyAny`).
      let entries := names.toList.filterMap (fun nm =>
        match env.get? nm with
        | some t =>
            if t.needsAscription then
              -- A dict var fed by `Counter`/`defaultdict` is `PyDefaultDict`-backed, not `Std.HashMap`.
              let ann? := match t with
                | .dict k v => if assignedFromDefaultDict nm s then defaultDictAnnotation? k v else toAnnotation? t
                | _ => toAnnotation? t
              ann?.map (fun ann => (nm, ann))
            else none
        | none => none)
      if entries.isEmpty then s else s.setObjVal! typesKey (Json.mkObj entries)
  | _ => s

/-- Stamp `_list_unpack` on a comprehension/generator tuple target iterating a list-of-lists
(`[… for a, b in edges]`, `edges : list[list[int]]`), so codegen indexes it (`row[0]`) instead of
projecting a `Prod` — the same mark `stampStmt` gives a `for`-statement target. Iterates the whole
subtree; the first generator's `iter` is typed in the enclosing `env` (the common case). -/
partial def stampCompTargets (sigs : Sigs) (env : Env) (json : Json) : Json :=
  if nodeTypeOf json == some "FunctionDef" then json
  else
    let json :=
      match nodeTypeOf json with
      | some "ListComp" | some "SetComp" | some "GeneratorExp" | some "DictComp" =>
          match json.getObjValAs? (Array Json) "generators" with
          | .ok gens =>
              json.setObjVal! "generators" (Json.arr (gens.map fun g =>
                match getField g "target", getField g "iter" with
                | some target, some iter =>
                    if nodeTypeOf target == some "Tuple" then
                      g.setObjVal! "target" (stampUnpackShape target (typeOfExpr sigs env iter).elemType)
                    else g
                | _, _ => g))
          | _ => json
      | _ => json
    match json with
    | .arr xs => Json.arr (xs.map (stampCompTargets sigs env))
    | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, stampCompTargets sigs env v)))
    | _ => json

/-- Set `_ty` (an annotation) on a lambda's FIRST parameter. -/
private partial def stampLambdaParam (lam : Json) (ann : Json) : Json :=
  match lam.getObjVal? "args" with
  | .ok argsNode =>
      match argsNode.getObjValAs? (Array Json) "args" with
      | .ok params =>
          if params.size ≥ 1 then
            lam.setObjVal! "args" (argsNode.setObjVal! "args"
              (Json.arr (params.set! 0 (params[0]!.setObjVal! "_ty" ann))))
          else lam
      | _ => lam
  | _ => lam

/-- The keyed collection of a `key=`-callback call (`sorted/min/max(coll, key=f)`, `xs.sort(key=f)`,
`bisect_left/right(a, x, key=f)`): the value whose ELEMENT type the callback's parameter takes. -/
private partial def keyCallbackColl? (json : Json) : Option Json :=
  match getField json "func" with
  | some func =>
      let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
      match nodeTypeOf func, (func.getObjValAs? String "id").toOption,
            (func.getObjValAs? String "attr").toOption with
      | some "Name", some fn, _ =>
          if ["sorted", "min", "max", "bisect_left", "bisect_right", "bisect",
              "nlargest", "nsmallest"].contains fn then args[0]? else none
      | some "Attribute", _, some "sort" => getField func "value"
      | _, _, _ => none
  | none => none

/-- Stamp each `key=`-callback lambda's first parameter with the keyed collection's element type, so
`sorted(xs, key=lambda p: -p[1])` types `p` as `xs`'s element (`list[int]` or a tuple) instead of the
polymorphic `α × β` fallback — which leaves `-p[1]` stuck on `Neg β`. Only stamps a concrete element
type (`toAnnotation?` succeeds); a tuple element is stamped too, letting codegen project statically. -/
partial def stampKeyLambdas (sigs : Sigs) (env : Env) (json : Json) : Json :=
  if nodeTypeOf json == some "FunctionDef" then json
  else
    let json :=
      if nodeTypeOf json == some "Call" then
        match keyCallbackColl? json, getField json "keywords" with
        | some coll, some kwObj =>
            match getField kwObj "key" with
            | some keyVal =>
                if nodeTypeOf keyVal == some "Lambda" then
                  let elemTy := (typeOfExpr sigs env coll).elemType
                  match toAnnotation? elemTy with
                  | some ann =>
                      -- A tuple element gets `_pair_param` too, so codegen projects `p[0]`/`p[1]`
                      -- statically (`Prod.fst`/`snd`) rather than a non-existent `PyGetItem (_ × _)`.
                      let keyVal := stampLambdaParam keyVal ann
                      let keyVal := match elemTy with
                        | .tuple _ => keyVal.setObjVal! "_pair_param" (Json.bool true)
                        | _ => keyVal
                      json.setObjVal! "keywords" (kwObj.setObjVal! "key" keyVal)
                  | none => json
                else json
            | none => json
        | _, _ => json
      else json
    match json with
    | .arr xs => Json.arr (xs.map (stampKeyLambdas sigs env))
    | .obj fs => Json.mkObj (fs.toList.map (fun (k, v) => (k, stampKeyLambdas sigs env v)))
    | _ => json

/-- Stamp one statement: its target, its nested blocks, and any nested def. -/
partial def stampStmt (sigs : Sigs) (env : Env) (roots : Array Json) (s : Json) : Json :=
  if nodeTypeOf s == some "FunctionDef" then
    let ownBody := (s.getObjValAs? (Array Json) "body").toOption.getD #[]
    stampFunction sigs env (nestedParamHints sigs env s (roots ++ ownBody)) s
  else Id.run do
    let mut s := s
    match nodeTypeOf s with
    | some "Assign" | some "AnnAssign" | some "AugAssign" | some "For" =>
        if let some t := getField s "target" then
          let allowDict := match getField s "value" with
            | some v =>
                nodeTypeOf v != some "Call"
                || ((getField v "func").bind (·.getObjValAs? String "library_module" |>.toOption)).isNone
            | none => true
          s := s.setObjVal! "target" (stampTarget env t allowDict)
    | _ => pure ()
    -- `c[i] = v` into a float-element container: stamp the *value* so codegen ascribes it to the
    -- element type. An un-ascribed `Int` value otherwise pins `PySetItem`'s value `outParam` to `ℤ`,
    -- which never resolves against a `List ℚ` / `Float` container (`dp = [float('inf')]*n; dp[0]=0`).
    if nodeTypeOf s == some "Assign" then
      match getField s "target", getField s "value" with
      | some target, some value =>
          -- `typeOfExpr` on the lvalue descends any subscript depth (`dp[i]`, `f[i][j]`) and dicts,
          -- so this covers 1-D and N-D float containers alike.
          if nodeTypeOf target == some "Subscript" && (getField value "_ty").isNone
             && typeOfExpr sigs env target == .float then
            if let some ann := toAnnotation? .float then
              s := s.setObjVal! "value" (value.setObjVal! "_ty" ann)
          -- `x = <int literal>` where `x` is a float-typed scalar (`ans = 0; ans = max(ans, inf)`):
          -- stamp the literal so codegen coerces `(0 : ℚ)` and Lean infers `x : ℚ`, WITHOUT ascribing
          -- the binder — that would force `ℚ` over a transcendental `ℝ` in a pure-float var.
          else if (nameId? target).any (fun n => (env.get? n).getD .unknown == .float)
             && nodeTypeOf value == some "Constant" && (getField value "_ty").isNone
             && typeOfExpr sigs env value == .int then
            if let some ann := toAnnotation? .float then
              s := s.setObjVal! "value" (value.setObjVal! "_ty" ann)
          -- `f = [0]*n` / `f = [inf]*n` where `f` is a float-typed container that later holds floats:
          -- coerce int-literal elements to float, and ascribe a list-literal/`[x]*n` value to the
          -- float container so a polymorphic element (`inf`) adapts to the mode float — otherwise
          -- `[inf]*n` binds `List ℚ` and a run-twin `dp[0] = 0` (`(0 : Float)`) clashes.
          else if (nameId? target).bind (env.get? ·) |>.any deepFloatContainer then
            let ct := ((nameId? target).bind (env.get? ·)).getD .unknown
            let value := stampFloatListElems value
            let value := if isListLitOrRepeat value && (getField value "_ty").isNone then
                (toAnnotation? ct).elim value (value.setObjVal! "_ty" ·)
              else value
            s := s.setObjVal! "value" value
      | _, _ => pure ()
    -- A tuple target unpacked from a *list* value (not a tuple) uses list indexing, not `Prod`:
    -- `for a, b in edges` with `edges : list[list[int]]`, or `a, b = np.shape(x)` (returns a list).
    -- Mark the target so codegen can tell.
    -- `for a, b in edges` (`edges : list[list[int]]`) indexes; `for k, (l, r) in enumerate(queries)`
    -- is a `Prod` outer with a list inner — stampUnpackShape marks each level from the element type.
    if nodeTypeOf s == some "For" then
      match getField s "target", getField s "iter" with
      | some target, some iter =>
          if nodeTypeOf target == some "Tuple" then
            s := s.setObjVal! "target" (stampUnpackShape target (typeOfExpr sigs env iter).elemType)
      | _, _ => pure ()
    -- `a, b = t[k]` (`t : list[(int,int)]`) reads a `Prod`; `a, b = np.shape(x)` reads a list.
    if nodeTypeOf s == some "Assign" then
      match getField s "target", getField s "value" with
      | some target, some value =>
          if nodeTypeOf target == some "Tuple" then
            s := s.setObjVal! "target" (stampUnpackShape target (typeOfExpr sigs env value))
      | _, _ => pure ()
    -- A name a branch/try leaks out (Python has no block scope; Lean does) is hoisted by codegen to
    -- `let mut x : T := default` before the block. Stamp its type T so the hoist is ascribed — PyAny
    -- for a genuinely dynamic var, so `default` resolves (to `emptyPyAny`); unknown types are omitted.
    s := stampHoistTypes env "if_assigned_names" "if_assigned_types" s
    s := stampHoistTypes env "try_assigned_names" "try_assigned_types" s
    s := stampHoistTypes env "for_assigned_names" "for_assigned_types" s
    s := stampHoistTypes env "while_assigned_names" "while_assigned_types" s
    for f in #["body", "orelse", "finalbody"] do
      if let .ok elems := s.getObjValAs? (Array Json) f then
        s := s.setObjVal! f (Json.arr (elems.map (stampStmt sigs env roots)))
    if let .ok handlers := s.getObjValAs? (Array Json) "handlers" then
      let handlers := handlers.map fun h =>
        match h.getObjValAs? (Array Json) "body" with
        | .ok elems => h.setObjVal! "body" (Json.arr (elems.map (stampStmt sigs env roots)))
        | _ => h
      s := s.setObjVal! "handlers" (Json.arr handlers)
    return s

end

/-! ### Interprocedural: return types flow to call sites, argument types flow to parameters -/

/-- Inferred type of each parameter of each user function, by position. -/
abbrev ParamSigs := Std.HashMap String (Array PyType)

/-- Every top-level `FunctionDef` in a module or mutual group, in order. -/
private def topFunctions (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter
    (nodeTypeOf · == some "FunctionDef")

/-- Module top-level statements that are not function defs (e.g. `print(add(3, 4))` at module scope):
their call sites refine callee params too, so `add` boxes whether it is called from a def or not. -/
private def topLevelStmts (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter
    (nodeTypeOf · != some "FunctionDef")

/-- Top-level `ClassDef`s of a module. -/
private def classDefsOf (module : Json) : Array Json :=
  ((module.getObjValAs? (Array Json) "body").toOption.getD #[]).filter (nodeTypeOf · == some "ClassDef")

/-- The `FunctionDef` methods of a class (stored under `methods`, or `body` on older nodes). -/
private def methodsOf (classDef : Json) : Array Json :=
  (#["methods", "body"].foldl (fun acc key =>
    acc ++ (classDef.getObjValAs? (Array Json) key).toOption.getD #[]) #[]).filter
    (nodeTypeOf · == some "FunctionDef")

/-- Names of every class defined at module top level. -/
private def classNamesOf (module : Json) : Std.HashSet String :=
  (classDefsOf module).foldl (fun s c => (c.getObjValAs? String "name").toOption.elim s s.insert) {}

/-- True when `fn`'s first parameter is `self` — an instance method, as opposed to a `@staticmethod`. -/
private def isInstanceMethod (fn : Json) : Bool := (paramNames fn)[0]? == some "self"

/-- Collect `Class.method(...)` call sites for method-parameter inference, keyed `"Class.method"` (a
dot no Python function name has). Two shapes resolve a class: a qualified call on a class *name*
(`BinaryIndexedTree.lowbit(x)`, static or explicit-`self`) and an instance call whose receiver types
to `.cls C` (`tree.update(a, b)`, `self.query(x)`). An instance method's arg list is prefixed with the
receiver's `.cls C` so it aligns with the `self` parameter. Skips nested defs' own scopes only in that
`env` is the enclosing one; the walk itself is exhaustive. -/
private partial def collectMethodCalls (sigs : Sigs) (env : Env) (classNames : Std.HashSet String)
    (methodSelf : Std.HashMap String Bool) (json : Json) : Array (String × Array PyType) :=
  let here : Array (String × Array PyType) :=
    match nodeTypeOf json, getField json "func" with
    | some "Call", some func =>
        if nodeTypeOf func != some "Attribute" then #[] else
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
private def hintsForKey (params : ParamSigs) (fn : Json) (key : String) : Env := Id.run do
  let names := paramNames fn
  let types := (params.get? key).getD #[]
  let mut env : Env := {}
  for i in [0:names.size] do
    if let some t := types[i]? then if t != .unknown then env := env.insert names[i]! t
  return env

/-- The hint environment for `fn`'s parameters from `params` (its inferred per-position types). -/
private def hintsFor (params : ParamSigs) (fn : Json) : Env :=
  hintsForKey params fn ((fn.getObjValAs? String "name").toOption.getD "")

/-- Collect `(calleeName, argumentTypes)` for every direct call `foo(a, b, …)` in `json`, typing the
arguments under `env`. Nested calls are included; method calls are ignored (no positional callee). -/
private partial def collectCalls (sigs : Sigs) (env : Env) (json : Json) : Array (String × Array PyType) :=
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
private def decoratorNamesOf (fn : Json) : Array String :=
  ((fn.getObjValAs? (Array Json) "decorator_list").toOption.getD #[]).filterMap fun d =>
    if nodeTypeOf d == some "Name" then nameId? d else none

/-- Join `argTypes` into `params[name]` position-by-position (missing positions start `unknown`). -/
private def refineParams (params : ParamSigs) (name : String) (arity : Nat) (argTypes : Array PyType) : ParamSigs :=
  let cur := (params.get? name).getD (Array.replicate arity .unknown)
  let next := (Array.range cur.size).map fun i =>
    (cur[i]!).join (argTypes[i]?.getD .unknown)
  params.insert name next

/-- Field types of every class in the module, keyed `"Class.field"` so `typeOfExpr` can type a field
access. Mirrors the struct codegen: an explicit annotation wins; otherwise an `__init__` param
defaulting to `None` types the field `Option Class` (the recursive `TreeNode.left`/`ListNode.next`
pattern); otherwise the initialising param's annotation or the type of its default. -/
private def classFieldSigs (module : Json) : Sigs := Id.run do
  let mut out : Sigs := {}
  for st in topLevelStmts module do
    if nodeTypeOf st != some "ClassDef" then continue
    let .ok cls := st.getObjValAs? String "name" | continue
    let methods := (st.getObjValAs? (Array Json) "methods").toOption.getD #[]
    -- `__init__` params: their declared/default type, and which ones default to `None`.
    let mut ptype : Env := {}
    let mut noneParams : List String := []
    if let some init := methods.find? (·.getObjValAs? String "name" == .ok "__init__") then
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
        let t := if annT != .unknown then annT else
          match getField f "init" with
          | some init =>
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
          | none => .unknown
        if t != .unknown then out := out.insert s!"{cls}.{fname}" t
  return out

/-- True when a type names a user class anywhere. Such a type must NOT be written back as an
annotation: the run twin renames `TreeNode` to `TreeNode'rn`, and only the struct codegen's own
class-name path applies that suffix — a literal annotation would pin the unsuffixed name. -/
private partial def mentionsClass : PyType → Bool
  | .cls _ => true
  | .list e | .set e | .opt e => mentionsClass e
  | .dict k v => mentionsClass k || mentionsClass v
  | .tuple es => es.any mentionsClass
  | .fn as r => as.any mentionsClass || mentionsClass r
  | _ => false

/-- Write each class field's inferred type into its (empty) `annotation` slot, which the struct
codegen already prefers over its own literal-shape guess — so a container field stops silently
defaulting to `Int`. -/
private def stampClassFields (fields : Sigs) (cls : String) (st : Json) : Json :=
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
    let mut nextSigs := sigs
    let mut nextParams := params
    let refineFrom (nextParams : ParamSigs) (calls : Array (String × Array PyType)) : ParamSigs :=
      calls.foldl (fun p (callee, argTypes) =>
        if params.contains callee then refineParams p callee argTypes.size argTypes else p) nextParams
    for fn in fns do
      if let .ok name := fn.getObjValAs? String "name" then
        let hints := hintsFor params fn
        nextSigs := nextSigs.insert name (returnTypeOf sigs hints fn)
        -- refine callees' params from this function's call sites, typed under its own env.
        let env := inferFunction sigs {} hints fn
        nextParams := refineFrom nextParams (collectCalls sigs env fn)
        nextParams := refineFrom nextParams (collectMethodCalls sigs env classNames methodSelf fn)
    -- Class methods: refine callees from each method body, with `self` typed to its class.
    for (cls, mn, m) in methodEntries do
      let key := s!"{cls}.{mn}"
      let hints := methodHints params cls key m
      nextSigs := nextSigs.insert key (returnTypeOf sigs hints m)
      let env := inferFunction sigs {} hints m
      nextParams := refineFrom nextParams (collectCalls sigs env m)
      nextParams := refineFrom nextParams (collectMethodCalls sigs env classNames methodSelf m)
    -- Module top-level call sites (outside any def), typed under an empty env (literal args).
    for stmt in topLevelStmts module do
      nextParams := refineFrom nextParams (collectCalls sigs {} stmt)
      nextParams := refineFrom nextParams (collectMethodCalls sigs {} classNames methodSelf stmt)
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
              stampFunction sigs outer (hintsForKey params m s!"{cls}.{mn}") m
            else m))
        | _ => s) s
  | some "Module" =>
      match s.getObjValAs? (Array Json) "body" with
      | .ok body => s.setObjVal! "body" (Json.arr (body.map (stampNodeWith sigs params globals)))
      | _ => s
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
  let globals : Env := (topLevelStmts module).foldl (applyStmt sigs) {}
  -- Mark each statement `_inferred` so the per-request fallback pass (which lacks module context and
  -- would re-derive worse types, e.g. a global-fed `float` local mis-stamped `int`) skips it.
  let mark (s : Json) : Json := (stampNodeWith sigs params globals s).setObjVal! "_inferred" (Json.bool true)
  match module.getObjValAs? (Array Json) "body" with
  | .ok body => module.setObjVal! "body" (Json.arr (body.map mark))
  | _ => mark module

end TypeInfer
