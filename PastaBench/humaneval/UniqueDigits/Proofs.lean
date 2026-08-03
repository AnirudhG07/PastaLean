import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.UniqueDigits

-- Reusable sort facts (candidates for HelperLemmas): `pyOrdLe` is exactly `≤` on ℤ, so `pySort`
-- produces a `Pairwise`-sorted list.
theorem pyOrdLe_eq_le (a b : Int) : pyOrdLe a b = decide (a ≤ b) := by
  unfold pyOrdLe
  rcases h : compare a b with _ | _ | _
  · have hh : a < b := Int.compare_eq_lt.mp h; grind
  · have hh : a = b := Int.compare_eq_eq.mp h; grind
  · have hh : b < a := Int.compare_eq_gt.mp h; grind

theorem pySort_sorted (xs : List Int) :
    (pySort xs).Pairwise (fun a b => pyOrdLe a b = true) := by
  show (List.mergeSort xs pyOrdLe).Pairwise _
  exact List.sorted_mergeSort
    (fun a b c h1 h2 => by simp only [pyOrdLe_eq_le, decide_eq_true_eq] at *; omega)
    (fun a b => by simp only [pyOrdLe_eq_le, Bool.or_eq_true, decide_eq_true_eq]; omega) xs

private def _unique_digits'judge := fun (num : Int) ↦
  (do
    for ch in (PastaLean.pyIter (PastaLean.pyStr num))do
      if h_1 : PastaLean.pyInt ch %ₚ (2 : Int) = (0 : Int) then
        return Bool.false
      else
        let _ := ()
    let _ :=
      Libraries.passta.pyPassAssert
        (PastaLean.pyAll
          ((PastaLean.pyIter (PastaLean.pyStr num)).map fun c => PastaLean.pyInt c %ₚ (2 : Int) != (0 : Int)))
    return Bool.true : Id _)

def unique_digits := fun (x : List Int) ↦
  PastaLean.pySort (PastaLean.pyList (PastaLean.pyFilter _unique_digits'judge x))

-- Deep property: the result is sorted in ascending order (`pyOrdLe`, i.e. `≤`).
theorem unique_digits_correct (x : List Int) :
    (unique_digits x).Pairwise (fun a b => pyOrdLe a b = true) := by
  show (pySort (pyList (pyFilter _unique_digits'judge x))).Pairwise _
  exact pySort_sorted _

end PastaBench.humaneval.UniqueDigits
