import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.DoAlgebra

/-- A scoped arithmetic evaluator (replacing Python `eval`): precedence `**` > `*`,`//` > `+`,`-`. -/
def applyOp (op : String) (a b : Int) : Int :=
  if op == "+" then a + b
  else if op == "-" then a - b
  else if op == "*" then a * b
  else if op == "//" then a / b
  else a ^ b.toNat

/-- Collapse every operator in `targets` left-to-right, leaving the lower-precedence operators. -/
def reducePass (nums : List Int) (ops : List String) (targets : List String) :
    List Int × List String := Id.run do
  let mut rnums : List Int := []
  let mut rops : List String := []
  let mut acc : Int := nums.headD 0
  let mut rest : List Int := nums.drop 1
  for op in ops do
    let b := rest.headD 0
    rest := rest.drop 1
    if targets.contains op then
      acc := applyOp op acc b
    else
      rnums := rnums ++ [acc]; rops := rops ++ [op]; acc := b
  return (rnums ++ [acc], rops)

def do_algebra (operator : List String) (operand : List Int) : Int :=
  let (n1, o1) := reducePass operand operator ["**"]
  let (n2, o2) := reducePass n1 o1 ["*", "//"]
  let (n3, _)  := reducePass n2 o2 ["+", "-"]
  n3.headD 0

theorem do_algebra_correct :
    do_algebra ["**","*","+"] [2,3,4,5] = 37 ∧
    do_algebra ["+","*","-"] [2,3,4,5] = 9 ∧
    do_algebra ["//","*"] [7,3,4] = 8 := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

/-- General property: with no operators, the expression is just its single operand. -/
theorem do_algebra_singleton (x : Int) : do_algebra [] [x] = x := by rfl

end PastaBench.humaneval.DoAlgebra
