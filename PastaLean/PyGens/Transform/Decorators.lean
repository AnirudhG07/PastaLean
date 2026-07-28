import PastaLean.PyGens.Core.Utils
import Libraries.Registry

open Lean

namespace PastaLean.Decorators

/-!
## Python decorators

`@a` / `@b` on a `def` is `f = a(b(f))` (bottom-up: `b`, nearest the def, applies first). We split
decorators into two kinds:

* **transparent** — no effect on the transpiled *value* (`@cache`/`@lru_cache` recompute to the same
  result; `@staticmethod`/`@classmethod`/`@property` are method-binding markers handled in `ClassDef`;
  `@wraps`/`@final`/… are metadata). The function is emitted unchanged.
* **applied** — a genuine wrapper (`@double`), lowered by emitting the raw function and binding the
  decorated name to the application `d1 (d2 raw)`. Requires the decorators to be transpilable
  functions; a decorator we can't resolve surfaces as a plain unknown-identifier error rather than
  being silently dropped (which would run the function undecorated — a wrong answer with no warning).

The transparent set is extensible: a library declares its own via `Libraries.libraryTransparentDecorator?`
(e.g. functools owns `cache`/`lru_cache`), so this file names no specific library.

TODO (general user decorators): applied decorators that return a *capturing* wrapper closure, or that
self-recurse, still depend on first-class closure values (the T3 closure-as-value work). Non-recursive
wrappers over top-level functions work today.
-/

/-- The dotted name of a decorator node: `@foo` → `foo`, `@a.b` → `a.b`, `@f(...)` → the callee's
name. `none` for a shape we don't recognise. -/
partial def decoratorName? (j : Json) : Option String :=
  match jsonNodeType? j with
  | some "Name" => (j.getObjValAs? String "id").toOption
  | some "Attribute" => do
      let recv ← (j.getObjVal? "value").toOption
      let attr ← (j.getObjValAs? String "attr").toOption
      let base ← decoratorName? recv
      some s!"{base}.{attr}"
  | some "Call" => do decoratorName? (← (j.getObjVal? "func").toOption)
  | _ => none

/-- The last dotted segment: `functools.cache` → `cache`. -/
private def lastSegment (name : String) : String :=
  (name.splitOn ".").getLast!

/-- Decorators with no effect on the transpiled value — emitting the function unchanged is correct.
Method-binding markers (`staticmethod`/`classmethod`/`property`) are included so they're transparent
in the free-function path too (in a class body `ClassDef` handles their real effect). -/
def isTransparent (name : String) : Bool :=
  let seg := lastSegment name
  ["staticmethod", "classmethod", "property", "abstractmethod", "final", "override"].contains seg
    || Libraries.libraryTransparentDecorator? seg

/-- The non-transparent decorators of a `FunctionDef`, in written (top-to-bottom) order — the ones
that must actually be applied. Empty ⇒ nothing to do (bare def, or all transparent). -/
def appliedDecorators (json : Json) : Array String :=
  let decos := (json.getObjValAs? (Array Json) "decorator_list").toOption.getD #[]
  (decos.filterMap decoratorName?).filter (fun n => !isTransparent n)

end PastaLean.Decorators
