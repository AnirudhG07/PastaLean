import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Simplify

def simplify (x1 x2 n1 n2 : Int) : Bool := (x1 * n1) % (x2 * n2) == 0

theorem simplify_correct (x1 x2 n1 n2 : Int) :
    simplify x1 x2 n1 n2 = true ↔ (x2 * n2) ∣ (x1 * n1) := by
  rw [simplify, beq_iff_eq, Int.dvd_iff_emod_eq_zero]

end PastaBench.humaneval.Simplify
