import PastaLean.PyAPI.Operators

/-!
# `operator` module shims

Thin wrappers so Python's `operator.add`, `operator.xor`, … can be passed as first-class function
VALUES — `reduce(xor, xs)`, `sorted(xs, key=…)`, `functools.reduce(operator.add, …)`. The bitwise ops
reuse the existing `pyBit*` runtime functions directly (see `Mapping.lean`); the arithmetic ones need
a named binary function, provided here over the Python operator typeclasses.
-/

namespace Libraries.operator
open PastaLean

def pyOperatorAdd {α β γ : Type} [PyHAdd α β γ] (a : α) (b : β) : γ := a +ₚ b
def pyOperatorSub {α β γ : Type} [PyHSub α β γ] (a : α) (b : β) : γ := a -ₚ b
def pyOperatorMul {α β γ : Type} [PyHMul α β γ] (a : α) (b : β) : γ := a *ₚ b
def pyOperatorMod {α β γ : Type} [PyModulo α β γ] (a : α) (b : β) : γ := a %ₚ b
def pyOperatorFloorDiv {α β γ : Type} [PyFloorDiv α β γ] (a : α) (b : β) : γ := PyFloorDiv.floorDiv a b

end Libraries.operator
