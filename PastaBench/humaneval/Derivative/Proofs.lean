import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Derivative

def derivative := fun (xs : List Int) ↦ (PastaLean.pyRange (PastaLean.pyLen xs) (1 : Int)).map fun i => xs⦋i⦌ *ₚ i

theorem derivative_correct :
    derivative [3, 1, 2, 4, 5] = [1, 4, 12, 20] ∧
    derivative [1, 2, 3] = [2, 6] ∧
    derivative [3, 2, 1] = [2, 2] ∧
    derivative [3, 2, 1, 0, 4] = [2, 2, 0, 16] ∧
    derivative [1] = [] := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Derivative
