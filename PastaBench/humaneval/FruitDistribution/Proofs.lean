import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FruitDistribution

/-- Number of mangoes = total fruit minus the parsed apple and orange counts. -/
def fruit_distribution := fun (s : String) ↦ fun (n : Int) ↦
  (do
    let words : List String := PastaLean.pyStringSplit s " "
    let c1 : Int := PastaLean.pyInt words⦋(0 : Int)⦌
    let c2 : Int := PastaLean.pyInt words⦋(3 : Int)⦌
    return n -ₚ c1 -ₚ c2 : Id Int)

/-- Exact output characterization: the result is `n - apples - oranges`. -/
theorem fruit_distribution_value (s : String) (n : Int) :
    (fruit_distribution s n).run
      = n - PastaLean.pyInt (PastaLean.pyStringSplit s " ")⦋(0 : Int)⦌
          - PastaLean.pyInt (PastaLean.pyStringSplit s " ")⦋(3 : Int)⦌ := rfl

/-- When the counted fruit does not exceed the total, the mango count is non-negative. -/
theorem fruit_distribution_correct (s : String) (n : Int)
    (h : PastaLean.pyInt (PastaLean.pyStringSplit s " ")⦋(0 : Int)⦌
        + PastaLean.pyInt (PastaLean.pyStringSplit s " ")⦋(3 : Int)⦌ ≤ n) :
    (fruit_distribution s n).run ≥ 0 := by
  rw [fruit_distribution_value]
  omega

end PastaBench.humaneval.FruitDistribution
