import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ChangeBase

def change_base := fun (x : Int) ↦ fun (base : Int) ↦
  (do
    let mut x := x
    if h_1 : x = (0 : Int) then
      return "0"
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (x > (0 : Int)))
    let mut ret : String := ""
    while (x ≠ (0 : Int)) do
      let _ := Libraries.passta.pyPassInvariant (decide (x > (0 : Int)))
      let _ := Libraries.passta.pyPassDecreases x
      ret := PastaLean.pyStr (x %ₚ base) +ₚ ret
      x := PastaLean.pyFloorDiv x base
    let _ := Libraries.passta.pyPassAssert (ret != "")
    return ret : Id _)

/-- Correctness on the reference examples: base conversion to a digit string. -/
theorem change_base_zero : (change_base 0 3).run = "0" := by native_decide
theorem change_base_probe1 : (change_base 8 3).run = "22" := by native_decide
theorem change_base_probe2 : (change_base 9 3).run = "100" := by native_decide
theorem change_base_probe3 : (change_base 234 2).run = "11101010" := by native_decide

end PastaBench.humaneval.ChangeBase
