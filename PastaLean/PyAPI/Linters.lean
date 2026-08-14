import Lean

/-!
# Marker linters

Reusable support for the transpiler's *marker linters*: a marker linter warns at every use site of
a runtime name that means "this code is not what the Python said". Generated code type-checks and
runs either way, so the warning is the only thing that makes the degradation visible.

`markerLinter` is the whole mechanism — an option, a predicate on the identifier's final name
component, and a message. To add one: register an option, name your runtime function so the
predicate matches, and `initialize addLinter (markerLinter …)`. Nothing here knows about any
particular library.

Two are registered below:

* `linter.unsupported` — `pyUnsupported`, a statement the best-effort fallback DROPPED.
* `linter.dummyImplementation` — a `*Dummy` stand-in, which produces a value of the right shape
  but the WRONG value.
-/

open Lean Elab Command

namespace PastaLean.Linter

/-- Collect every identifier in `stx` whose final name component satisfies `isMarked`. -/
private partial def collectMarked (isMarked : String → Bool) : Syntax → Array Syntax → Array Syntax
  | stx@(Syntax.ident ..), acc =>
      let marked := match stx.getId.eraseMacroScopes with
        | .str _ s => isMarked s
        | _ => false
      if marked then acc.push stx else acc
  | Syntax.node _ _ args, acc => args.foldl (fun a s => collectMarked isMarked s a) acc
  | _, acc => acc

/-- A linter that warns at every use of a marked runtime name. `opt` gates it (so it can be turned
off per-file), `isMarked` recognises the name, `message` explains the consequence. -/
def markerLinter (opt : Lean.Option Bool) (isMarked : String → Bool) (message : MessageData) :
    Linter where
  run := fun stx => do
    unless Linter.getLinterValue opt (← Linter.getLinterOptions) do
      return
    for occ in collectMarked isMarked stx #[] do
      Linter.logLint opt occ message

/-! ### The registered marker linters -/

register_option linter.unsupported : Bool := {
  defValue := true
  descr := "warn on best-effort `pyUnsupported(...)` placeholders for Python constructs the \
            transpiler does not support"
}

initialize addLinter (markerLinter linter.unsupported (· == "pyUnsupported")
  m!"Could not translate this Python to Lean because it is Unsupported. Left as a no-op placeholder and does nothing.")

register_option linter.dummyImplementation : Bool := {
  defValue := true
  descr := "warn on stand-in runtime functions (name ends in `Dummy`) that do not faithfully \
            implement the Python original"
}

initialize addLinter (markerLinter linter.dummyImplementation
  (fun s => s.endsWith "Dummy" && s != "Dummy")
  m!"This is a DUMMY stand-in, not a faithful implementation of the Python original. It returns a \
     deterministic value of the right shape, but that value is WRONG — do not depend on it, and do \
     not prove anything about it.")

end PastaLean.Linter
