import Mathlib
import PastaLean.Codegen
import PastaLean.PyGens.Basic
import PastaLean.PyGens.Core.Utils
import PastaLean.PyGens.UseCases.FuncDef

open Lean Meta Elab Term Qq Std

namespace PastaLean

open Lean.Parser.Term
open Lean.Parser.Command

/-!
  Translates Python `class` definitions to a Lean `structure` plus namespaced method `def`s.

  * Fields (`self.x = …`, class-level `x = …`) become structure fields, types from
    `annotate_python`/parameter annotations (defaulting to `Int`).
  * `__init__` becomes the smart constructor `C.mk`, built by the same `self`-threading machinery
    as a mutator (start from `default`, apply each `self.x = …`, return `self`), so partial and
    locally-computed `__init__`s both work.
  * A non-mutating method is a pure `def C.method (self : C) … `; a mutator returns the rebuilt
    `self` (value semantics — see the module plan for the aliasing caveat).
  * Methods are emitted with fully-qualified names (`def C.method`), so `obj.method` dot-notation
    resolves without a `namespace` wrapper.
-/

/-- Names of `__init__` parameters that default to `None`; the fields they initialise are typed
`Option ClassName` (the recursive node pattern, `TreeNode.left`/`ListNode.next`). -/
def noneDefaultParamNames (initJson : Json) : List String := Id.run do
  let args := ((initJson.getObjVal? "args").toOption.bind
    (fun a => (a.getObjValAs? (Array Json) "args").toOption)).getD #[]
  let defaults := functionParamDefaults initJson
  let offset := args.size - defaults.size
  let mut names := []
  for i in [0:args.size] do
    if i ≥ offset then
      let d := defaults[i - offset]!
      if d.getObjValAs? String "node_type" == .ok "Constant" && (d.getObjVal? "value").toOption == some Json.null then
        if let .ok nm := args[i]!.getObjValAs? String "arg" then names := nm :: names
  return names

/-- A `None` literal (`Constant` whose value is JSON null). -/
private def isNoneConstJson (j : Json) : Bool :=
  j.getObjValAs? String "node_type" == .ok "Constant" && (j.getObjVal? "value").toOption == some Json.null

/-- A list whose elements are all `None` — `[None, None]` or `[None] * k` (`[None for _ in …]`) — the
initial value of a recursive node's children array (a Trie's `children`, a segment tree's kids). -/
private partial def isListOfNoneJson (j : Json) : Bool :=
  match j.getObjValAs? String "node_type" with
  | .ok "List" =>
      let elts := (j.getObjValAs? (Array Json) "elts").toOption.getD #[]
      !elts.isEmpty && elts.all isNoneConstJson
  | .ok "BinOp" =>
      j.getObjValAs? String "op" == .ok "mul"
        && ((j.getObjVal? "left").toOption.any isListOfNoneJson
            || (j.getObjVal? "right").toOption.any isListOfNoneJson)
  | .ok "ListComp" => (j.getObjVal? "elt").toOption.any isNoneConstJson
  | _ => false

