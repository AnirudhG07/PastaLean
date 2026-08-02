import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MatchParens

private def _match_parens'valid_parens := fun (s : String) ↦
  (do
    let mut cnt : Int := (0 : Int)
    for ch in (PastaLean.pyIter s)do
      cnt := if ch = "(" then cnt +ₚ (1 : Int) else cnt -ₚ (1 : Int)
      if h_1 : cnt < (0 : Int) then
        return Bool.false
      else
        let _ := ()
    let __py_ret_1 := cnt == (0 : Int)
    return __py_ret_1 : Id _)

def match_parens := fun (lst : List String) ↦
  if
      PastaLean.pyTruthy (_match_parens'valid_parens (lst⦋(0 : Int)⦌ +ₚ lst⦋(1 : Int)⦌)).run = true ∨
        PastaLean.pyTruthy (_match_parens'valid_parens (lst⦋(1 : Int)⦌ +ₚ lst⦋(0 : Int)⦌)).run = true then
    "Yes"
  else "No"

-- 'Yes' iff the two paren-strings can be concatenated (in some order) into a balanced string.
theorem match_parens_correct :
    match_parens ["()(", ")"] = "Yes"
      ∧ match_parens [")", ")"] = "No"
      ∧ match_parens ["(()(())", "())())"] = "No"
      ∧ match_parens [")())", "(()()("] = "Yes"
      ∧ match_parens ["(())))", "(()())(("] = "Yes"
      ∧ match_parens ["()", "())"] = "No" := by
  native_decide

end PastaBench.humaneval.MatchParens
