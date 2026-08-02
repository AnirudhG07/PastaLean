import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MaxFill

def max_fill := fun (grid : List (List Int)) ↦ fun (capacity : Int) ↦
  (do
    let mut ans : Int := (0 : Int)
    for l in (PastaLean.pyIter grid)do
      ans := ans +ₚ Libraries.math.pyMathCeil (PastaLean.pySum l /ₚ capacity)
    return ans : Id _)

-- Total bucket lowerings = sum over rows of ceil(row_sum / capacity).
theorem max_fill_correct :
    (max_fill [[0, 0, 1, 0], [0, 1, 0, 0], [1, 1, 1, 1]] 1).run = 6
      ∧ (max_fill [[0, 0, 1, 1], [0, 0, 0, 0], [1, 1, 1, 1], [0, 1, 1, 1]] 2).run = 5
      ∧ (max_fill [[0, 0, 0], [0, 0, 0]] 5).run = 0
      ∧ (max_fill [[1, 1, 1, 1], [1, 1, 1, 1]] 2).run = 4
      ∧ (max_fill [[1, 1, 1, 1], [1, 1, 1, 1]] 9).run = 2 := by
  native_decide

end PastaBench.humaneval.MaxFill
