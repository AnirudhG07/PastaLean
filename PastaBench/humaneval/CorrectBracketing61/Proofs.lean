import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CorrectBracketing61

/-- Balance scan over a string of `(`/`)`: return `True` iff every prefix has at least as
    many `(` as `)` and the totals match. -/
def correct_bracketing := fun (brackets : String) ↦
  (do
    let mut cnt : Int := (0 : Int)
    for x in (PastaLean.pyIter brackets) do
      if x = "(" then cnt := cnt +ₚ (1 : Int)
      if x = ")" then cnt := cnt -ₚ (1 : Int)
      if cnt < (0 : Int) then return Bool.false
    return cnt == (0 : Int) : Id Bool)

/-- If the scan accepts, the string has equally many `(` and `)`. -/
theorem correct_bracketing_correct :
    ⦃⌜True⌝⦄ correct_bracketing brackets ⦃⇓result =>
      ⌜result = true →
        (PastaLean.pyIter brackets).count "(" = (PastaLean.pyIter brackets).count ")"⌝⦄ := by
  mvcgen [correct_bracketing, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · Invariant.withEarlyReturn
        (onContinue := fun cur cnt =>
          ⌜cnt = (cur.prefix.count "(" : Int) - (cur.prefix.count ")" : Int)⌝)
        (onReturn := fun (r : Bool) _ =>
          ⌜r = true →
            (PastaLean.pyIter brackets).count "(" = (PastaLean.pyIter brackets).count ")"⌝)
  all_goals
    simp_all (config := { zetaDelta := true })
      [taste_ingr, pyTruthy, PyTruthy.truthy, PyHAdd.hAdd, PyHSub.hSub,
       List.count_append, List.count_cons, List.count_nil, List.count_singleton] <;>
      (first | omega | grind | (split_ifs <;> omega) | grind +locals)

end PastaBench.humaneval.CorrectBracketing61
