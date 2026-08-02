import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RemoveDuplicates

def remove_duplicates (l : List Int) : List Int :=
  l.filter (fun x => l.count x == 1)

theorem remove_duplicates_correct (l : List Int) (x : Int) :
    x ∈ remove_duplicates l ↔ (x ∈ l ∧ l.count x = 1) := by
  simp [remove_duplicates, List.mem_filter, beq_iff_eq]

end PastaBench.humaneval.RemoveDuplicates
