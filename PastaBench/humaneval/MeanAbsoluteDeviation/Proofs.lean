import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MeanAbsoluteDeviation

def mean_absolute_deviation := fun (numbers : List Rat) ↦
  let mean : Rat := PastaLean.pySum numbers /ₚ PastaLean.pyLen numbers
  (PastaLean.pySum ((PastaLean.pyIter numbers).map (fun x => PastaLean.pyAbs (x -ₚ mean))) /ₚ
    PastaLean.pyLen numbers : Rat)

-- Average absolute deviation from the mean (computed exactly over ℚ).
theorem mean_absolute_deviation_correct :
    mean_absolute_deviation [1, 2, 3] = 2/3
      ∧ mean_absolute_deviation [1, 2, 3, 4] = 1
      ∧ mean_absolute_deviation [1, 2, 3, 4, 5] = 6/5
      ∧ mean_absolute_deviation [0, 0, 0, 0, 0] = 0
      ∧ mean_absolute_deviation [-2, 2] = 2
      ∧ mean_absolute_deviation [-1, -1, 1, 1] = 1 := by
  native_decide

end PastaBench.humaneval.MeanAbsoluteDeviation
