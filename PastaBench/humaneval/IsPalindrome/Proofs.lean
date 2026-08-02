import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IsPalindrome

def is_palindrome := fun (text : String) ↦ text == PastaLean.pySlice text none none (some (-(1 : Int)))

/-- The check returns `True` exactly when the string equals its reverse, `text[::-1]`. -/
theorem is_palindrome_correct (text : String) :
    is_palindrome text = true ↔ text = PastaLean.pySlice text none none (some (-(1 : Int))) := by
  simp only [is_palindrome, beq_iff_eq]

end PastaBench.humaneval.IsPalindrome
