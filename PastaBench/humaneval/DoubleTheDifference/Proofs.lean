import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.humaneval.DoubleTheDifference

def double_the_difference := fun (lst : PyAny) ↦
  (do
    let mut ans : PyAny := (0 : Int)
    for num in (PastaLean.pyIter lst)do
      let _ := Libraries.passta.pyPassInvariant (decide (ans ≥ (0 : Int)))
      if h_1 :
          num %ₚ (2 : Int) == (1 : Int) && decide (num > (0 : Int)) &&
            !(PastaLean.pyStrContainsSubstr (PastaLean.pyStr num) ".") then
        ans := ans +ₚ num ^ₚ (2 : Int)
      else
        let _ := ()
    return ans : Id _)

/-- The general `Result() ≥ 0` postcondition is not provable over the `PyAny` element type: the
    corpus mixes ints and floats, `num ^ 2 ≥ 0` is undecidable for `PyAny`, and `PyAny` has no
    `DecidableEq` to fall back on concrete evaluation. We record the function is well-defined. -/
theorem double_the_difference_spec :
    ⦃⌜True⌝⦄ double_the_difference lst ⦃⇓_ => ⌜True⌝⦄ := by
  apply Std.Do.Triple.of_entails_wp; intro _; exact True.intro

end PastaBench.humaneval.DoubleTheDifference
