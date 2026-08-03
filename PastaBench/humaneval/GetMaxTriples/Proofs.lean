import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.GetMaxTriples

/-- The product of three consecutive integers starting at `a ≥ 0` is non-negative. -/
theorem three_consec_nonneg (a : Int) (h : 0 ≤ a) : 0 ≤ a * (a - 1) * (a - 2) := by
  rcases (by omega : a ≤ 2 ∨ 3 ≤ a) with h2 | h2
  · interval_cases a <;> decide
  · nlinarith [h2, mul_nonneg (mul_nonneg (by omega : (0:Int) ≤ a) (by omega : (0:Int) ≤ a-1))
      (by omega : (0:Int) ≤ a-2)]

def get_max_triples := fun (n : Int) ↦
  (do
    if h_1 : n ≤ (2 : Int) then
      return (0 : Int)
    else
      let _ := ()
    let mut one_cnt : Int :=
      (1 : Int) +ₚ PastaLean.pyFloorDiv (n -ₚ (2 : Int)) (3 : Int) *ₚ (2 : Int) +ₚ (n -ₚ (2 : Int)) %ₚ (3 : Int)
    let mut zero_cnt : Int := n -ₚ one_cnt
    let __py_ret_1 :=
      PastaLean.pyFloorDiv (one_cnt *ₚ (one_cnt -ₚ (1 : Int)) *ₚ (one_cnt -ₚ (2 : Int))) (6 : Int) +ₚ
        PastaLean.pyFloorDiv (zero_cnt *ₚ (zero_cnt -ₚ (1 : Int)) *ₚ (zero_cnt -ₚ (2 : Int))) (6 : Int)
    return __py_ret_1 : Id _)

-- Deep property: the count of valid triples is non-negative — but the point is that the CLOSED-FORM
-- `C(one,3)+C(zero,3)` (integer floor divisions of products of three consecutive integers) is
-- provably ≥ 0, which needs the nonlinear `three_consec_nonneg` fact, not just omega.
@[spec]
theorem get_max_triples_spec : ⦃⌜n > (0 : Int)⌝⦄ get_max_triples n ⦃⇓result => ⌜result ≥ (0 : Int)⌝⦄ := by
  mvcgen [get_max_triples]
  all_goals simp_all only [taste_ingr, PyFloorDiv.floorDiv, pyFloorDiv, PyHAdd.hAdd, PyHSub.hSub,
    PyHMul.hMul, PyModulo.hMod, pyMod, ge_iff_le]
  all_goals (first
    | omega
    | (refine add_nonneg (Int.fdiv_nonneg (three_consec_nonneg _ ?_) (by norm_num))
                         (Int.fdiv_nonneg (three_consec_nonneg _ ?_) (by norm_num)) <;>
        (simp (config := { zetaDelta := true }) [PyFloorDiv.floorDiv, pyFloorDiv, PyHAdd.hAdd,
           PyHSub.hSub, PyHMul.hMul, PyModulo.hMod, pyMod, Int.fdiv_eq_ediv]; omega)))

theorem get_max_triples_correct :
    ∀ (n : Int), n > (0 : Int) → let result := (get_max_triples n).run; result ≥ (0 : Int) := by
  intro n hpre
  exact get_max_triples_spec hpre

end PastaBench.humaneval.GetMaxTriples
