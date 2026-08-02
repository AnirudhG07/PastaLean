import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IsEqualToSumEven

def is_equal_to_sum_even := fun (n : Int) ↦
  if PastaLean.pyTruthy (decide (n ≥ (8 : Int))) then n %ₚ (2 : Int) == (0 : Int) else decide (n ≥ (8 : Int))

/-- `n` is a sum of exactly four positive even numbers iff `n ≥ 8` and `n` is even. -/
theorem is_equal_to_sum_even_correct (n : Int) :
    is_equal_to_sum_even n = true ↔ (n ≥ (8 : Int) ∧ n %ₚ (2 : Int) = (0 : Int)) := by
  simp only [is_equal_to_sum_even, pyTruthy, PyTruthy.truthy]
  by_cases h : n ≥ (8 : Int) <;> simp [h] <;> omega

end PastaBench.humaneval.IsEqualToSumEven
