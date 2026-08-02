import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Maximum

def maximum := fun (arr : List Int) ↦ fun (k : Int) ↦
  PastaLean.pySort
    (PastaLean.pySlice (PastaLean.pySlice (PastaLean.pySort arr) none none (some (-(1 : Int)))) none (some k)
      none)

-- Sorted list of the k largest elements of arr.
theorem maximum_correct :
    maximum [-3, -4, 5] 3 = [-4, -3, 5]
      ∧ maximum [4, -4, 4] 2 = [4, 4]
      ∧ maximum [-3, 2, 1, 2, -1, -2, 1] 1 = [2]
      ∧ maximum [123, -123, 20, 0, 1, 2, -3] 3 = [2, 20, 123]
      ∧ maximum [-123, 20, 0, 1, 2, -3] 4 = [0, 1, 2, 20] := by
  native_decide

end PastaBench.humaneval.Maximum
