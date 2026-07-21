import PastaLean.PyGens.UseCases.ClassDef

/-!
# `HeapPrelude` — the generated value universe (`--heap`)

Under reference semantics the driver injects one `HeapPrelude` node at the front of the module. It
emits, **in this order** (a hard constraint — each part references the previous):

1. every class `structure` (pulled out of `ClassDef`, which skips it in heap mode);
2. the per-program `Val` inductive — one native constructor per class (fields at their heap types)
   plus one per distinct heap container cell type, and NO primitive constructors (Python never
   heap-allocates a bare primitive), so `inject`/`project` round-trip by `rfl`;
3. the concrete `Storable Val …` instances and one `derive_storable%` per class.

The `Val` inductive and the `Storable` instances are built as text and parsed (their
constructor-heavy syntax is awkward to assemble by quotation); the `structure`s reuse
`classStructCommand`.
-/

open Lean

namespace PastaLean

/-- Parse a generated command from text into `Syntax`. The backend environment has the `Val`-free
parsers plus PastaLean's `derive_storable%`, so all generated command forms parse here. -/
def parseHeapCommand (src : String) : PygenM (TSyntax `command) := do
  match Lean.Parser.runParserCategory (← getEnv) `command src with
  | .ok stx => return ⟨stx⟩
  | .error e => throwError s!"HeapPrelude: could not parse generated command:\n{src}\n\n{e}"

/-- Erase macro scopes from every identifier in a syntax tree. Field types come from quotations
(`classFieldNameType`), so their `Option`/`List`/… idents are hygienic and would otherwise
pretty-print with a `✝` dagger that fails to re-parse. -/
partial def eraseHeapScopes : Syntax → Syntax
  | .ident info rawVal val pre => .ident info rawVal val.eraseMacroScopes pre
  | .node info kind args => .node info kind (args.map eraseHeapScopes)
  | s => s

/-- Render a type term to a string for embedding in the generated `Val` inductive text. -/
def renderHeapType (ty : TSyntax `term) : PygenM String := do
  return (← Lean.PrettyPrinter.ppCategory `term (eraseHeapScopes ty.raw)).pretty 10000

/-- The field list of a class's `Val` constructor, matching what `derive_storable%` sees via
`getStructureFields` on the emitted structure. A subclass's `extends Base` shows up there as a single
bundled `toBase : Base` field (NOT the flattened base fields), so we mirror that. Each entry is
`(fieldName, type)`.

`rawName` locates the class in the (raw-named) `classes` array; `effName` is the name the twin's
`structure` was actually emitted under (`Counter` in exact mode, `Counter'rn` in the runnable twin),
used for field typing so self-referential `None`-default fields (`.opt (.cls effName)`) render the
SAME type the struct did — otherwise the `Val` constructor and the structure disagree and
`derive_storable%` fails. In single-mode builds `rawName == effName`. -/
def resolveFullFields (classes : Array Json) (rawName effName : String) :
    PygenM (Array (String × TSyntax `term)) := do
  let some cj := classes.find? (fun c => c.getObjValAs? String "name" == .ok rawName)
    | return #[]
  let bases := (cj.getObjValAs? (Array Json) "bases").toOption.getD #[]
  let baseName? := bases[0]?.bind (fun b => (b.getObjValAs? String "id").toOption)
  -- `extends Base` becomes the `toBase : Base` field that `getStructureFields` reports first.
  -- Suffix the base like the class's own name, so the `'rn` twin's field is `toBase : Base'rn`,
  -- matching the emitted `structure …'rn extends Base'rn` (else `derive_storable%` disagrees).
  let baseField : Array (String × TSyntax `term) ← match baseName? with
    | some bn => do
        let bn' ← withRunSuffix bn
        pure #[("toBase", (mkIdent bn'.toName : TSyntax `term))]
    | none    => pure #[]
  let fields := (cj.getObjValAs? (Array Json) "fields").toOption.getD #[]
  let methods := (cj.getObjValAs? (Array Json) "methods").toOption.getD #[]
  let noneParams :=
    (methods.find? (·.getObjValAs? String "name" == .ok "__init__")).elim [] noneDefaultParamNames
  let mut own := #[]
  for f in fields do
    let .ok fname := f.getObjValAs? String "name" | throwError "HeapPrelude: field missing 'name'"
    let (_, ty) ← classFieldNameType effName noneParams f
    own := own.push (fname, ty)
  return baseField ++ own

/-- A class's `Val` constructor name: its name with the first character lowercased — matching the
constructor `derive_storable%` targets. -/
def valCtorName (className : String) : String :=
  match className.toList with
  | c :: rest => String.ofList (c.toLower :: rest)
  | []        => className

/-- Wrap `s` in parens if it contains a space, so it nests as an argument (`List (Ref Point)`). -/
def parenIfSpaced (s : String) : String :=
  if s.any (· == ' ') then "(" ++ s ++ ")" else s

/-- A valid `Val` constructor name derived from a container cell-type string (`List Int` → `hc_List_Int`). -/
def mangleContainerCtor (s : String) : String :=
  "hc_" ++ String.ofList (s.toList.map (fun c => if c.isAlphanum then c else '_'))

/-- If `t` is a mutable container, the heap CELL type (what its `Ref` points to) rendered as a Lean
type string; else `none`. Element types are heap-typed, so objects/inner-containers become `Ref`s.
`list[int]` → "List Int"; `list[Point]` → "List (Ref Point)"; `dict[str,int]` → "Std.HashMap String Int". -/
partial def containerCellType? (t : TypeInfer.PyType) : PygenM (Option String) := do
  match t with
  | .list e | .set e => return some ("List " ++ parenIfSpaced (← renderHeapType (← heapElemTypeSyntax e)))
  | .dict k v =>
      return some ("Std.HashMap " ++ parenIfSpaced (← renderHeapType (← heapTypeSyntax k))
                     ++ " " ++ parenIfSpaced (← renderHeapType (← heapElemTypeSyntax v)))
  | .opt inner => containerCellType? inner
  | _ => return none

@[pygen "HeapPrelude"]
def heapPreludeSyntax : (kind : SyntaxNodeKind) → Json → PygenM (TSyntax kind)
  | `command, json => do
      let classes := (json.getObjValAs? (Array Json) "classes").toOption.getD #[]
      -- Under `--mode both` the driver stamps `emit_twin`: render BOTH the exact and the runnable
      -- `'rn` twin of every struct / `Val` constructor / `Storable`, all into ONE `Val` universe (each
      -- twin only injects/projects its own constructors, and a program runs exactly one twin). One
      -- `Val` — rather than two suffixed universes — keeps every `mkIdent \`Val` site and
      -- `derive_storable%` untouched. Otherwise render just the single ambient mode.
      let emitTwin := (json.getObjValAs? Bool "emit_twin").toOption.getD false
      let savedMode ← getNumericMode
      let savedSuffix ← getRunSuffix
      let modes : List (NumericMode × String) :=
        if emitTwin then [(.exact, ""), (.approx, "'rn")] else [(savedMode, savedSuffix)]
      let mut cmds : Array (TSyntax `command) := #[]

      -- 0. Distinct mutable-container cell types across all class fields AND local/param annotations,
      -- over every mode, deduped. A cell type identical across modes (`List Int`) yields one shared
      -- constructor + `Storable`; a mode-varying one (`List ℚ` vs `List Float`) yields two. Register
      -- each container field (per twin name) so codegen dereferences its accesses. Each cell type gets
      -- its own `Val` constructor, so `list[int]` is a real heap cell, never a bare-primitive case.
      let mut containers : List (String × String) := []   -- (cellType, mangledCtor), deduped
      for (m, sfx) in modes do
        numericModeRef.set m
        runSuffixRef.set sfx
        for c in classes do
          let .ok rawName := c.getObjValAs? String "name" | throwError "HeapPrelude: class missing 'name'"
          let name ← withRunSuffix rawName
          let fields := (c.getObjValAs? (Array Json) "fields").toOption.getD #[]
          let methods := (c.getObjValAs? (Array Json) "methods").toOption.getD #[]
          let noneParams :=
            (methods.find? (·.getObjValAs? String "name" == .ok "__init__")).elim [] noneDefaultParamNames
          for f in fields do
            if let .ok fname := f.getObjValAs? String "name" then
              match ← containerCellType? (classFieldPyType name noneParams f) with
              | some cell =>
                  registerContainerField name fname
                  unless containers.any (·.1 == cell) do containers := (cell, mangleContainerCtor cell) :: containers
              | none => pure ()
        for ann in (json.getObjValAs? (Array Json) "container_types").toOption.getD #[] do
          match ← containerCellType? (TypeInfer.ofAnnotation ann) with
          | some cell => unless containers.any (·.1 == cell) do containers := (cell, mangleContainerCtor cell) :: containers
          | none => pure ()

      -- 1. Every class structure (both twins under `emit_twin`), interleaved per class so an
      -- exact/approx twin sits adjacent, and all structs precede `Val`.
      for c in classes do
        for (m, sfx) in modes do
          numericModeRef.set m
          runSuffixRef.set sfx
          cmds := cmds.push (← classStructCommand c)

      -- 2. The per-program `Val` universe: one constructor per class×mode (fields at that mode's heap
      -- types) plus one per distinct container cell type. Python never heap-allocates a bare
      -- primitive, so `Val` has NO primitive constructors — only objects and mutable containers.
      let mut valSrc := "inductive Val where\n"
      let mut classCtorCount := 0
      for c in classes do
        let .ok rawName := c.getObjValAs? String "name" | throwError "HeapPrelude: class missing 'name'"
        for (m, sfx) in modes do
          numericModeRef.set m
          runSuffixRef.set sfx
          let name ← withRunSuffix rawName
          let mut fieldStr := ""
          for (fname, ty) in ← resolveFullFields classes rawName name do
            fieldStr := fieldStr ++ s!" ({fname} : {← renderHeapType ty})"
          valSrc := valSrc ++ s!"  | {valCtorName name}{fieldStr}\n"
          classCtorCount := classCtorCount + 1
      for (cell, ctor) in containers do
        valSrc := valSrc ++ s!"  | {ctor} (c : {cell})\n"
      valSrc := valSrc ++ "  deriving Repr, Inhabited"
      cmds := cmds.push (← parseHeapCommand valSrc)

      -- 3. `derive_storable%` per class×mode, and a trivial `Storable` per container cell type (the
      -- whole container rides in one constructor — elements are already inline/refs, so no recursion).
      for c in classes do
        let .ok rawName := c.getObjValAs? String "name" | throwError "HeapPrelude: class missing 'name'"
        for (m, sfx) in modes do
          numericModeRef.set m
          runSuffixRef.set sfx
          let name ← withRunSuffix rawName
          cmds := cmds.push (← parseHeapCommand s!"derive_storable% {name}")
      -- Omit the catch-all `| _ => none` when `Val` has a single constructor (else redundant-alt).
      let totalCtors := classCtorCount + containers.length
      for (cell, ctor) in containers do
        let projArm := if totalCtors == 1 then s!"fun | Val.{ctor} c => some c"
                       else s!"fun | Val.{ctor} c => some c | _ => none"
        cmds := cmds.push (← parseHeapCommand
          s!"instance : Storable Val ({cell}) where\n  inject := Val.{ctor}\n  project := {projArm}\n  project_inject := fun _ => rfl")

      numericModeRef.set savedMode
      runSuffixRef.set savedSuffix
      return ⟨mkNullNode (cmds.map (·.raw))⟩
  | kind, _ => throwError s!"HeapPrelude is only supported at command position, not '{kind}'."

end PastaLean
