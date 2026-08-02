import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SortThird

def sort_third := fun (l : List Int) ↦
  (do
    let mut third :=
      (List.filter (fun i => i %ₚ (3 : Int) = (0 : Int)) (PastaLean.pyRange (PastaLean.pyLen l))).map fun i => l⦋i⦌
    third := PastaLean.pySort third
    let __py_ret_1 :=
      (PastaLean.pyRange (PastaLean.pyLen l)).map fun i =>
        if i %ₚ (3 : Int) = (0 : Int) then third⦋PastaLean.pyFloorDiv i (3 : Int)⦌ else l⦋i⦌
    return __py_ret_1 : Id _)

/-- The result has the same length as the input list: every index of the input contributes
exactly one element to the output (multiple-of-3 indices from the sorted sublist, the rest
copied), so length is preserved. -/
theorem sort_third_correct : ∀ (l : List Int), pyLen (sort_third l).run = pyLen l := by
  intro l
  have plen : ∀ (xs : List Int), pyLen xs = (xs.length : Int) := fun _ => rfl
  simp only [sort_third, Id.run, bind, pure, plen,
    List.length_map, PastaLean.pyRange_eq_ofNat, List.length_range]
  simp [Int.toNat_of_nonneg, List.length_range]

end PastaBench.humaneval.SortThird
