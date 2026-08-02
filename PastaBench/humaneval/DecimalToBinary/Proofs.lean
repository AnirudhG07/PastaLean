import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000

namespace PastaBench.humaneval.DecimalToBinary

def decimal_to_binary := fun decimal ↦
  "db" +ₚ PastaLean.pySlice (PastaLean.pyBin decimal) (some (2 : Int)) none none +ₚ "db"

theorem decimal_to_binary_correct :
    decimal_to_binary 0 = "db0db" ∧
    decimal_to_binary 32 = "db100000db" ∧
    decimal_to_binary 103 = "db1100111db" ∧
    decimal_to_binary 15 = "db1111db" ∧
    decimal_to_binary 100001 = "db11000011010100001db" := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.DecimalToBinary
