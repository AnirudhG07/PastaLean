import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Common

def common := fun (l1 : List Int) ↦ fun (l2 : List Int) ↦
  PastaLean.pySort (PastaLean.pyList (PastaLean.pySetIntersection (PastaLean.pySet l1) (PastaLean.pySet l2)))

private theorem pyOrdLe_iff (a b : Int) : PastaLean.pyOrdLe a b = true ↔ a ≤ b := by
  unfold PastaLean.pyOrdLe
  simp only [bne_iff_ne]
  exact Int.compare_ne_gt

private theorem pyOrdLe_trans (a b c : Int) :
    PastaLean.pyOrdLe a b → PastaLean.pyOrdLe b c → PastaLean.pyOrdLe a c := by
  intro h1 h2
  rw [pyOrdLe_iff] at h1 h2 ⊢
  omega

private theorem pyOrdLe_total (a b : Int) :
    PastaLean.pyOrdLe a b || PastaLean.pyOrdLe b a := by
  rw [Bool.or_eq_true, pyOrdLe_iff, pyOrdLe_iff]
  omega

/-- The result of `common` is already sorted: re-sorting it leaves it unchanged. This is the
key correctness property of `sorted(list(set(l1) & set(l2)))`. -/
theorem common_correct : ∀ (l1 l2 : List Int),
    PastaLean.pySort (common l1 l2) = common l1 l2 := by
  intro l1 l2
  set Y := PastaLean.pyList (PastaLean.pySetIntersection (PastaLean.pySet l1) (PastaLean.pySet l2)) with hY
  have hc : common l1 l2 = List.mergeSort Y PastaLean.pyOrdLe := rfl
  rw [hc]
  show List.mergeSort (List.mergeSort Y PastaLean.pyOrdLe) PastaLean.pyOrdLe
      = List.mergeSort Y PastaLean.pyOrdLe
  exact List.mergeSort_of_pairwise (List.pairwise_mergeSort pyOrdLe_trans pyOrdLe_total Y)

end PastaBench.humaneval.Common
