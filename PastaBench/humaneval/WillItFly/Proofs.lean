import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.WillItFly

def will_it_fly := fun (q : List Int) ↦ fun (w : Int) ↦
  if PastaLean.pyTruthy (q == PastaLean.pySlice q none none (some (-(1 : Int)))) then decide (PastaLean.pySum q ≤ w)
  else q == PastaLean.pySlice q none none (some (-(1 : Int)))

theorem will_it_fly_correct :
    ∀ (q : List Int) (w : Int),
      will_it_fly q w = true ↔
        ((q == PastaLean.pySlice q none none (some (-(1 : Int)))) = true ∧ PastaLean.pySum q ≤ w) := by
  intro q w
  simp only [will_it_fly, pyTruthy, PyTruthy.truthy]
  cases h : (q == PastaLean.pySlice q none none (some (-(1 : Int)))) <;>
    simp [h, decide_eq_true_iff]

end PastaBench.humaneval.WillItFly
