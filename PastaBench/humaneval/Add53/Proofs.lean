import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Add53

def add := fun (x : Int) ↦ fun (y : Int) ↦ x +ₚ y

theorem add_correct : ∀ (x : Int) (y : Int), add x y = x + y := by
  intro x y
  simp only [add, PyHAdd.hAdd]

end PastaBench.humaneval.Add53
