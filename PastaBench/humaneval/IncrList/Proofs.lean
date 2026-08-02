import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IncrList

def incr_list := fun (l : List Int) ↦ (PastaLean.pyIter l).map fun x => x +ₚ (1 : Int)

/-- The result is exactly the input list with every element incremented by one. -/
theorem incr_list_correct (l : List Int) :
    incr_list l = l.map (fun x => x + 1) := by
  simp only [incr_list, pyIter, PyIterable.toPyList, PyHAdd.hAdd, id_eq]

end PastaBench.humaneval.IncrList
