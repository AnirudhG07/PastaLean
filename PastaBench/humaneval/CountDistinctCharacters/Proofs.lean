import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CountDistinctCharacters

/-- `count_distinct_characters s = len(set(s.lower()))`, the number of distinct
    case-folded characters. -/
def count_distinct_characters := fun (string : String) ↦
  PastaLean.pyLen (PastaLean.pySet (PastaLean.pyStringLower string) : List String)

/-- Deduplicating a list never grows it. -/
theorem pySetFromList_length_le {α} [BEq α] (xs : List α) :
    (PastaLean.pySetFromList xs).length ≤ xs.length := by
  have key : ∀ (ys : List α) (acc : List α),
      (ys.foldl (fun acc x => if acc.contains x then acc else acc ++ [x]) acc).length
        ≤ acc.length + ys.length := by
    intro ys
    induction ys with
    | nil => intro acc; simp
    | cons a t ih =>
      intro acc
      simp only [List.foldl_cons, List.length_cons]
      split
      · have := ih acc; omega
      · have := ih (acc ++ [a])
        simp only [List.length_append, List.length_cons, List.length_nil] at this
        omega
  have := key xs []
  simpa [PastaLean.pySetFromList] using this

/-- The count of distinct characters is between 0 and the string length. -/
@[taste_ingr]
theorem count_distinct_characters_correct (string : String) :
    (0 : Int) ≤ count_distinct_characters string ∧
      count_distinct_characters string ≤ PastaLean.pyLen string := by
  have hlen : (PastaLean.pyStringLower string).toList.length = string.length := by
    simp [pyStringLower, String.length_toList]
  simp only [count_distinct_characters, PastaLean.pySet, pyLen, PyLen.pyLen,
    pyIter, PyIterable.toPyList]
  refine ⟨by exact_mod_cast Nat.zero_le _, ?_⟩
  have h1 := pySetFromList_length_le
    ((PastaLean.pyStringLower string).toList.map (·.toString))
  rw [List.length_map, hlen] at h1
  exact_mod_cast h1

end PastaBench.humaneval.CountDistinctCharacters
