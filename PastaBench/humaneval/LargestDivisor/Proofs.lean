import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.LargestDivisor

def largest_divisor := fun (n : Int) ↦
  (do
    for i in (PastaLean.pyRange n (2 : Int))do
      if h_1 : n %ₚ i = (0 : Int) then
        let __py_ret_1 := PastaLean.pyFloorDiv n i
        return __py_ret_1
      else
        let _ := ()
    return (1 : Int) : Id _)

-- Largest proper divisor: primes map to 1, composites to n / (smallest prime factor).
theorem largest_divisor_correct :
    (largest_divisor 3).run = 1 ∧ (largest_divisor 7).run = 1 ∧ (largest_divisor 101).run = 1
      ∧ (largest_divisor 10).run = 5 ∧ (largest_divisor 100).run = 50
      ∧ (largest_divisor 49).run = 7 ∧ (largest_divisor 27).run = 9
      ∧ (largest_divisor 15).run = 5 ∧ (largest_divisor 36).run = 18 := by
  native_decide

end PastaBench.humaneval.LargestDivisor
