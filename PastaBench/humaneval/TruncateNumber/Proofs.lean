import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.TruncateNumber

def truncate_number := fun (number : Rat) ↦ (number -ₚ PastaLean.pyInt number : Rat)

theorem truncate_number_correct :
    ∀ (number : Rat), number ≥ (0 : Int) →
      (0 : Rat) ≤ truncate_number number ∧ truncate_number number < (1 : Rat) := by
  intro number _
  simp only [truncate_number, PyHSub.hSub, PastaLean.pyInt, PyIntCast.pyInt]
  constructor
  · have h := Int.floor_le number
    linarith
  · have h := Int.lt_floor_add_one number
    linarith

end PastaBench.humaneval.TruncateNumber