/-- One structure field `name : Type [:= default]` from a `{name, annotation?, default?}` entry. A
field with no annotation whose `__init__` param is in `noneParams` (defaults to `None`) — or which is
directly assigned `None` / `[None]*k` — is typed `Option className` / `List (Option className)` (the
recursive node pattern). -/
def classStructFieldSyntax (className : String) (noneParams : List String) (fieldJson : Json) :
    PygenM (TSyntax ``Lean.Parser.Command.structSimpleBinder) := do
  let .ok fname := fieldJson.getObjValAs? String "name" | throwError
    s!"Class field is missing a 'name': {fieldJson}"
  let fid := mkIdent fname.toName
  let intTy : TSyntax `term := mkIdent ``Int
  -- A field the per-variable pass marked `_real` (holds an `ℝ` value, e.g. a trained weight) types
  -- its annotation under real-context so `float`/`list[float]` → `ℝ`/`List ℝ`.
  let isRealField := (← getNumericMode) == .exact && fieldJson.getObjValAs? Bool "_real" == .ok true
  -- The field's initial value is the `__init__` param assigned to it (`self.left = left`).
  let initFromNoneParam : Bool := match (fieldJson.getObjVal? "init").toOption with
    | some initJson =>
        (initJson.getObjValAs? String "node_type" == .ok "Name")
        && (match initJson.getObjValAs? String "id" with | .ok nm => noneParams.contains nm | _ => false)
    | none => false
  -- No annotation: a `None`-default param → `Option ClassName`; else read the type off what
  -- `__init__` assigns (`self.c = [0] * n` → `List Int`); only then fall back to `Int`.
  let ty : TSyntax `term ← withRealContext isRealField do
    match (fieldJson.getObjVal? "annotation").toOption with
    | some (.null) | none =>
        if initFromNoneParam then `(Option $(mkIdent className.toName))
        else match (fieldJson.getObjVal? "init").toOption with
          -- A DIRECT `self.x = None` (not via a None-default param) is `Option ClassName`, and
          -- `self.children = [None]*k` is `List (Option ClassName)` — the recursive-node pattern. Both
          -- otherwise mis-infer to `Unit` / `List Unit` from the bare `None` literal.
          | some initJson =>
              if isNoneConstJson initJson then `(Option $(mkIdent className.toName))
              else if isListOfNoneJson initJson then `(List (Option $(mkIdent className.toName)))
              else pure ((← pyTypeSyntax? (TypeInfer.ofValue initJson)).getD intTy)
          | none => pure intTy
    | some annJson => pure ((← functionArgTypeSyntax? annJson).getD intTy)
  match (fieldJson.getObjVal? "default").toOption with
  | some (.null) | none => `(structSimpleBinder| $fid:ident : $ty)
  | some defJson =>
      let defCode ← getCode defJson `term
      `(structSimpleBinder| $fid:ident : $ty := $defCode)

