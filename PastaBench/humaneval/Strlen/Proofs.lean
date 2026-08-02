import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Strlen

def strlen := fun (string : String) ↦ PastaLean.pyLen string

/-- The returned length equals the Python length of the string and is non-negative. -/
theorem strlen_correct :
    ∀ (string : String), strlen string ≥ (0 : Int) ∧ strlen string = PastaLean.pyLen string := by
  intro string
  refine ⟨?_, rfl⟩
  simp only [strlen, pyLen, PyLen.pyLen]
  omega

end PastaBench.humaneval.Strlen
