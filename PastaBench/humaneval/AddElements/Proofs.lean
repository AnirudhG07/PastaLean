import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.AddElements

private def _add_elements'digits := fun (x : Int) ↦
  let s := (PastaLean.pyStr x : String)
  if s⦋(0 : Int)⦌ = "-" then PastaLean.pyLen s -ₚ (1 : Int) else PastaLean.pyLen s

def add_elements := fun (arr : List Int) ↦ fun (k : Int) ↦
  PastaLean.pySum
    (PastaLean.pyFilter (fun x ↦ decide (_add_elements'digits x ≤ (2 : Int)))
      (PastaLean.pySlice arr none (some k) none))

/-- The digit-count helper returns 1 for every single-digit natural number. -/
theorem digits_single : ∀ (x : Int), 0 ≤ x → x ≤ 9 → _add_elements'digits x = 1 := by
  intro x h1 h2
  interval_cases x <;> native_decide

/-- Correctness on the reference examples: sum of the ≤2-digit numbers among the first k. -/
theorem add_elements_probe1 :
    add_elements [(1:Int), -2, -3, 41, 57, 76, 87, 88, 99] 3 = -4 := by native_decide
theorem add_elements_probe2 :
    add_elements [(111:Int), 121, 3, 4000, 5, 6] 2 = 0 := by native_decide
theorem add_elements_probe3 :
    add_elements [(11:Int), 21, 3, 90, 5, 6, 7, 8, 9] 4 = 125 := by native_decide

end PastaBench.humaneval.AddElements
