import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RightAngleTriangle

def right_angle_triangle (a b c : Int) : Bool :=
  (a^2 + b^2 == c^2) || (a^2 + c^2 == b^2) || (b^2 + c^2 == a^2)

theorem right_angle_triangle_correct (a b c : Int) :
    right_angle_triangle a b c = true ↔
      (a ^ 2 + b ^ 2 = c ^ 2 ∨ a ^ 2 + c ^ 2 = b ^ 2 ∨ b ^ 2 + c ^ 2 = a ^ 2) := by
  simp [right_angle_triangle, beq_iff_eq, or_assoc]

end PastaBench.humaneval.RightAngleTriangle
