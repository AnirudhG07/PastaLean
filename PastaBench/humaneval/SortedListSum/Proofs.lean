import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SortedListSum

/-- Faithful reconstruction (PastaLean's codegen degraded the original `Return`): keep only
the even-length strings, then return them sorted. -/
def sorted_list_sum := fun (lst : List String) ↦
  PastaLean.pySort (lst.filter (fun s => PastaLean.pyLen s %ₚ (2 : Int) == (0 : Int)))

/-- Every string in the result has even length: the result is a permutation (via sorting) of
the sublist of even-length strings, so nothing of odd length survives. -/
theorem sorted_list_sum_correct :
    ∀ (lst : List String) (s : String),
      s ∈ sorted_list_sum lst → PastaLean.pyLen s %ₚ (2 : Int) = 0 := by
  intro lst s hs
  simp only [sorted_list_sum, PastaLean.pySort] at hs
  have hmem : s ∈ lst.filter (fun s => PastaLean.pyLen s %ₚ (2 : Int) == (0 : Int)) := by
    have := (List.mem_mergeSort (l := lst.filter (fun s => PastaLean.pyLen s %ₚ (2 : Int) == (0 : Int)))
      (le := pyOrdLe)).mp hs
    exact this
  have := (List.mem_filter.mp hmem).2
  simpa using this

end PastaBench.humaneval.SortedListSum
