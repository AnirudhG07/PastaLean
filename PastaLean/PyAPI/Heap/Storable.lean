import PastaLean.PyAPI.Heap.Core

/-!
# Heap runtime — the `Storable` prism

`Storable V α` says how to store an `α` into the heap's value universe `V`: inject into `V`, project
back out (partial), with the round-trip law. `V` is a `semiOutParam` (determined by the heap, like
`MonadStateOf`'s state).

The **generic** pieces live here: the class, the `derive_storable%` command macro, and the
element-wise `projectList` helpers (for an element-wise container universe, e.g. the runtime test's
`arr`; the current `HeapPrelude` generator stores each container whole in one cell, so it does not
use these). The **concrete** `Storable Val …` instances (for `Int`/`String`/`Ref`/`List`/…) mention
the *generated* per-program `Val` constructors, so they are emitted into the generated program by the
`HeapPrelude` generator, not defined here.
-/

namespace PastaLean

/-- How to store an `α` into a value universe `V`: `inject`/`project` with the round-trip law. -/
class Storable (V : semiOutParam Type) (α : Type) where
  inject  : α → V
  project : V → Option α
  project_inject : ∀ a, project (inject a) = some a

/-- Project a list of universe values back to a `List α`, element by element. Fully generic in `V`.
Backs an element-wise container universe (one `V` cell per element, e.g. the runtime test's `arr`);
the current `HeapPrelude` generator stores each container whole in one cell, so it does not call this. -/
def projectList {V α : Type} [Storable V α] : List V → Option (List α)
  | []      => some []
  | v :: vs =>
    match Storable.project (α := α) v, projectList (V := V) vs with
    | some a, some as => some (a :: as)
    | _,      _       => none

theorem projectList_map_inject {V α : Type} [Storable V α] (xs : List α) :
    projectList (V := V) (xs.map Storable.inject) = some xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.map_cons, projectList, Storable.project_inject, ih]

open Lean Elab Command in
/-- `derive_storable% S` generates `Storable Val S` for a single-constructor structure `S`, mirroring
its native `Val` constructor (`Val.<s>`, the struct name with its first letter lowercased): `inject`
builds the constructor, `project` matches it (rejecting every other `Val` shape), and
`project_inject` is `rfl` by structure eta.

Run as a **command** *after* `Val` (not a `deriving` clause): with native per-struct fields the
`structure` must precede `Val`, so its instance — which needs `Val` — cannot be produced at
definition time. `Val` is referenced by raw name so it resolves in the generated program's scope. -/
elab "derive_storable% " structId:ident : command => do
  let env ← getEnv
  -- Resolve the structure name honoring the current namespace: codegen wraps user classes in a
  -- `namespace PastaLean.User.<path>`, so the bare ident (`Counter`) must be qualified to the
  -- enclosing namespace (`PastaLean.User.Root.Counter`) to be found.
  let currNs ← getCurrNamespace
  let structName :=
    if isStructure env structId.getId then structId.getId
    else currNs ++ structId.getId
  unless isStructure env structName do
    throwError "derive_storable%: '{structName}' is not a structure"
  let fields := getStructureFields env structName
  let ctorStr := match structName.getString!.toList with
    | c :: rest => String.ofList (c.toLower :: rest)
    | []        => structName.getString!
  let valId := mkIdent `Val
  let ctorId := mkIdent (Name.mkStr `Val ctorStr)
  let s := mkIdent `s
  let injFields ← fields.mapM fun f => `($s.$(mkIdent f):ident)
  let binders := (Array.range fields.size).map fun i => mkIdent (Name.mkSimple s!"a{i}")
  let injectTerm ← `(fun $s => $ctorId $injFields*)
  -- `project` rebuilds a NAMED structure literal (not the anonymous `⟨…⟩` constructor) so it resolves
  -- inherited fields by name — anonymous flattening mismatches an `extends` structure's shape.
  let projFields ← (fields.zip binders).mapM fun (f, b) =>
    `(Lean.Parser.Term.structInstField| $(mkIdent f):ident := $b)
  -- When `Val` has a single constructor (a one-class program) the catch-all `| _ => none` is a
  -- redundant match alternative (a hard error), so omit it in that case.
  let valSingleCtor := match env.find? `Val with
    | some (.inductInfo iv) => iv.ctors.length == 1
    | _ => false
  let projectTerm ← if valSingleCtor then
      `(fun | $ctorId $binders* => some ({ $projFields:structInstField,* } : $structId))
    else
      `(fun | $ctorId $binders* => some ({ $projFields:structInstField,* } : $structId) | _ => none)
  -- `cases a` exposes the constructor so the `project`/`inject` match and field projections reduce;
  -- plain `rfl` gets stuck for recursive (`Option Self`) and `extends` structures.
  elabCommand (← `(instance : Storable $valId $structId where
      inject := $injectTerm
      project := $projectTerm
      project_inject := by intro a; cases a <;> rfl))

end PastaLean
