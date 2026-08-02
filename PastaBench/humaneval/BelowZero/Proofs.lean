import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.BelowZero

def below_zero := fun (operations : List Int) ↦
  (do
    let mut account : Int := (0 : Int)
    for operation in (PastaLean.pyIter operations)do
      let _ := Libraries.passta.pyPassInvariant (decide (account ≥ (0 : Int)))
      account := account +ₚ operation
      if h_1 : account < (0 : Int) then
        return Bool.true
      else
        let _ := ()
    return Bool.false : Id _)

/-- Correctness on the reference examples: detects a running balance dropping below zero. -/
theorem below_zero_empty : (below_zero []).run = false := by native_decide
theorem below_zero_probe1 : (below_zero [(1:Int), 2, -3, 1, 2, -3]).run = false := by native_decide
theorem below_zero_probe2 : (below_zero [(1:Int), 2, -4, 5, 6]).run = true := by native_decide

end PastaBench.humaneval.BelowZero
