import PastaLean.PyGens.Core.Utils
import PastaLean.PyGens.Calls.CallEffects
import PastaLean.PyGens.Calls.CallShared

open Lean Meta Elab Term Qq Std

namespace PastaLean

/-- Read all Name idents from a tuple assignment target (any arity ≥ 2). -/
def tupleAssignTargetNames? (target : Json) : PygenM (Option (Array (TSyntax `ident))) := do
  unless jsonNodeType? target == some "Tuple" do
    return none
  let .ok elts := target.getObjValAs? (Array Json) "elts" | throwError
    s!"Tuple assignment target does not have an 'elts' field or it is not a JSON value: {target}"
  if elts.size < 2 then
    throwError "Tuple assignment target must have at least two elements."
  let mut idents := #[]
  for elt in elts do
    unless jsonNodeType? elt == some "Name" do
      throwError "Only Name targets are supported in tuple assignment."
    idents := idents.push (← getCode elt `ident)
  return some idents

/-- The elements of a tuple-assignment target (arity ≥ 2), or `none` if it is not a `Tuple`.
Unlike `tupleAssignTargetNames?`, elements may be any target shape — e.g. the `Subscript`s in
`a[i], a[j] = a[j], a[i]`. -/
def tupleTargetElts? (target : Json) : PygenM (Option (Array Json)) := do
  unless jsonNodeType? target == some "Tuple" do
    return none
  let .ok elts := target.getObjValAs? (Array Json) "elts" | throwError
    s!"Tuple assignment target does not have an 'elts' field or it is not a JSON value: {target}"
  if elts.size < 2 then
    throwError "Tuple assignment target must have at least two elements."
  return some elts

/-- Build the accessor term to reach element `idx` of an N-element right-nested pair `pairIdent`.
`buildTuple` produces `(e0, (e1, (e2, e3)))`, so:
  - element 0 → `Prod.fst p`
  - element 1 → `Prod.fst (Prod.snd p)`
  - element N-2 → `Prod.fst (Prod.snd^(N-2) p)`
  - element N-1 → `Prod.snd^(N-1) p` -/
def tupleAccessTerm (pairIdent : TSyntax `ident) (idx n : Nat) : PygenM (TSyntax `term) := do
  let fstIdent := mkIdent ``Prod.fst
  let sndIdent := mkIdent ``Prod.snd
  let mut base : TSyntax `term := mkIdent pairIdent.getId
  for _ in List.range idx do
    base ← `($sndIdent $base)
  if idx == n - 1 then
    pure base
  else
    `($fstIdent $base)

/-- Build the accessor to reach element `idx` of an unpack source.

Python unpacking (`a, b, c = rhs`) iterates the RHS, but our two runtime shapes need different
accessors: a tuple *literal* RHS builds a right-nested `Prod` (so use `Prod.fst`/`Prod.snd`),
while anything else (a `list`, a `map(...)`/`split()` result, a variable) is a `List` (so index
with `pyListGetItem`). `isTuple` selects which. -/
def unpackAccessTerm (isTuple : Bool) (sourceIdent : TSyntax `ident) (idx n : Nat) :
    PygenM (TSyntax `term) := do
  if isTuple then
    tupleAccessTerm sourceIdent idx n
  else
    let getIdent := mkIdent ``PastaLean.pyListGetItem
    let idxStx ← intToStx (Int.ofNat idx)
    `($getIdent $sourceIdent $idxStx)

/-- Pure-term binding of one tuple-target element to `acc`, recursing into nested tuple targets
(`(a, b), c = …`). `isTuple` is the access mode for the *nested* levels: `Prod` for a threaded
call's all-`Prod` return, `List` for a `list[list[...]]`. -/
partial def pureUnpackBinding (isTuple : Bool) (elt : Json) (acc tail : TSyntax `term) :
    PygenM (TSyntax `term) := do
  match jsonNodeType? elt with
  | some "Tuple" | some "List" =>
    let subElts := (elt.getObjValAs? (Array Json) "elts").toOption.getD #[]
    let tmp := mkIdent (← freshName `__unpack_pair)
    let mut body := tail
    for i in (List.range subElts.size).reverse do
      body ← pureUnpackBinding isTuple subElts[i]! (← unpackAccessTerm isTuple tmp i subElts.size) body
    `(let $tmp := $acc
      $body)
  | _ =>
    `(let $(← getCode elt `ident) := $acc
      $tail)

/-- Emit either a fresh `let mut` or a reassignment for one local binding. On the first binding an
inferred type (`ty?`) is ascribed — `let mut x : T := …` — which stops Lean defaulting an
unconstrained element/index to `ℚ`. A reassignment never re-ascribes. -/
def bindOrAssignLocal (nameIdent : TSyntax `ident) (rhs : TSyntax `term)
    (ty? : Option (TSyntax `term) := none) (rebindShadow : Bool := false) : PygenM (TSyntax `doElem) := do
  -- Python may rebind a name to a DIFFERENT type (`for ch in s: ch = ord(ch)`). One `let mut` has a
  -- fixed type, so a fresh `let mut` shadows the plain `let` the loop bound — matching Python, where
  -- code before the rebind saw the old value and code after sees the new. Its type comes from the
  -- RHS, NOT from the `PyAny` stamp: a single binding never has to hold both types.
  if rebindShadow then
    setMutVar nameIdent.getId
    return ← `(doElem| let mut $nameIdent:ident := $rhs)
  if ← hasVar nameIdent.getId then
    `(doElem| $nameIdent:ident := $rhs)
  else
    let stx ← match ty? with
      | some ty => `(doElem| let mut $nameIdent:ident : $ty := $rhs)
      | none => `(doElem| let mut $nameIdent:ident := $rhs)
    addVar nameIdent.getId
    setMutVar nameIdent.getId
    pure stx

/-- Normalize Python-style two-target unpacking through the iterable protocol. -/
def unpack2Term (value : TSyntax `term) : PygenM (TSyntax `term) := do
  let pyUnpack2Ident := mkIdent ``PastaLean.pyUnpack2
  `($pyUnpack2Ident $value)

/-- Recognize a single-level subscript assignment target `name[index]`, returning the
container ident (the `mut` variable to rebuild) and the index term. Returns `none` for
non-subscript targets; throws a clear error for unsupported subscript shapes (nested
subscripts, non-Name containers, slice targets). -/
def subscriptTargetParts? (target : Json) : PygenM (Option (TSyntax `ident × TSyntax `term)) := do
  unless jsonNodeType? target == some "Subscript" do
    return none
  let .ok containerJson := target.getObjValAs? Json "value" | throwError
    s!"Subscript assignment target is missing a 'value' field: {target}"
  let .ok sliceJson := target.getObjValAs? Json "slice" | throwError
    s!"Subscript assignment target is missing a 'slice' field: {target}"
  -- Slice targets (`s[a:b] = ...`) are item-list replacement, handled by `sliceTargetParts?`.
  if jsonNodeType? sliceJson == some "Slice" then
    return none
  unless jsonNodeType? containerJson == some "Name" do
    throwError "Only `name[index] = ...` subscript assignment (single-level, Name container) \
      is supported."
  let containerIdent ← getCode containerJson `ident
  let indexTerm ← getCode sliceJson `term
  return some (containerIdent, indexTerm)

/-- Emit `container := pySetItem container index value` for a subscript item assignment. -/
def subscriptSetDoElem (containerIdent : TSyntax `ident) (indexTerm value : TSyntax `term) :
    PygenM (TSyntax `doElem) := do
  let setItemIdent := mkIdent ``PastaLean.pySetItem
  `(doElem| $containerIdent:ident := $setItemIdent $containerIdent $indexTerm $value)

/-- If `target` is `self.X` (an `Attribute` whose base is the `Name` `self`), return the attribute
name `X`. Used to lower attribute writes inside a class method to a `self` record update. -/
def selfAttrTarget? (target : Json) : Option String :=
  if jsonNodeType? target == some "Attribute" then
    match (target.getObjVal? "value").toOption, (target.getObjValAs? String "attr").toOption with
    | some v, some attr =>
        if jsonNodeType? v == some "Name" && v.getObjValAs? String "id" == .ok "self" then
          some attr
        else none
    | _, _ => none
  else none

/-- Emit `self := { self with X := rhs }` — the value-semantics lowering of `self.X = rhs` inside a
class method body (`self` is the method's `let mut` shadow). -/
def selfRecordUpdateDoElem (attr : String) (rhs : TSyntax `term) : PygenM (TSyntax `doElem) := do
  let selfId := mkIdent `self
  let attrId := mkIdent attr.toName
  let fields := #[← `(Lean.Parser.Term.structInstField| $attrId:ident := $rhs)]
  `(doElem| $selfId:ident := { $selfId:term with $fields:structInstField,* })

/-- `<recv>.attr = rhs` under value semantics, for ANY receiver (`node.children[i]=v` on a local,
`obj.field=v`): rebuild the receiver record `{recv with attr := rhs}` and store it back — a `Name`
receiver is reassigned, a nested attribute recurses. (Emitting `let mut obj.field := …` is invalid
Lean; this is the general form of the `self` record update.) -/
partial def attrRecordUpdateDoElem (recvJson : Json) (attr : String) (rhs : TSyntax `term)
    (recvIsOpt : Bool := false) : PygenM (TSyntax `doElem) := do
  let recvTerm ← getCode recvJson `term
  let attrId := mkIdent attr.toName
  -- An `Option`-typed receiver (`root.left = v` on a tree node) must be unwrapped for the record
  -- update and re-wrapped, since `{ opt with f := v }` is not a valid update.
  let updated ← if recvIsOpt then
      `(some { ($recvTerm).getD default with $attrId:ident := $rhs })
    else `({ $recvTerm with $attrId:ident := $rhs })
  match jsonNodeType? recvJson with
  | some "Name" =>
      let recvIdent ← getCode recvJson `ident
      `(doElem| $recvIdent:ident := $updated)
  | some "Attribute" =>
      let .ok inner := recvJson.getObjVal? "value" | throwError s!"Attribute missing 'value': {recvJson}"
      let .ok innerAttr := recvJson.getObjValAs? String "attr" | throwError s!"Attribute missing 'attr': {recvJson}"
      attrRecordUpdateDoElem inner innerAttr updated
        (recvJson.getObjValAs? Bool "_unwrap_opt" == .ok true)
  | some "Subscript" =>
      -- `arr[i].f = v` / `self.tr[u].l = v`: rebuild the element `{arr[i] with f := v}` and store it
      -- back into `arr[i]` via `pySetItem`, then reassign the container (a `Name`, or an `Attribute`
      -- like `self.tr` via the same record-update recursion).
      let .ok containerJson := recvJson.getObjVal? "value" | throwError s!"Subscript missing 'value': {recvJson}"
      let .ok sliceJson := recvJson.getObjVal? "slice" | throwError s!"Subscript missing 'slice': {recvJson}"
      if jsonNodeType? sliceJson == some "Slice" then
        throwError "attribute assignment on a sliced element is not supported."
      let containerCode ← getCode containerJson `term
      let indexTerm ← getCode sliceJson `term
      let newContainer ← `($(mkIdent ``PastaLean.pySetItem) $containerCode $indexTerm $updated)
      match jsonNodeType? containerJson with
      | some "Name" =>
          let containerIdent ← getCode containerJson `ident
          `(doElem| $containerIdent:ident := $newContainer)
      | some "Attribute" =>
          let .ok inner := containerJson.getObjVal? "value" | throwError s!"Attribute missing 'value': {containerJson}"
          let .ok innerAttr := containerJson.getObjValAs? String "attr" | throwError s!"Attribute missing 'attr': {containerJson}"
          attrRecordUpdateDoElem inner innerAttr newContainer
            (containerJson.getObjValAs? Bool "_unwrap_opt" == .ok true)
      | _ => throwError "attribute assignment `arr[i].f = v` needs a variable or attribute base container."
  | _ => throwError "attribute assignment `x.f = v` needs a variable or attribute receiver."

/-- Lower a possibly-nested subscript assignment `a[i]…[k] = value` to a reassignment of the
base variable. Each level is rebuilt innermost-first with `pySetItem`: `a[i][j] = v` becomes
`a := pySetItem a i (pySetItem (pyGetItem a i) j v)`. This mirrors Python, where mutating the
inner list and leaving outer bindings pointing at the (now-rebuilt) value is observationally the
same for the local variable. Returns `none` when the target is not a subscript (or is an outer
slice, handled by `sliceTargetParts?`); throws if the base is not a variable. -/
partial def nestedSubscriptSetDoElem? (target : Json) (value : TSyntax `term) :
    PygenM (Option (TSyntax `doElem)) := do
  unless jsonNodeType? target == some "Subscript" do return none
  let .ok containerJson := target.getObjValAs? Json "value" | throwError
    s!"Subscript assignment target is missing a 'value' field: {target}"
  let .ok sliceJson := target.getObjValAs? Json "slice" | throwError
    s!"Subscript assignment target is missing a 'slice' field: {target}"
  if jsonNodeType? sliceJson == some "Slice" then return none
  let indexTerm ← getCode sliceJson `term
  let setItemIdent := mkIdent ``PastaLean.pySetItem
  let containerCode ← getCode containerJson `term
  let newContainer ← `($setItemIdent $containerCode $indexTerm $value)
  match jsonNodeType? containerJson with
  | some "Name" =>
      let containerIdent ← getCode containerJson `ident
      return some (← `(doElem| $containerIdent:ident := $newContainer))
  | some "Subscript" =>
      nestedSubscriptSetDoElem? containerJson newContainer
  | some "Attribute" =>
      -- `recv.c[i] = v` rebuilds the field: `recv := { recv with c := … }` (self or any local, e.g.
      -- a Trie walk-node `node.children[i] = Trie()`).
      let .ok recv := containerJson.getObjVal? "value" | throwError
        s!"Attribute container is missing 'value': {containerJson}"
      let .ok attr := containerJson.getObjValAs? String "attr" | throwError
        s!"Attribute container is missing 'attr': {containerJson}"
      return some (← attrRecordUpdateDoElem recv attr newContainer
        (containerJson.getObjValAs? Bool "_unwrap_opt" == .ok true))
  | _ =>
      throwError "Subscript assignment requires the base container to be a variable \
        (`a[i]…[k] = v`); got an unsupported container expression."

/-- Assign one element of a tuple target from `acc`, which reads it out of the already-evaluated
RHS temp. `Subscript` elements rebuild their container, so the swap `a[i], a[j] = a[j], a[i]`
works: the temp is evaluated before any write-back. -/
partial def tupleElementAssignDoElem (isTuple : Bool) (elt : Json) (acc : TSyntax `term) :
    PygenM (TSyntax `doElem) := do
  match ← nestedSubscriptSetDoElem? elt acc with
  | some setStx => pure setStx
  | none =>
    match jsonNodeType? elt with
    | some "Name" => bindOrAssignLocal (← getCode elt `ident) acc
    | some "Tuple" | some "List" =>
      let subElts := (elt.getObjValAs? (Array Json) "elts").toOption.getD #[]
      let tmp := mkIdent (← freshName `__unpack_nested)
      let mut binds := #[← `(doElem| let $tmp:ident := $acc)]
      for i in [0:subElts.size] do
        binds := binds.push (← tupleElementAssignDoElem isTuple subElts[i]! (← unpackAccessTerm isTuple tmp i subElts.size))
      pure ⟨mkNullNode (binds.map TSyntax.raw)⟩
    | _ =>
      throwError s!"Unsupported tuple-assignment target element (only `Name`, nested tuple, and \
        subscript `a[i]` targets are supported): {elt}"

/-- Index of a `Starred` element in a tuple target (`a, *b = …`), if any. -/
def starredTargetIndex? (elts : Array Json) : Option Nat :=
  (List.range elts.size).find? (fun i => jsonNodeType? elts[i]! == some "Starred")

/-- Lower a starred tuple-assignment `a, *b, c = src` over a list `src`. The starred element (at
`k`) collects the middle slice `src[k : -(after)]`; elements before it index from the front, and
elements after it index from the end (negative indices), so `c` always reads the last element
regardless of how many `src` holds. `src` must be list-accessed (a `*` target collects a list). -/
def starredUnpackDoElems (elts : Array Json) (k : Nat) (srcIdent : TSyntax `ident) :
    PygenM (Array (TSyntax `doElem)) := do
  let n := elts.size
  let after := n - 1 - k
  let getItem := mkIdent ``PastaLean.pyListGetItem
  let mut binds : Array (TSyntax `doElem) := #[]
  for i in List.range n do
    let elt := elts[i]!
    let bind ←
      if i < k then
        tupleElementAssignDoElem false elt (← `($getItem $srcIdent $(← intToStx (Int.ofNat i))))
      else if i == k then
        let .ok inner := elt.getObjVal? "value" | throwError
          s!"Starred assignment target is missing a 'value' field: {elt}"
        let startStx ← `(some $(← intToStx (Int.ofNat k)))
        let stopStx ← if after == 0 then `((none : Option Int))
                      else `(some $(← intToStx (-(Int.ofNat after))))
        tupleElementAssignDoElem false inner (← `($(mkIdent ``PastaLean.pyListSlice) $srcIdent $startStx $stopStx))
      else
        tupleElementAssignDoElem false elt (← `($getItem $srcIdent $(← intToStx (-(Int.ofNat (n - i))))))
    binds := binds.push bind
  pure binds

/-- Lower an optional slice bound expression to a `some _`/`none` `Option Int` term. -/
def sliceBoundOptTerm (boundJson? : Option Json) : PygenM (TSyntax `term) := do
  match boundJson? with
  | none => `(none)
  | some boundJson => `(some $(← getCode boundJson `term))

/-- Recognize a slice assignment target `name[lower:upper]`, returning the container ident
and the two optional bound terms. Returns `none` for non-slice subscript targets. A step
(`name[a:b:c]`) is rejected. -/
def sliceTargetParts? (target : Json) :
    PygenM (Option (TSyntax `ident × TSyntax `term × TSyntax `term)) := do
  unless jsonNodeType? target == some "Subscript" do
    return none
  let .ok sliceJson := target.getObjValAs? Json "slice" | throwError
    s!"Subscript assignment target is missing a 'slice' field: {target}"
  unless jsonNodeType? sliceJson == some "Slice" do
    return none
  unless (jsonFieldOption sliceJson "step").isNone do
    throwError "Slice assignment with a step (`s[a:b:c] = ...`) is not supported yet."
  let .ok containerJson := target.getObjValAs? Json "value" | throwError
    s!"Slice assignment target is missing a 'value' field: {target}"
  unless jsonNodeType? containerJson == some "Name" do
    throwError "Only `name[a:b] = ...` slice assignment (Name container) is supported."
  let containerIdent ← getCode containerJson `ident
  let lowerTerm ← sliceBoundOptTerm (jsonFieldOption sliceJson "lower")
  let upperTerm ← sliceBoundOptTerm (jsonFieldOption sliceJson "upper")
  return some (containerIdent, lowerTerm, upperTerm)

/-- Simple returned expressions can stay unparenthesized; more complex or effectful ones
keep parentheses so Lean parses multiline `return` expressions reliably. -/
def shouldParenthesizeReturnValue (value : Json) : Bool :=
  if jsonUsesMonadicEffect value then
    true
  else
    match jsonNodeType? value with
    | some "Name" => false
    | some "Constant" => false
    | some "Attribute" => false
    | _ => true

@[pygen "Assign"]
def assignSyntax : (kind : SyntaxNodeKind) → Json →
    PygenM (TSyntax kind)
    | `command, json => withRealIfMarked json do
        let .ok target := json.getObjVal? "target" | throwError
          s!"Assign node does not have a 'target' field or it is not a JSON value: {json}"
        let .ok value := json.getObjVal? "value" | throwError
          s!"Assign node does not have a 'value' field or it is not a JSON value: {json}"
        match ← tupleAssignTargetNames? target with
        | some idents => do
            let n := idents.size
            let valueStx ← getCode value `term
            let unpackTmpIdent := mkIdent (Name.mkSimple s!"__py_unpack_{idents.toList.map (·.getId.toString) |> String.intercalate "_"}")
            -- The unpack temporary is always private (an implementation detail).
            let cmd0 ← makeCommandPrivate (← `(command| def $unpackTmpIdent := $valueStx))
            -- A literal `Tuple` RHS builds a `Prod` (use `Prod.fst`/`Prod.snd`); so does a
            -- function call returning a `tuple[...]` (the Python pre-pass only leaves such
            -- tuple-returning calls as native unpacking — list-returning RHSs are pre-split
            -- into subscripts and never reach here, so a `Call` here means a `Prod` result).
            -- `_list_unpack` (stamped when the RHS is list-typed, e.g. `np.shape(x)` returns a list)
            -- forces list-index access even for a `Call` RHS that would otherwise be read as a `Prod`.
            -- `_tuple_unpack` (TypeInfer saw a `tuple[...]`-typed RHS) settles it directly.
            let isTuple := target.getObjValAs? Bool "_tuple_unpack" == .ok true
              || ((jsonNodeType? value == some "Tuple" || jsonNodeType? value == some "Call")
                  && target.getObjValAs? Bool "_list_unpack" != .ok true)
            let mut cmds : Array (TSyntax `command) := #[cmd0]
            for i in List.range n do
              let acc ← unpackAccessTerm isTuple unpackTmpIdent i n
              let cmd ← applyPrivacy idents[i]!.getId.toString (← `(command| def $(idents[i]!) := $acc))
              cmds := cmds.push cmd
            pure ⟨mkNullNode (cmds.map TSyntax.raw)⟩
        | none => do
            if jsonNodeType? target == some "Subscript" then
              throwError "Top-level subscript assignment (`s[i] = ...`) is not supported; \
                it mutates a global, which has no top-level form. Move it into a function \
                or an `if __name__ == \"__main__\"` block."
            let nameIdent ← getCode target `ident
            let valueStx ← getCode value `term
            -- `inf = float('inf')` must stay polymorphic in its numeric type: a monomorphic `def`
            -- would pin it to `ℚ` and then `-inf` inside an `int`-returning DP would not typecheck.
            if (← nonFiniteFloatTerm? ((value.getObjVal? "func").toOption.getD Json.null)
                  ((value.getObjValAs? (Array Json) "args").toOption.getD #[])).isSome then
              let α := mkIdent `α
              return ← applyPrivacy nameIdent.getId.toString
                (← `(def $nameIdent {$α : Type} [$(mkIdent ``PastaLean.PyNonFinite) $α] : $α := $valueStx))
            applyPrivacy nameIdent.getId.toString (← `(def $nameIdent := $valueStx))
    | `doElem, json => withRealIfMarked json do
        let .ok target := json.getObjVal? "target" | throwError
          s!"Assign node does not have a 'target' field or it is not a JSON value: {json}"
        let .ok value := json.getObjVal? "value" | throwError
          s!"Assign node does not have a 'value' field or it is not a JSON value: {json}"
        match ← tupleTargetElts? target with
        | some elts => do
            let n := elts.size
            let nestedIsTuple := target.getObjValAs? Bool "_thread_unpack" == .ok true
            -- RHS both yields a value (a tuple) and mutates its receiver (`d, node = heappop(h)`):
            -- bind the value first (reads the original receiver), apply the mutation, then unpack.
            if let some (valueTerm, update) ← mutatingCallRhsLowering? value then
              let valueTmpIdent := mkIdent (← freshName `__unpack_value)
              let bindValueTmp ← `(doElem| let $valueTmpIdent:ident := $valueTerm)
              let mut binds : Array (TSyntax `doElem) := #[bindValueTmp, update]
              for i in List.range n do
                let acc ← unpackAccessTerm true valueTmpIdent i n
                binds := binds.push (← tupleElementAssignDoElem nestedIsTuple elts[i]! acc)
              return ⟨mkNullNode (binds.map TSyntax.raw)⟩
            let valueStx ← getCode value `term
            let valueTmpIdent := mkIdent (← freshName `__unpack_value)
            let unpackTmpIdent := mkIdent (← freshName `__unpack_pair)
            let bindValueTmp ←
              if jsonUsesIOEffect value || jsonUsesMonadicEffect value then
                `(doElem| let $valueTmpIdent:ident ← $valueStx:term)
              else
                `(doElem| let $valueTmpIdent:ident := $valueStx)
            let bindUnpackTmp ← `(doElem| let $unpackTmpIdent:ident := $valueTmpIdent)
            -- `a, *b, c = src`: the `*` target collects a list slice, so `src` is list-accessed
            -- (never a `Prod`), and elements after the star index from the end.
            if let some k := starredTargetIndex? elts then
              let starBinds ← starredUnpackDoElems elts k unpackTmpIdent
              return ⟨mkNullNode ((#[bindValueTmp, bindUnpackTmp] ++ starBinds).map TSyntax.raw)⟩
            -- A literal `Tuple` RHS builds a `Prod` (use `Prod.fst`/`Prod.snd`); so does a
            -- function call returning a `tuple[...]` (the Python pre-pass only leaves such
            -- tuple-returning calls as native unpacking — list-returning RHSs are pre-split
            -- into subscripts and never reach here, so a `Call` here means a `Prod` result).
            -- `_list_unpack` (stamped when the RHS is list-typed, e.g. `np.shape(x)` returns a list)
            -- forces list-index access even for a `Call` RHS that would otherwise be read as a `Prod`.
            -- `_tuple_unpack` (TypeInfer saw a `tuple[...]`-typed RHS) settles it directly.
            let isTuple := target.getObjValAs? Bool "_tuple_unpack" == .ok true
              || ((jsonNodeType? value == some "Tuple" || jsonNodeType? value == some "Call")
                  && target.getObjValAs? Bool "_list_unpack" != .ok true)
            let mut binds : Array (TSyntax `doElem) := #[bindValueTmp, bindUnpackTmp]
            for i in List.range n do
              let acc ← unpackAccessTerm isTuple unpackTmpIdent i n
              binds := binds.push (← tupleElementAssignDoElem nestedIsTuple elts[i]! acc)
            -- Return the bindings as siblings (a flattened null-node), NOT wrapped in a
            -- nested `do` — wrapping would scope the unpacked names away from following
            -- statements. Consumers flatten via `appendDoElems`.
            pure ⟨mkNullNode (binds.map TSyntax.raw)⟩
        | none => do
            -- Some RHS calls both mutate their receiver and yield a value (e.g. `x.pop()`), which a
            -- pure term cannot express. The Calls layer lowers these to a value term plus a
            -- container-update statement, both reading the original container; assignment binds the
            -- target to the value first, then applies the update.
            if jsonNodeType? target == some "Name" then
              if let some (valueTerm, update) ← mutatingCallRhsLowering? value then
                let bindTarget ← bindOrAssignLocal (← getCode target `ident) valueTerm
                return ⟨mkNullNode #[bindTarget.raw, update.raw]⟩
            let rhs ←
              -- `x = a or b` binds the deciding *value*, not a `Bool` (`x = s or '0'` → the string).
              if jsonNodeType? value == some "BoolOp" then boolOpValueTerm value
              else if jsonUsesIOEffect value then
                inlineIOTerm value
              else
                let valueStx ← getCode value `term
                if jsonUsesMonadicEffect value then
                  `((← $valueStx))
                else
                  pure valueStx
            -- Ascribe to the value's inferred type when the inference pass stamped one (a `c[i] = v`
            -- into a float container: put an `Int` value into the container's `ℚ`/`Float` element).
            let rhs ← match ← stampedTypeSyntax? value with
              | some tyStx =>
                  -- A bare int literal must be re-emitted as an `OfNat` in the target type (`(0 : Float)`);
                  -- an ascribed `((0 : Int) : Float)` fails — there is no `Int → Float` coercion.
                  match jsonNodeType? value, value.getObjValAs? Int "value" with
                  | some "Constant", .ok i =>
                      let n := Syntax.mkNumLit (toString i.natAbs)
                      let lit : TSyntax `term ← if i < 0 then `(- $n:num) else pure ⟨n⟩
                      `(($lit : $tyStx))
                  | _, _ => `(($rhs : $tyStx))
              | none => pure rhs
            -- `self.X = v` inside a class method (where `self` is the `let mut` shadow) rebuilds
            -- `self` via record update. The `hasVar self` guard keeps top-level `obj.x = v`
            -- (no mutable `self` in scope) on its normal path.
            if let some attr := selfAttrTarget? target then
              if ← hasVar `self then
                return ← selfRecordUpdateDoElem attr rhs
            -- `obj.field = v` for a non-`self` receiver (a local record/node): record-update + reassign,
            -- rather than the invalid `let mut obj.field := v`.
            if jsonNodeType? target == some "Attribute" then
              let .ok recv := target.getObjVal? "value" | throwError s!"Attribute missing 'value': {target}"
              let .ok attr := target.getObjValAs? String "attr" | throwError s!"Attribute missing 'attr': {target}"
              return ← attrRecordUpdateDoElem recv attr rhs
                (target.getObjValAs? Bool "_unwrap_opt" == .ok true)
            match ← sliceTargetParts? target with
            | some (containerIdent, lowerTerm, upperTerm) =>
                -- `s[a:b] = repl` replaces the slice and reassigns the variable.
                let sliceSetIdent := mkIdent ``PastaLean.pySliceSet
                `(doElem| $containerIdent:ident := $sliceSetIdent $containerIdent $lowerTerm $upperTerm $rhs)
            | none =>
            match ← nestedSubscriptSetDoElem? target rhs with
            | some setStx =>
                -- `s[i] = v` (and nested `g[i][j] = v`) rebuild the container(s) and reassign.
                pure setStx
            | none =>
                let nameIdent ← getCode target `ident
                -- A cross-type rebind (`_ty` = `PyAny`) of an immutable `let` (a loop var, `for ch in
                -- s: ch = ord(ch)`) is shadowed with a fresh `let mut`. But a `let mut` slot — incl. a
                -- `let mut x : PyAny` from a first binding — is just reassigned (a `let mut` cannot be
                -- shadowed, and a `PyAny` slot coerces the new value in).
                let conflicting := (jsonFieldOption target "_ty").any
                  (fun t => t.getObjValAs? String "id" == .ok "PyAny")
                let shadow := conflicting && (← hasVar nameIdent.getId) && !(← isMutVar nameIdent.getId)
                let ty? ← if shadow then pure none else stampedTypeSyntax? target
                let bound ← bindOrAssignLocal nameIdent rhs ty? shadow
                -- Track whether this name now holds a set, so later `==`/`<=` on it use set semantics
                -- (order-independent) rather than the list-backed ones.
                setSetVar nameIdent.getId (← jsonIsSetExpr value)
                pure bound
    | _, _ => throwError s!"Unsupported syntax category for Assign node"

/--
`AnnAssign` represents Python's annotated assignment syntax (`x : T = v` or `x : T`).
The remaining declaration-only form is currently treated as a no-op in `do` blocks, and
rejected at top level until the backend grows explicit type-directed declarations.
-/
@[pygen "AnnAssign"]
def annAssignSyntax : (kind : SyntaxNodeKind) → Json →
    PygenM (TSyntax kind)
    | `command, json => do
        let .ok value? := json.getObjVal? "value" | throwError
          s!"AnnAssign node does not have a 'value' field or it is not a JSON value: {json}"
        match value? with
        | .null =>
            throwError "Declaration-only annotated assignments are not yet supported at top level."
        | _ =>
            let targetJson := Json.mkObj [("node_type", Json.str "Assign")]
            let json := targetJson.mergeObj json
            assignSyntax `command json
    | `doElem, json => do
        let .ok value? := json.getObjVal? "value" | throwError
          s!"AnnAssign node does not have a 'value' field or it is not a JSON value: {json}"
        match value? with
        | .null =>
            `(doElem| let _ := ())
        | _ =>
            let targetJson := Json.mkObj [("node_type", Json.str "Assign")]
            let json := targetJson.mergeObj json
            assignSyntax `doElem json
    | _, _ => throwError s!"Unsupported syntax category for AnnAssign node"

@[pygen "Return"]
def returnSyntax : (kind : SyntaxNodeKind) → Json →
    PygenM (TSyntax kind)
    | `doElem, json => withRealIfMarked json do
        let .ok value := json.getObjVal? "value" | throwError
          s!"Return node does not have a 'value' field or it is not a JSON value: {json}"
        match value with
        -- A bare `return` (Python `return`, i.e. `None`) → `return default`, which is `()` for a
        -- `Unit`/void function but also matches a (mis-)annotated non-`Unit` return type.
        | .null =>
            `(doElem| return default)
        | _ =>
            let valueStx ←
              -- `return a or b` returns the deciding *value* (`x or '0'` → the string), not a `Bool`.
              if jsonNodeType? value == some "BoolOp" then boolOpValueTerm value
              -- A call that both yields a value and mutates its receiver (`return heappop(h)`):
              -- the mutation is unobservable after a `return`, so return the value component.
              else if let some (valueTerm, _) ← mutatingCallRhsLowering? value then
                pure valueTerm
              else if jsonUsesIOEffect value then
                inlineIOTerm value
              else
                let s ← getCode value `term
                if jsonUsesMonadicEffect value then `((← $s:term)) else pure s
            -- In a boxed-return function, ascribe each value to `PyAny` so `try/catch` branches
            -- coerce individually (Lean would otherwise unify the branch types from the first return).
            let valueStx ← if (← getBoxReturnContext)
              then `(($valueStx : PastaLean.PyAny)) else pure valueStx
            -- A simple atom (`return x` / `return 42`) is always narrow, so return it directly.
            -- A wide expression placed directly after `return`, however, can be split onto the
            -- next line by the pretty-printer, which re-parses as `return` (Unit) followed by a
            -- stray term ("must be last element in a `do` sequence"). For those we bind the value
            -- to a temporary first and `return <ident>`, which always stays on one line.
            match jsonNodeType? value with
            | some "Name" | some "Constant" =>
                `(doElem| return $valueStx)
            | _ =>
                let retIdent := mkIdent (← freshName `__py_ret)
                let bind ← `(doElem| let $retIdent:ident := $valueStx)
                let ret ← `(doElem| return $retIdent)
                pure ⟨mkNullNode #[bind.raw, ret.raw]⟩
    | _, _ => throwError s!"Unsupported syntax category for Return node"

end PastaLean