/-- Build the `Id.run do` body of a `self`-threading routine (`__init__` or a mutator method):
declare a mutable `self` (the parameter for a mutator, or `default` for a constructor), lower the
body (where `self.x = …` becomes `self := { self with x := … }` — see `Core/Assign.lean`), then
`return self`. Wrapped in a lambda over `argInfos`. -/
def classSelfThreadingValue (argInfos : Array (TSyntax `ident × Option (TSyntax `term)))
    (classTyTerm : TSyntax `term) (bodyElems : Array Json) (selfIsParam : Bool) :
    PygenM (TSyntax `term) := withFreshVariables do
  let selfId := mkIdent `self
  addVar `self
  let selfDecl ← if selfIsParam then `(doElem| let mut $selfId:ident := $selfId:ident)
                 else `(doElem| let mut $selfId:ident : $classTyTerm := default)
  -- A mutator method may also reassign/augment its OWN parameters (`x += x & -x` in a Fenwick
  -- `update`), so each mutated param needs a `let mut` shadow — exactly as free functions do. Without
  -- it the immutable binder throws "`x` cannot be mutated" and the whole method fails to elaborate.
  let mut paramPrelude : Array (TSyntax `doElem) := #[]
  for (argIdent, _) in argInfos do
    if argIdent.getId != `self && bodyElems.any (fun b => jsonMutatesName b argIdent.getId.toString) then
      addVar argIdent.getId
      paramPrelude := paramPrelude.push (← `(doElem| let mut $argIdent:ident := $argIdent))
  let bodyStxArray ← monadicFunctionBodySyntax bodyElems
  let idRun := mkIdent ``Id.run
  let core ← `($idRun do
      $selfDecl:doElem
      $[$paramPrelude:doElem]*
      $[$bodyStxArray:doElem]*
      return $selfId:term)
  let mut result := core
  for (argIdent, ty?) in argInfos.toList.reverse do
    result ← match ty? with
      | some ty => `(fun ($argIdent : $ty) ↦ $result)
      | none => `(fun $argIdent ↦ $result)
  pure result

/-- Body of a VALUE+MUTATE method — mutates `self` AND returns a value (union-find `union`). Like
`classSelfThreadingValue` but each `return v` is emitted as `return (v, self)` (via `valueMutatorRef`),
so the method returns `(result × Self)`; the caller binds both, reassigns the receiver, and uses the
result. A fall-through returns `(default, self)`. -/
def classValueMutatorValue (argInfos : Array (TSyntax `ident × Option (TSyntax `term)))
    (bodyElems : Array Json) : PygenM (TSyntax `term) := withFreshVariables do
  let selfId := mkIdent `self
  addVar `self
  let selfDecl ← `(doElem| let mut $selfId:ident := $selfId:ident)
  let mut paramPrelude : Array (TSyntax `doElem) := #[]
  for (argIdent, _) in argInfos do
    if argIdent.getId != `self && bodyElems.any (fun b => jsonMutatesName b argIdent.getId.toString) then
      addVar argIdent.getId
      paramPrelude := paramPrelude.push (← `(doElem| let mut $argIdent:ident := $argIdent))
  let old ← valueMutatorRef.get
  valueMutatorRef.set true
  let bodyStxArray ← monadicFunctionBodySyntax bodyElems
  valueMutatorRef.set old
  let idRun := mkIdent ``Id.run
  -- A trailing `return v` already emits `return (v, self)`; only supply the fall-through terminal
  -- when the body doesn't itself end in a `return` (else the two returns collide in the do-sequence).
  let endsInReturn := bodyElems.back?.any (jsonNodeType? · == some "Return")
  let core ← if endsInReturn then
      `($idRun do
        $selfDecl:doElem
        $[$paramPrelude:doElem]*
        $[$bodyStxArray:doElem]*)
    else
      `($idRun do
        $selfDecl:doElem
        $[$paramPrelude:doElem]*
        $[$bodyStxArray:doElem]*
        return (default, $selfId:term))
  let mut result := core
  for (argIdent, ty?) in argInfos.toList.reverse do
    result ← match ty? with
      | some ty => `(fun ($argIdent : $ty) ↦ $result)
      | none => `(fun $argIdent ↦ $result)
  pure result

/-- If `__init__`'s body is purely straight-line `self.X = expr` (no control flow, no locals, and
no value reading `self`), return the `(field, valueJson)` pairs in order — the case that lowers to
a plain record literal (which honors structure field defaults for unassigned fields). `none`
otherwise (then the constructor threads a mutable `self` from `default`). -/
def initFieldAssignments? (bodyElems : Array Json) : Option (Array (String × Json × Bool)) := Id.run do
  let mut out := #[]
  for s in bodyElems do
    if jsonNodeType? s != some "Assign" then return none
    let some target := (s.getObjVal? "target").toOption | return none
    let some attr := selfAttrTarget? target | return none
    let some value := (s.getObjVal? "value").toOption | return none
    if jsonReferencesName value "self" then return none
    -- carry the per-field `_real` stamp so a real field's initial value is lowered in real-context
    out := out.push (attr, value, s.getObjValAs? Bool "_real" == .ok true)
  return some out

/-- The smart constructor `C.new` from `__init__`. A straight-line `__init__` becomes a record
literal `{ field := … }` (so unassigned fields take their structure defaults); anything else threads
a mutable `self` from `default`. Named `new` (not `mk`) to avoid clashing with the structure's
auto-generated `C.mk` field constructor. -/
def classInitConstructor (className : String) (initJson : Json) (hasRealField : Bool) :
    PygenM (TSyntax `command) := do
  let mkIdentC := mkIdent (Name.mkStr className.toName "new")
  let classTy : TSyntax `term := mkIdent className.toName
  let argInfos := (← functionArgInfos initJson).drop 1   -- drop the leading `self`
  let bodyElems ← functionBodyElems initJson
  let defaults := functionParamDefaults initJson
  match initFieldAssignments? bodyElems with
  | some pairs =>
      -- Straight-line `__init__` → a record literal. `__init__` defaults become `optParam` binders on
      -- `C.new`, so `TreeNode(x)` fills `left`/`right` instead of being a partial application.
      withFreshVariables do
        let fields ← pairs.mapM fun (attr, valJson, isReal) => do
          let v ← if isReal then withRealContext true (getCode valJson `term) else getCode valJson `term
          `(Lean.Parser.Term.structInstField| $(mkIdent attr.toName):ident := $v)
        let recordBody : TSyntax `term ← `(({ $fields:structInstField,* } : $classTy))
        if defaults.isEmpty then
          let mut result := recordBody
          for (argIdent, ty?) in argInfos.toList.reverse do
            result ← match ty? with
              | some ty => `(fun ($argIdent : $ty) ↦ $result)
              | none => `(fun $argIdent ↦ $result)
          -- `result` is `fun (n : Int) ↦ …` once there are params, so the ascription must be the
          -- arrow type `Int → C`, not `C`. No params → the record itself, ascribed `C`; an
          -- unannotated param → no full arrow, so emit without ascription and let Lean infer.
          let fullTy? ← if argInfos.isEmpty then pure (some classTy)
                        else functionArrowTypeSyntax? argInfos classTy
          match fullTy? with
          | some ty => if hasRealField then `(command| noncomputable def $mkIdentC : $ty := $result)
                       else `(command| def $mkIdentC : $ty := $result)
          | none => if hasRealField then `(command| noncomputable def $mkIdentC := $result)
                    else `(command| def $mkIdentC := $result)
        else
          let offset := argInfos.size - defaults.size
          let binders ← (Array.range argInfos.size).mapM fun i => do
            let (argIdent, ty?) := argInfos[i]!
            let d? := if i ≥ offset then some defaults[i - offset]! else none
            -- Unannotated `None`-default param is `Option ClassName` (matches the field type).
            let tyStx ← match ty? with
              | some t => pure t
              | none =>
                  if d?.any (fun d => d.getObjValAs? String "node_type" == .ok "Constant"
                                      && (d.getObjVal? "value").toOption == some Json.null)
                  then `(Option $classTy) else `(_)
            match d? with
            | some d => let dCode ← getCode d `term
                        `(Lean.Parser.Term.bracketedBinderF| ($argIdent : $tyStx := $dCode))
            | none => `(Lean.Parser.Term.bracketedBinderF| ($argIdent : $tyStx))
          if hasRealField then `(command| noncomputable def $mkIdentC $binders* : $classTy := $recordBody)
          else `(command| def $mkIdentC $binders* : $classTy := $recordBody)
  | none =>
      let valueStx ← withFreshVariables do
        withCurrentClass className [] do
          classSelfThreadingValue argInfos classTy bodyElems (selfIsParam := false)
      let mkDef : TSyntax `term → PygenM (TSyntax `command) := fun ty =>
        if hasRealField then `(command| noncomputable def $mkIdentC : $ty := $valueStx)
        else `(command| def $mkIdentC : $ty := $valueStx)
      match ← functionArrowTypeSyntax? argInfos classTy with
      | some fullTy => mkDef fullTy
      | none => if hasRealField then `(command| noncomputable def $mkIdentC := $valueStx)
                else `(command| def $mkIdentC := $valueStx)

/-- True when the method's body calls itself (`self.find(…)`). Lean cannot show termination for
path-compression / DFS recursion, so such a method is emitted `partial` — and without `@[simp]`,
which on a recursive def is an unfolding hazard. -/
partial def methodIsSelfRecursive (mName : String) (json : Json) : Bool :=
  let selfCall :=
    jsonNodeType? json == some "Attribute"
    && json.getObjValAs? String "attr" == .ok mName
    && (match (json.getObjVal? "value").toOption with
        | some v => jsonNodeType? v == some "Name" && v.getObjValAs? String "id" == .ok "self"
        | none => false)
  selfCall || (match json with
    | .arr xs => xs.any (methodIsSelfRecursive mName)
    | .obj fs => fs.toList.any (fun (_, v) => methodIsSelfRecursive mName v)
    | _ => false)

/-- One method `def C.method …`. A getter is a pure `functionValueSyntax`; a mutator returns the
rebuilt `self`. Static/class methods drop the leading `self`/`cls`. -/
def classMethodDef (className : String) (info : ClassInfo) (m : Json) : PygenM (Array (TSyntax `command)) := do
  let .ok mName := m.getObjValAs? String "name" | throwError
    s!"Class method is missing a 'name': {m}"
  let defIdent := mkIdent (Name.mkStr className.toName mName)
  let classTy : TSyntax `term := mkIdent className.toName
  let allArgInfos ← functionArgInfos m
  let bodyElems ← functionBodyElems m
  let isStatic := info.staticmethods.contains mName
  let isClassM := info.classmethods.contains mName
  let isMutator := info.mutators.contains mName && !isStatic && !isClassM
  let isValueMutator := info.valueMutators.contains mName && !isStatic && !isClassM
  let argInfos : Array (TSyntax `ident × Option (TSyntax `term)) :=
    if isStatic then allArgInfos
    else if isClassM then allArgInfos.drop 1
    else #[(mkIdent `self, some classTy)] ++ allArgInfos.drop 1
  -- Params with Python defaults become `optParam` binders; then the body is built un-wrapped
  -- (empty argInfos), reading `self`/params from the binders.
  let binders? ← functionParamBinders? m argInfos
  let bodyArgInfos := if binders?.isSome then #[] else argInfos
  let valueStx ← withCurrentClass className info.mutators do
    if isMutator then
      classSelfThreadingValue bodyArgInfos classTy bodyElems (selfIsParam := true)
    else if isValueMutator then
      classValueMutatorValue bodyArgInfos bodyElems
    else
      functionValueSyntax bodyArgInfos bodyElems
  -- A method the per-variable pass stamped `_real_fn` (produces/handles an `ℝ` transcendental)
  -- must be `noncomputable` in exact mode, exactly like a free function.
  let nc := (← getNumericMode) == .exact && m.getObjValAs? Bool "_real_fn" == .ok true
  let isRecursive := bodyElems.any (methodIsSelfRecursive mName)
  let cmd ← match binders? with
    | some binders =>
        if isRecursive then `(command| partial def $defIdent $binders* := $valueStx)
        else if nc then `(command| noncomputable def $defIdent $binders* := $valueStx)
        else `(command| def $defIdent $binders* := $valueStx)
    | none =>
        if isRecursive then `(command| partial def $defIdent := $valueStx)
        else if nc then `(command| noncomputable def $defIdent := $valueStx)
        else `(command| def $defIdent := $valueStx)
  let finalCmd ← applyPrivacy mName cmd
  -- Prove-version (exact) methods get `@[simp]` (and `taste_ingr` when a pure, computable, non-
  -- `assert` value method), so `taste?` can unfold them — mirroring free functions in `FuncDef`.
  -- Never the `'rn` twin (approx mode is skipped). Methods are emitted as plain `def`s, not
  -- `partial`, so there's no recursive-`@[simp]` hazard.
  if (← getNumericMode) == .exact && !isRecursive then
    let isEffectful := bodyNeedsExceptionMonad bodyElems || bodyNeedsIOMonad bodyElems
    let hasAssert := bodyElems.any (jsonNodeType? · == some "Assert")
    let attrCmd ← if !isEffectful && !hasAssert && !nc
      then `(command| attribute [simp, taste_ingr] $defIdent)
      else `(command| attribute [simp] $defIdent)
    return #[finalCmd, attrCmd]
  else
    return #[finalCmd]

