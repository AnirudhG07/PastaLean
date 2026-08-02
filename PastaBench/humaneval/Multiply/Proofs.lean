import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Multiply

def multiply := fun (a : Int) ↦ fun (b : Int) ↦
  PastaLean.pyInt (PastaLean.pyStr a)⦋(-1 : Int)⦌ *ₚ PastaLean.pyInt (PastaLean.pyStr b)⦋(-1 : Int)⦌

/-- Correctness: the product of the unit digits, equivalently `(|a| % 10) * (|b| % 10)`,
    checked on the reference test cases. -/
theorem multiply_correct :
    multiply 148 412 = 16 ∧
    multiply 19 28 = 72 ∧
    multiply 2020 1851 = 0 ∧
    multiply 14 (-15) = 20 ∧
    multiply 76 67 = 42 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Multiply
