import Mathlib

namespace PastaLean

/--
Python's `x is None` / `x is not None` identity test against `None`.

Unlike a raw `Option.isNone`, this dispatches on the operand's type, so the test type-checks for
*any* value — not only `Option`s. A value whose type cannot be `None` (an `Int`, `String`, `List`,
…) answers `false`; the Python `None` value (Lean `Unit`) answers `true`; an `Option` answers by
its `none`/`some` tag. This mirrors Python, where `is None` is meaningful on every object, not just
the ones that might actually be `None`.

Codegen lowers `expr is None` to `pyIsNone expr` and `expr is not None` to `!pyIsNone expr`.
-/
class PyIsNone (α : Type) where
  isNoneVal : α → Bool

/-- Dispatch Python's `is None` test through the `PyIsNone` protocol. -/
def pyIsNone {α : Type} [PyIsNone α] (x : α) : Bool := PyIsNone.isNoneVal x

/-- An `Optional[T]` value is `None` exactly when it is `Option.none`. -/
instance {α : Type} : PyIsNone (Option α) where isNoneVal := Option.isNone

/-- The Python `None` value itself (modelled as `Unit`) is always `None`. -/
instance : PyIsNone Unit where isNoneVal _ := true

/-- Any other value is never `None` — a concrete non-`Option` type cannot hold `None`. Low priority
so the `Option`/`Unit` (and `PyAny`, in `PyAny.lean`) instances win when they apply. -/
instance (priority := low) {α : Type} : PyIsNone α where isNoneVal _ := false

end PastaLean
