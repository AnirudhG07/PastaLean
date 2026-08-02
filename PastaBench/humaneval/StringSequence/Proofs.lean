import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.StringSequence

def string_sequence := fun (n : Int) ↦
  PastaLean.pyStringJoin " " (PastaLean.pyMap PastaLean.pyStr (PastaLean.pyRange (n +ₚ (1 : Int))))

/-- The function produces the space-delimited sequence `0..n`. -/
theorem string_sequence_examples :
    string_sequence 0 = "0" ∧ string_sequence 5 = "0 1 2 3 4 5" := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.StringSequence
