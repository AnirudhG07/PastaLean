import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.LargestSmallestIntegers

def largest_smallest_integers := fun (lst : List Int) ↦
  let neg := PastaLean.pyList (PastaLean.pyFilter (fun x ↦ decide (x < (0 : Int))) lst)
  let pos := PastaLean.pyList (PastaLean.pyFilter (fun x ↦ decide (x > (0 : Int))) lst)
  (if neg = [] then none else some (PastaLean.pyMax neg),
   if pos = [] then none else some (PastaLean.pyMin pos))

-- (largest negative or None, smallest positive or None).
theorem largest_smallest_integers_correct :
    largest_smallest_integers [2, 4, 1, 3, 5, 7] = (none, some 1)
      ∧ largest_smallest_integers [] = (none, none)
      ∧ largest_smallest_integers [0] = (none, none)
      ∧ largest_smallest_integers [1, 3, 2, 4, 5, 6, -2] = (some (-2), some 1)
      ∧ largest_smallest_integers [-1, -3, -5, -6] = (some (-1), none)
      ∧ largest_smallest_integers [-6, -4, -4, -3, 1] = (some (-3), some 1) := by
  native_decide

end PastaBench.humaneval.LargestSmallestIntegers
