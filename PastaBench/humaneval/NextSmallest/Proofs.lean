import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.NextSmallest

def next_smallest := fun (lst : List Int) ↦
  Id.run
    (do
      if h_1 : PastaLean.pyLen lst ≤ (1 : Int) then
        return (none : Option Int)
      else
        let _ := ()
      let sorted_list : List Int := PastaLean.pySort lst
      for x in (PastaLean.pyIter sorted_list)do
        if h_2 : x ≠ sorted_list⦋(0 : Int)⦌ then
          return (some x)
        else
          let _ := ()
      return none)

/-- Correctness: returns the 2nd-smallest distinct element, or `None` when there is
    no such element, checked on the reference test cases. -/
theorem next_smallest_correct :
    next_smallest [1, 2, 3, 4, 5] = some 2 ∧
    next_smallest [5, 1, 4, 3, 2] = some 2 ∧
    next_smallest [] = none ∧
    next_smallest [1, 1] = none ∧
    next_smallest [1, 1, 1, 1, 0] = some 1 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.NextSmallest
