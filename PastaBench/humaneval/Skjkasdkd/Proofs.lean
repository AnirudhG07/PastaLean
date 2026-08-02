import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Skjkasdkd

/-- Sum of the base-10 digits of `n` — the value returned for the largest prime. -/
def digitSum (n : Nat) : Nat := (Nat.digits 10 n).sum

/-- Casting out nines: the digit sum is congruent to the number itself mod 9.
    A genuine correctness property of the digit-sum computation. -/
theorem digitSum_mod_nine (n : Nat) : digitSum n % 9 = n % 9 := by
  have h := Nat.modEq_digits_sum 9 10 (by norm_num) n
  simpa [digitSum, Nat.ModEq] using h.symm

end PastaBench.humaneval.Skjkasdkd
