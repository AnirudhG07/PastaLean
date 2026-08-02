import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.LargestPrimeFactor

def largest_prime_factor := fun (n : Int) ↦
  (do
    let mut isprime : List Bool := PastaLean.pyListRepeat [Bool.true] (n +ₚ (1 : Int))
    for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (2 : Int))do
      if h_1 : PastaLean.pyTruthy isprime⦋i⦌ then
        for j in (PastaLean.pyRange n (i +ₚ i) i)do
          isprime := PastaLean.pySetItem isprime j Bool.false
      else
        let _ := ()
    for i in (PastaLean.pyRange (0 : Int) (n -ₚ (1 : Int)) (-(1 : Int)))do
      if h_1 : PastaLean.pyTruthy isprime⦋i⦌ = true ∧ n %ₚ i = (0 : Int) then
        return i
      else
        let _ := ()
    return default : Id _)

-- Largest prime factor via a sieve (n composite, n > 1).
theorem largest_prime_factor_correct :
    (largest_prime_factor 15).run = 5
      ∧ (largest_prime_factor 27).run = 3
      ∧ (largest_prime_factor 63).run = 7
      ∧ (largest_prime_factor 100).run = 5
      ∧ (largest_prime_factor 121).run = 11 := by
  native_decide

end PastaBench.humaneval.LargestPrimeFactor
