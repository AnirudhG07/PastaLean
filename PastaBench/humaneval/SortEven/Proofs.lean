import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SortEven

def sort_even := fun (l : List Int) ↦
  (do
    let mut even :=
      (List.filter (fun i => i %ₚ (2 : Int) = (0 : Int)) (PastaLean.pyRange (PastaLean.pyLen l))).map fun i => l⦋i⦌
    even := PastaLean.pySort even
    let __py_ret_1 :=
      (PastaLean.pyRange (PastaLean.pyLen l)).map fun i =>
        if i %ₚ (2 : Int) = (0 : Int) then even⦋PastaLean.pyFloorDiv i (2 : Int)⦌ else l⦋i⦌
    return __py_ret_1 : Id _)

/-- The result has the same length as the input list: every input index contributes exactly
one output element (even indices from the sorted sublist, odd indices copied). -/
theorem sort_even_correct : ∀ (l : List Int), pyLen (sort_even l).run = pyLen l := by
  intro l
  have plen : ∀ (xs : List Int), pyLen xs = (xs.length : Int) := fun _ => rfl
  simp only [sort_even, Id.run, bind, pure, plen,
    List.length_map, PastaLean.pyRange_eq_ofNat, List.length_range]
  simp [Int.toNat_of_nonneg, List.length_range]

end PastaBench.humaneval.SortEven
