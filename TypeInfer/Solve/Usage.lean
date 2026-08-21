import TypeInfer.Solve.Env

namespace TypeInfer

open Lean

/-- Every statement in a body, flattened through nested blocks but not into nested `def`s. -/
partial def flatStmts (stmts : List Json) : List Json :=
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
def isNoneConst (j : Json) : Bool :=
  nodeTypeOf j == some "Constant" && (getField j "value" == some Json.null)

/-- A list of all `None` — `[None, None]` or `[None] * k` — the initial value of a recursive node's
child array (a Trie's `children`, a segment tree's kids). -/
partial def isListOfNone (j : Json) : Bool :=
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
partial def nameIsNoneTested (name : String) (json : Json) : Bool :=
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
partial def nameReassigned (name : String) (json : Json) : Bool :=
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
def paramSeed (fn : Json) : Env := Id.run do
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

/-- Does `ord(name)` appear anywhere in `json`? `ord` demands a one-character string, so its argument
is a single character (a `str`). -/
partial def containsOrdOf (name : String) (json : Json) : Bool :=
  (nodeTypeOf json == some "Call"
    && (getField json "func").bind nameId? == some "ord"
    && ((json.getObjValAs? (Array Json) "args").toOption.getD #[]).any (fun a => nameId? a == some name))
  || (match json with
      | .arr xs => xs.any (containsOrdOf name)
      | .obj fs => fs.toList.any (fun (_, v) => containsOrdOf name v)
      | _ => false)

/-- The static type of a *literal* expression (needs no environment): `[]`→list, `""`→str, `5`→int,
`3.0`→float, `True`→bool, `None`→none, plus list/set/tuple literals recursively. `none` for a
non-literal (a name, a call, …) so the caller learns nothing. Covers every PyAny subtype. -/
partial def literalType? (e : Json) : Option PyType :=
  let elts := ((e.getObjValAs? (Array Json) "elts").toOption.getD #[]).toList
  match nodeTypeOf e with
  | some "Constant" => some (ofValue e)
  | some "List"  => some (.list  (PyType.joinAll (elts.filterMap literalType?)))
  | some "Set"   => some (.set   (PyType.joinAll (elts.filterMap literalType?)))
  | some "Tuple" => some (.tuple (elts.map (fun x => (literalType? x).getD .unknown)))
  | _ => none

/-- `side` is a subscript read `name[…]` (a direct element access of `name`). -/
def isSubscriptOf (name : String) (side : Option Json) : Bool :=
  match side with
  | some s => nodeTypeOf s == some "Subscript" && (getField s "value").bind nameId? == some name
  | none => false

/-- `name[…]` appears ANYWHERE in `j` — used to propagate an element constraint down through nested
arithmetic (`(array[0] + array[-1]) % 2` still teaches `array`'s element from the outer `% 2`). -/
partial def containsSubscriptOf (name : String) (j : Json) : Bool :=
  (nodeTypeOf j == some "Subscript" && (getField j "value").bind nameId? == some name)
  || (match j with
      | .arr xs => xs.any (containsSubscriptOf name)
      | .obj fs => fs.toList.any (fun (_, v) => containsSubscriptOf name v)
      | _ => false)

/-- What `name`'s usage in one expression unambiguously tells us — enumerated exhaustively over the
Python signals that pin exactly one type: a type-exclusive method on it (`p.split()` → str), an
int-only operator over it (`p << 1`, `p >> 1`, `~p` — bitwise `& | ^` are int OR set, so NOT here),
a type-fixing builtin arg (`ord(p)` → str, `chr(p)` → int), or a comparison against a literal
(`p == []` → list, `p == ""` → str, `p in "abc"` → str element). Genuinely ambiguous uses (`p[i]`,
`for x in p`, `len(p)`, `p + q`) stay `unknown` — the fixpoint fills them in. -/
partial def usageType (fnParams : Std.HashMap String (Array PyType)) (known : Env) (fuel : Nat) (name : String) (json : Json) : PyType :=
  let isName (j : Option Json) : Bool := j.bind nameId? == some name
  -- Element type of an iterable whose loop variable `c` is used as `ctx`: `ord(c)` ⇒ the iterable is
  -- a `str` (char iteration); any other concrete usage ⇒ `list[<c's type>]`. `fuel` bounds how deep
  -- loop-variable inference may nest — each level re-scans a body via `usageType`, so unbounded
  -- nesting (comprehension inside comprehension in a big contract) blows up exponentially.
  let loopElemType (c : String) (ctx : Json) : PyType :=
    if fuel == 0 then .unknown
    else if containsOrdOf c ctx then .str
    else match usageType fnParams known (fuel - 1) c ctx with
      | .unknown => .unknown
      -- a `str`-typed loop var is ambiguous: iterating a STRING yields 1-char strings, so `str` usage
      -- could mean `p : str` (char iteration) OR `p : list[str]`. Leave it to other signals rather
      -- than force `list[str]` (which mis-typed a plain-string param iterated char by char).
      | .str => .unknown
      | t => .list t
  let here : PyType :=
    match nodeTypeOf json with
    | some "Call" =>
        match getField json "func" with
        -- `p.method(...)`: a type-exclusive method pins `p`.
        | some func =>
            if nodeTypeOf func == some "Attribute" then
              if isName (getField func "value") then
                (func.getObjValAs? String "attr").toOption.elim .unknown Libraries.builtinMethodReceiver?
              -- `p[i].method()`: a type-exclusive method on an ELEMENT ⇒ `p : list[<receiver>]`
              -- (e.g. `words[0].upper()` ⇒ `words : list[str]`).
              else if isSubscriptOf name (getField func "value") then
                match (func.getObjValAs? String "attr").toOption.map Libraries.builtinMethodReceiver? with
                | some t => if t == .unknown then .unknown else .list t
                | none => .unknown
              else .unknown
            -- `ord(p)` → p is a one-char str; `chr(p)` → p is an int.
            else match nameId? func with
              | some fn =>
                  let args := (json.getObjValAs? (Array Json) "args").toOption.getD #[]
                  -- `p(...)` — the param is CALLED, so it is a function of this arity (a higher-order
                  -- callback); the arg/return types are refined from the call site interprocedurally.
                  if fn == name then .fn (List.replicate args.size .unknown) .unknown
                  -- `filter(lambda c: <body>, p)` / `map(lambda c: <body>, p)`: `p`'s element is
                  -- inferred from the lambda body, exactly like a comprehension target (`x < 0` ⇒
                  -- `p : list[int]`). Only fires when the body pins the element; an ambiguous body
                  -- (e.g. `c in "abc"`) stays `unknown`.
                  -- The container arg may be the name itself OR a SLICE of it (`arr[:k]`) — a slice's
                  -- elements are the container's elements, so the inferred element applies to `name`.
                  else if (fn == "filter" || fn == "map")
                          && args.any (fun a => nameId? a == some name
                             || (isSubscriptOf name (some a)
                                 && (getField a "slice").any (nodeTypeOf · == some "Slice"))) then
                    match args[0]? with
                    | some lam =>
                        if nodeTypeOf lam == some "Lambda" then
                          match (getField lam "args").bind (fun a => (a.getObjValAs? (Array Json) "args").toOption)
                                |>.bind (·[0]?) |>.bind (·.getObjValAs? String "arg" |>.toOption) with
                          | some c => loopElemType c ((getField lam "body").getD Json.null)
                          | none => .unknown
                        else .unknown
                    | none => .unknown
                  else if args.any (fun a => nameId? a == some name) then
                    if fn == "ord" then .str else if fn == "chr" then .int
                    else
                      -- `f(x)` where user/nested fn `f` has an ANNOTATED param at x's position ⇒ `x`
                      -- has that type: a well-typed call must match the annotation. Sound —
                      -- `digits(x: int)` ⇒ `x : int`, so `filter(lambda x: digits(x)…, arr)` ⇒ `arr :
                      -- list[int]`. `unknown` if `f` is unknown or its param there is unannotated.
                      match fnParams.get? fn with
                      | some ptys =>
                          match (List.range args.size).find? (fun i => nameId? args[i]! == some name) with
                          | some i => match ptys[i]? with | some t => if t.isKnown then t else .unknown | none => .unknown
                          | none => .unknown
                      | none => .unknown
                  else .unknown
              | none => .unknown
        | none => .unknown
    -- Shift is int-only in Python (`p << 1`); `& | ^` also work on sets, so they pin nothing for a
    -- bare name. But over an ELEMENT (`p[i]`) these int-only ops teach `p : list[int]`, and an
    -- arithmetic op against a literal teaches the element from the literal.
    | some "BinOp" =>
        let op := (json.getObjValAs? String "op").toOption.getD ""
        let left := getField json "left"
        let right := getField json "right"
        -- `p << 1`: `p` itself is int.
        if ["lshift", "rshift"].contains op && (isName left || isName right) then .int
        -- an int-only op anywhere over an element of `p` — however nested, e.g. `(p[0]+p[-1]) % 2` —
        -- forces the element int ⇒ `p : list[int]`.
        else if ["mod", "lshift", "rshift", "bitand", "bitor", "bitxor"].contains op
                && (left.elim false (containsSubscriptOf name) || right.elim false (containsSubscriptOf name)) then .list .int
        -- `p[i] <arith> <literal>` (or the reverse): the element has the literal's type.
        else if ["add", "sub", "mul", "div", "floordiv", "pow"].contains op then
          if isSubscriptOf name left then (right.bind literalType?).elim .unknown .list
          else if isSubscriptOf name right then (left.bind literalType?).elim .unknown .list
          -- `name + <str/list literal>` pins `name` to that type: `+` typechecks only between two
          -- `str`s or two `list`s (`class_name + "."` ⇒ `class_name : str`), so a `str`/`list` literal
          -- on the other side is decisive (`int + str` / `list + str` are `TypeError`s in Python).
          else
            -- `x <arith> <numeric literal>` on a plain name (a loop/element variable, `x + 1`, `x * 2`)
            -- pins `x` to that numeric type — the `[x + 1 for x in l]` element case. `str`/`list`
            -- literals under `+` stay concat-typed (below). EXCLUDES `pow`: `a ** 0.5` (a float sqrt
            -- bound) does NOT make the base a float — `int ** 0.5` is valid, common in primality checks.
            let numLit (lit : Option Json) : PyType :=
              if op == "pow" then .unknown else match lit.bind literalType? with
              | some .int => .int | some .float => .float | _ => .unknown
            let numg := (if isName left then numLit right else .unknown).join
                        (if isName right then numLit left else .unknown)
            if numg != .unknown then numg
            else if op == "add" then
              let concatType (lit : Option Json) : PyType := match lit.bind literalType? with
                | some (.str) => .str
                | some (.list e) => .list e
                | _ => .unknown
              if isName left then concatType right
              else if isName right then concatType left
              else .unknown
            else .unknown
        else .unknown
    -- `~p` (bitwise NOT) is int-only.
    | some "UnaryOp" =>
        if (json.getObjValAs? String "op").toOption == some "invert" && isName (getField json "operand")
        then .int else .unknown
    -- `for c in p`: infer `p`'s element from how the loop variable `c` is used in the body. `ord(c)`
    -- means `p` is a `str` iterated CHARACTER by character (the unannotated-word pattern); any other
    -- concrete usage (`c > 0`, `c.split()`) means `p : list[<that element>]`. A `str`-forcing usage is
    -- ambiguous (str-of-chars vs list[str]) so only `ord` decides `str`; the general lift covers
    -- `int`/`float`/container elements. Conflicting evidence joins to `unknown` (→ PyAny), so a dict
    -- param iterated for its keys is not mis-tagged when a `.keys()`/`d[k]=v` signal is also present.
    | some "For" =>
        match getField json "iter", (getField json "target").bind nameId? with
        | some it, some c =>
            if isName (some it)
            then loopElemType c (Json.arr ((json.getObjValAs? (Array Json) "body").toOption.getD #[]))
            else .unknown
        | _, _ => .unknown
    -- A comprehension `[<elt> for c in p if <ifs>]` (or `all(<elt> for c in p)` in a spec): each
    -- generator iterating `p` teaches `p`'s element from how its target `c` is used in `elt`/`ifs` —
    -- the comprehension analogue of the `For` rule. This is what recovers `lst : list[int]` from an
    -- injected `Requires(all(x > 0 for x in lst))`, keeping the param concrete instead of `PyAny`.
    | some "ListComp" | some "SetComp" | some "GeneratorExp" =>
        let elt := (getField json "elt").toArray
        let gens := (json.getObjValAs? (Array Json) "generators").toOption.getD #[]
        PyType.joinAll (gens.toList.map (fun g =>
          match getField g "iter", (getField g "target").bind nameId? with
          | some it, some c =>
              if nameId? it == some name then
                let ifs := (g.getObjValAs? (Array Json) "ifs").toOption.getD #[]
                loopElemType c (Json.arr (elt ++ ifs))
              else .unknown
          | _, _ => .unknown))
    -- `p <cmp> <literal>` (or the reverse) pins `p` to the literal's type — the only type a concrete
    -- value can be compared at. `in`/`notin` mean `p` is an ELEMENT of the literal container → its
    -- element type. `is`/`isnot` are identity (usually `x is None` ⇒ nullable, NOT `none`), so they
    -- teach nothing. Conflicting usages join to `unknown` (→ PyAny); a type-CHANGING reassignment is
    -- still resolved per-segment by codegen's rebind-shadow, so this only ever refines a single-typed
    -- parameter (e.g. an unannotated `array` used as `array == []`).
    | some "Compare" =>
        let op := (json.getObjValAs? String "op").toOption.getD ""
        let left := getField json "left"
        let right := getField json "right"
        let membership := op == "in" || op == "notin"
        let valueCmp := ["eq", "ne", "lt", "le", "gt", "ge"].contains op
        -- An ORDERED comparison (`< <= > >=`) requires order-COMPATIBLE operands in Python 3
        -- (`1 < "a"` is a `TypeError`), so `x < t` where the OTHER operand's type is already KNOWN
        -- pins `x` to that same scalar type — soundly, and matching what Lean's `<` would infer.
        -- `word < ans` with `ans : str` ⇒ `word : str` (NOT `int`); `x < t` with `t : int` ⇒ `x : int`.
        -- `eq`/`ne` are excluded (any two values are `==`-comparable). Only scalar anchors (no containers).
        let ordered := ["lt", "le", "gt", "ge"].contains op
        let anchorOf (other : Option Json) : PyType :=
          match (other.bind nameId?).bind known.get? with
          | some t => if [PyType.int, .float, .str, .bool].contains t then t else .unknown
          | none => .unknown
        let fromOrdered : PyType :=
          if ordered then (if isName left then anchorOf right else .unknown).join
                          (if isName right then anchorOf left else .unknown)
          else .unknown
        let elemOf : PyType → PyType
          | .list e => e | .set e => e | .tuple es => PyType.joinAll es | _ => .unknown
        let fromLeft : PyType :=
          if isName left then
            match right.bind literalType? with
            | some t => if membership then elemOf t else if valueCmp then t else .unknown
            | none => .unknown
          else .unknown
        let fromRight : PyType :=
          if valueCmp && isName right then (left.bind literalType?).getD .unknown else .unknown
        -- `<literal> in p` (name is the CONTAINER): `p` holds elements of the literal's type ⇒
        -- `p : list[<literal>]` (`0 in arr` ⇒ `arr : list[int]`). Left as `list` since it is the common
        -- array case; a competing dict/set signal joins this away to `unknown`/`any` as usual. A `str`
        -- literal is EXCLUDED — `"a" in s` is ambiguous between substring (`s : str`) and membership
        -- (`s : list[str]`); only a non-`str` literal makes `p` unambiguously a container.
        let fromRightContainer : PyType :=
          if membership && isName right then
            match left.bind literalType? with
            | some t => if t == .str then .unknown else .list t
            | none => .unknown
          else .unknown
        -- `p[i] <cmp> <literal>` pins the ELEMENT type ⇒ `p : list[<that>]`.
        let fromLeftElem : PyType :=
          if valueCmp && isSubscriptOf name left then (right.bind literalType?).elim .unknown .list else .unknown
        let fromRightElem : PyType :=
          if valueCmp && isSubscriptOf name right then (left.bind literalType?).elim .unknown .list else .unknown
        fromLeft.join fromRight |>.join (fromLeftElem.join fromRightElem) |>.join fromRightContainer
          |>.join fromOrdered
    | _ => .unknown
  let sub := match json with
    | .arr xs => PyType.joinAll (xs.toList.map (usageType fnParams known fuel name))
    | .obj fs => PyType.joinAll (fs.toList.map (fun (_, v) => usageType fnParams known fuel name v))
    | _ => .unknown
  here.join sub

end TypeInfer
