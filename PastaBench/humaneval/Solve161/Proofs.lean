import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Solve161

/-- Reverse the case of every letter; if there are no letters, reverse the whole string. -/
def solve (s : String) : String :=
  if s.data.any Char.isAlpha then
    String.mk (s.data.map (fun c => if c.isUpper then c.toLower else if c.isLower then c.toUpper else c))
  else String.mk s.data.reverse

theorem solve_correct :
    solve "AsDf" = "aSdF" ∧ solve "1234" = "4321" ∧ solve "ab" = "AB" := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Solve161
