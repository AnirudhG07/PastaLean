import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.humaneval.CarRaceCollision
def car_race_collision := fun (n : Int) ↦ n ^ₚ (2 : Int)
theorem car_race_collision_correct : ∀ (n : Int), n ≥ 0 → car_race_collision n = n * n := by
  intro n _
  simp only [car_race_collision, PyHPow.hPow]
  show n ^ (2:Nat) = n * n
  rw [pow_two]
end PastaBench.humaneval.CarRaceCollision