/-- A `__repr__`/`__str__` method becomes a `PyPrintable` instance, so `print(obj)` / `str(obj)`
use it (overriding the `deriving Repr` fallback). -/
def classPrintableInstance (className : String) (m : Json) : PygenM (TSyntax `command) := do
  let classTy : TSyntax `term := mkIdent className.toName
  let bodyElems ← functionBodyElems m
  let lam ← withCurrentClass className [] do
    functionValueSyntax #[(mkIdent `self, some classTy)] bodyElems
  let printableC ← `($(mkIdent ``PastaLean.PyPrintable) $classTy)
  `(command| instance : $printableC where pyStringify := $lam)

/-- Operator dunders become the runtime operator typeclass instances the generated code dispatches
through: `__add__`→`PyHAdd` (used by `+ₚ`), `__sub__`→`PyHSub`, `__mul__`→`PyHMul`, `__eq__`→`BEq`
(used by `==`). Returns `none` for a non-operator method name. -/
def classDunderInstance? (className : String) (m : Json) : PygenM (Option (TSyntax `command)) := do
  let .ok mName := m.getObjValAs? String "name" | return none
  let classTy : TSyntax `term := mkIdent className.toName
  let bodyElems ← functionBodyElems m
  let argInfos := #[(mkIdent `self, some classTy)] ++ (← functionArgInfos m).drop 1
  let lam ← withCurrentClass className [] do functionValueSyntax argInfos bodyElems
  match mName with
  | "__add__" => some <$> `(command| instance : $(mkIdent ``PastaLean.PyHAdd) $classTy $classTy $classTy where hAdd := $lam)
  | "__sub__" => some <$> `(command| instance : $(mkIdent ``PastaLean.PyHSub) $classTy $classTy $classTy where hSub := $lam)
  | "__mul__" => some <$> `(command| instance : $(mkIdent ``PastaLean.PyHMul) $classTy $classTy $classTy where hMul := $lam)
  | "__eq__"  => some <$> `(command| instance : BEq $classTy where beq := $lam)
  | _ => return none

@[pygen "ClassDef"]
def classDefSyntax : (kind : SyntaxNodeKind) → Json → PygenM (TSyntax kind)
  | `command, json => do
      let .ok rawName := json.getObjValAs? String "name" | throwError
        s!"ClassDef node is missing a 'name': {json}"
      -- Run-twin: the class is emitted as `CNN'rn`; its methods/constructor follow (`CNN'rn.new`,
      -- `CNN'rn.forward`) since they are built from this name, and references to `CNN` are suffixed
      -- by the Name pygen + the constructor/method call sites.
      let name ← withRunSuffix rawName
      let nameId := mkIdent name.toName
      let .ok fields := json.getObjValAs? (Array Json) "fields" | throwError
        s!"ClassDef node is missing a 'fields' array: {json}"
      let .ok methods := json.getObjValAs? (Array Json) "methods" | throwError
        s!"ClassDef node is missing a 'methods' array: {json}"
      let mutators := (json.getObjValAs? (Array String) "mutators").toOption.getD #[]
      let valueMutators := (json.getObjValAs? (Array String) "value_mutators").toOption.getD #[]
      let staticmethods := (json.getObjValAs? (Array String) "staticmethods").toOption.getD #[]
      let classmethods := (json.getObjValAs? (Array String) "classmethods").toOption.getD #[]
      let bases := (json.getObjValAs? (Array Json) "bases").toOption.getD #[]

      -- Record class metadata so later top-level statements can dispatch instantiation/methods.
      let methodNames := methods.filterMap (·.getObjValAs? String "name" |>.toOption)
      let info : ClassInfo := {
        methods := methodNames.toList
        mutators := mutators.toList
        valueMutators := valueMutators.toList
        staticmethods := staticmethods.toList
        classmethods := classmethods.toList }
      registerClass name info

      let hasEq := methodNames.contains "__eq__"
      -- A class with an `ℝ` field (exact mode) can't derive a COMPUTABLE `BEq` (`Real.decidableEq`
      -- is noncomputable; `Real`'s only `Repr` is `unsafe`), and its constructor builds an `ℝ`
      -- struct → `noncomputable`.
      let hasRealField := (← getNumericMode) == .exact
        && fields.any (fun f => f.getObjValAs? Bool "_real" == .ok true)
      -- Everything the structure derives, folded into one `deriving` clause: `Inhabited` always;
      -- `Repr` unless a real field (no computable `Repr`); `BEq` unless the class supplies a custom
      -- `__eq__` (which becomes its own `BEq` instance) or has a real field. Each class name is
      -- wrapped as a `derivingClass` node (an empty `@[expose]?` slot + the class term).
      let mkDeriv (n : Name) : TSyntax ``Lean.Parser.Command.derivingClass :=
        ⟨mkNode ``Lean.Parser.Command.derivingClass #[mkNullNode, (mkIdent n).raw]⟩
      let derivs : Array (TSyntax ``Lean.Parser.Command.derivingClass) :=
        #[mkDeriv ``Inhabited]
          ++ (if hasRealField then #[] else #[mkDeriv ``Repr])
          ++ (if hasEq || hasRealField then #[] else #[mkDeriv ``BEq])
      -- The structure carries the class docstring as its `/-- … -/` doc comment (when present)
      -- and `extends Base` for a single base.
      let noneParams :=
        (methods.find? (·.getObjValAs? String "name" == .ok "__init__")).elim [] noneDefaultParamNames
      let fieldBinders ← fields.mapM (classStructFieldSyntax name noneParams)
      let baseId? : Option (TSyntax `ident) ←
        match bases[0]? with
        | some baseJson =>
            match baseJson.getObjValAs? String "id" with
            | .ok bid => pure (some (mkIdent bid.toName))
            | _ => throwError s!"Class base is not a simple Name: {baseJson}"
        | none => pure none
      -- A leading class docstring → `/-- … -/`. `-/` inside the text is defanged so it can't close
      -- the comment early.
      let docStx? : Option (TSyntax ``Lean.Parser.Command.docComment) :=
        match (json.getObjValAs? String "docstring").toOption with
        | some text =>
            let body := (text.trimAscii).toString.replace "-/" "- /"
            some ⟨mkNode ``Lean.Parser.Command.docComment #[mkAtom "/--", mkAtom (body ++ " -/")]⟩
        | none => none
      let structCmd ← match docStx?, baseId? with
        | some doc, some baseId =>
            `(command| $doc:docComment structure $nameId:ident extends $baseId:ident where
                $[$fieldBinders]* deriving $derivs,*)
        | some doc, none =>
            `(command| $doc:docComment structure $nameId:ident where
                $[$fieldBinders]* deriving $derivs,*)
        | none, some baseId =>
            `(command| structure $nameId:ident extends $baseId:ident where
                $[$fieldBinders]* deriving $derivs,*)
        | none, none =>
            `(command| structure $nameId:ident where
                $[$fieldBinders]* deriving $derivs,*)

      let mut members : Array (TSyntax `command) := #[structCmd]
      -- A class instance is a non-`None` object, so Python truthiness on it is always `true`
      -- (`if node:` / `while node:`); a nullable cursor is `Option C`, whose own `PyTruthy` handles
      -- the `none` case. Without this, `if node:` on a bare-typed `ListNode`/`TreeNode` has no instance.
      members := members.push
        (← `(command| instance : PastaLean.PyTruthy $nameId where truthy _ := true))
      -- Lift a bare node into `Option C` so a nullable cursor (`curr = head`, later `curr = curr.next`)
      -- ascribed `Option C` takes its bare initial value, and `curr = ListNode(...)` reassignments fit.
      members := members.push
        (← `(command| instance : Coe $nameId (Option $nameId) := ⟨some⟩))

      -- Constructor (from `__init__`), operator/printable dunders, and the remaining methods.
      let mut hasInit := false
      for m in methods do
        let .ok mName := m.getObjValAs? String "name" | throwError
          s!"Class method is missing a 'name': {m}"
        if mName == "__init__" then
          hasInit := true
          members := members.push (← classInitConstructor name m hasRealField)
        else if mName == "__str__" || (mName == "__repr__" && !methodNames.contains "__str__") then
          -- Prefer `__str__` for `pyStringify` when both are defined (Python `str()`/`print`).
          members := members.push (← classPrintableInstance name m)
        else if mName == "__repr__" then
          pure ()  -- shadowed by `__str__`

        else if let some inst ← classDunderInstance? name m then
          members := members.push inst
        else
          members := members ++ (← classMethodDef name info m)
      -- No `__init__`: `C()` builds an all-defaults instance (fields use their declared defaults).
      unless hasInit do
        members := members.push (← `(command| def $(mkIdent (Name.mkStr name.toName "new")) : $nameId := default))
      return ⟨mkNullNode (members.map (·.raw))⟩
  | kind, _ => throwError
      s!"ClassDef is only supported at command (top-level) position, not '{kind}'."

end PastaLean
