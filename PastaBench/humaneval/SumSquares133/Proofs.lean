import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SumSquares133

def sum_squares := fun (lst : List Int) ↦
  PastaLean.pySum (PastaLean.pyMap (fun (x : Int) ↦ Libraries.math.pyMathCeil (PastaLean.pyFloat x) ^ₚ (2 : Int)) lst)

/-- Sum of squared ceilings of the (integer) list entries. -/
theorem sum_squares_examples :
    sum_squares [1, 2, 3] = 14 ∧
    sum_squares [1, 4, 9] = 98 ∧
    sum_squares [1, 3, 5, 7] = 84 := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SumSquares133
