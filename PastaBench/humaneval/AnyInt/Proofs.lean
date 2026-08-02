import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.AnyInt

/-- All three arguments are integers (the `type(...) != int` guard is vacuously
    false for `Int` inputs), so `any_int` reduces to the sum-of-the-other-two test. -/
def any_int := fun (x : Int) ↦ fun (y : Int) ↦ fun (z : Int) ↦
  decide (x = y + z) || decide (y = x + z) || decide (z = x + y)

theorem any_int_correct :
    ∀ (x y z : Int),
      any_int x y z = true ↔ (x = y + z ∨ y = x + z ∨ z = x + y) := by
  intro x y z
  simp only [any_int, Bool.or_eq_true, decide_eq_true_eq]
  tauto

end PastaBench.humaneval.AnyInt
