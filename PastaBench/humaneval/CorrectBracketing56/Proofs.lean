import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.CorrectBracketing56

/-- Every `<` is matched by a later `>` (running count never negative, ends at zero). -/
def correct_bracketing (brackets : String) : Bool :=
  let (cnt, ok) := brackets.data.foldl (fun (st : Int × Bool) c =>
    let cnt := st.1 + (if c == '<' then 1 else if c == '>' then -1 else 0)
    (cnt, st.2 && cnt ≥ 0)) (0, true)
  ok && cnt == 0

theorem correct_bracketing_correct :
    correct_bracketing "<>" = true ∧ correct_bracketing "<<><>>" = true ∧
    correct_bracketing "<><><<><>><>" = true ∧
    correct_bracketing "<><><<<><><>><>><<><><<>>>" = true ∧
    correct_bracketing "<<<><>>>>" = false ∧ correct_bracketing "><<>" = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.CorrectBracketing56
