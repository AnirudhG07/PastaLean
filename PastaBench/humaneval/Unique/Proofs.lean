import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Unique

def unique := fun (l : List Int) ↦ PastaLean.pySort (PastaLean.pySet l)

theorem unique_perm : ∀ (l : List Int), (unique l).Perm (PastaLean.pySet l) := by
  intro l
  simp only [unique, pySort, PySort.pySort]
  exact List.mergeSort_perm _ _

end PastaBench.humaneval.Unique
