import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MaxElement

def max_element := fun (l : List Int) ↦ PastaLean.pyMax l

-- Returns the maximum element of the list.
theorem max_element_correct :
    max_element [1, 2, 3] = 3
      ∧ max_element [5, 3, -5, 2, -3, 3, 9, 0, 124, 1, -10] = 124
      ∧ max_element [0, 0, 0, 0] = 0
      ∧ max_element [-1, -2, -3, -4, -5] = -1
      ∧ max_element [8, 7, 6, 5, 4, 3] = 8 := by
  native_decide

end PastaBench.humaneval.MaxElement
