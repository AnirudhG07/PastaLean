import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SumToN

def sum_to_n := fun (n : Int) ↦ PastaLean.pyFloorDiv ((n +ₚ (1 : Int)) *ₚ n) (2 : Int)

/-- Twice the result equals `n * (n + 1)`, i.e. the closed form of the triangular sum. -/
theorem sum_to_n_correct :
    ∀ (n : Int), n ≥ (0 : Int) → (2 : Int) *ₚ sum_to_n n = n *ₚ (n + 1) := by
  intro n _
  simp only [sum_to_n, pyFloorDiv, PyFloorDiv.floorDiv, PyHAdd.hAdd, PyHMul.hMul]
  rw [if_neg (by decide)]
  obtain ⟨k, hk⟩ := Int.even_mul_succ_self n
  have h2 : (n + 1) * n = 2 * k := by rw [mul_comm]; rw [hk]; ring
  rw [h2, Int.mul_fdiv_cancel_left _ (by decide : (2 : Int) ≠ 0)]
  rw [hk]; ring

end PastaBench.humaneval.SumToN
