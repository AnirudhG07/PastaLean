import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.StringXor

def string_xor := fun (a : String) ↦ fun (b : String) ↦
  PastaLean.pyStringJoin ""
    ((PastaLean.pyRange (PastaLean.pyLen a)).map fun i =>
      PastaLean.pyStr (PastaLean.pyBitXor (PastaLean.pyInt a⦋i⦌) (PastaLean.pyInt b⦋i⦌)))

/-- Bitwise XOR of the two bit-strings, character by character. -/
theorem string_xor_examples :
    string_xor "010" "110" = "100" ∧ string_xor "1" "1" = "0" := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.StringXor
