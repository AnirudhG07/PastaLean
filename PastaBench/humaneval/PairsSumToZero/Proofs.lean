import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.PairsSumToZero

def pairs_sum_to_zero := fun (l : List Int) ↦
  Id.run
    (do
      for i in (PastaLean.pyRange (PastaLean.pyLen l))do
        for j in (PastaLean.pyRange (PastaLean.pyLen l))do
          if h_1 : i ≠ j ∧ l⦋i⦌ +ₚ l⦋j⦌ = (0 : Int) then
            return Bool.true
          else
            let _ := ()
      return Bool.false)

/-- Correctness: returns `True` iff two distinct positions hold values summing to
    zero, checked on the reference test cases. -/
theorem pairs_sum_to_zero_correct :
    pairs_sum_to_zero [1, 3, 5, 0] = false ∧
    pairs_sum_to_zero [1, 3, -2, 1] = false ∧
    pairs_sum_to_zero [1, 2, 3, 7] = false ∧
    pairs_sum_to_zero [2, 4, -5, 3, 5, 7] = true ∧
    pairs_sum_to_zero [1] = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.PairsSumToZero
