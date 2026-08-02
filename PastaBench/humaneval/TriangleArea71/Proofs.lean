import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.TriangleArea71

def triangle_area := fun (a : Int) ↦ fun (b : Int) ↦ fun (c : Int) ↦
  Id.run (do
    if h_1 : decide (a +ₚ b ≤ c) || decide (a +ₚ c ≤ b) || decide (b +ₚ c ≤ a) then
      let __py_ret_1 := (-1 : Float)
      return __py_ret_1
    else
      let _ := ()
    let mut p := PastaLean.pyFloat (a +ₚ b +ₚ c) /ₚ (2 : Int)
    let __py_ret_1 :=
      PastaLean.pyRoundDigits ((p *ₚ (p -ₚ a) *ₚ (p -ₚ b) *ₚ (p -ₚ c)) ^ₚ (0.5 : Float)) (2 : Int)
    return __py_ret_1)

/-- Heron's-formula area for a valid triangle, and `-1` for an invalid one. -/
theorem triangle_area_examples :
    (triangle_area 3 4 5 == 6.0) = true ∧
    (triangle_area 1 2 10 == -1) = true := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.TriangleArea71
