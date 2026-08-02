import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.XOrY

-- Faithful primality test: `a` is prime iff `a ≥ 2` and no `d ∈ [2, a)` divides `a`
-- (the mathematical characterization stated in the contract; the original `int(a**0.5)`
-- bound has no computable Lean power instance).
private def _x_or_y'is_prime := fun (a : Int) ↦
  !if PastaLean.pyTruthy (decide (a < (2 : Int))) then decide (a < (2 : Int))
    else
      PastaLean.pyStdAny
        ((PastaLean.pyRange a (2 : Int)).map fun x =>
          a %ₚ x == (0 : Int))

def x_or_y := fun (n : Int) ↦ fun (x : Int) ↦ fun (y : Int) ↦ if PastaLean.pyTruthy (_x_or_y'is_prime n) then x else y

theorem x_or_y_correct :
    ∀ (n : Int) (x y : Int),
      (_x_or_y'is_prime n = true → x_or_y n x y = x) ∧
        (_x_or_y'is_prime n = false → x_or_y n x y = y) := by
  intro n x y
  constructor <;> intro h <;>
    simp [x_or_y, pyTruthy, PyTruthy.truthy, h]

end PastaBench.humaneval.XOrY
