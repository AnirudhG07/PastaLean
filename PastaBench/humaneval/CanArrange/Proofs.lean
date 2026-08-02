import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CanArrange

def can_arrange := fun (arr : List Int) ↦
  (do
    for i in (PastaLean.pyRange (0 : Int) (PastaLean.pyLen arr -ₚ (1 : Int)) (-(1 : Int)))do
      let _ := Libraries.passta.pyPassInvariant (decide ((1 : Int) ≤ i) && decide (i < PastaLean.pyLen arr))
      let _ := Libraries.passta.pyPassDecreases i
      if h_1 : ¬arr⦋i⦌ ≥ arr⦋i -ₚ (1 : Int)⦌ then
        return i
      else
        let _ := ()
    let __py_ret_1 := -(1 : Int)
    return __py_ret_1 : Id _)

/-- Correctness on the reference examples: largest index i with arr[i] < arr[i-1], else -1. -/
theorem can_arrange_probe1 : (can_arrange [(1:Int), 2, 4, 3, 5]).run = 3 := by native_decide
theorem can_arrange_probe2 : (can_arrange [(1:Int), 2, 4, 5]).run = -1 := by native_decide
theorem can_arrange_probe3 : (can_arrange [(1:Int), 4, 2, 5, 6, 7, 8, 9, 10]).run = 2 := by native_decide

end PastaBench.humaneval.CanArrange
