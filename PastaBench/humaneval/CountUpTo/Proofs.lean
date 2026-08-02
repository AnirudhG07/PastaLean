import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.CountUpTo

def isPrime (a : Nat) : Bool := 2 ≤ a && (List.range a).all (fun x => x < 2 || a % x != 0)

/-- The primes strictly less than `n`. -/
def count_up_to (n : Nat) : List Nat := (List.range n).filter isPrime

theorem count_up_to_correct :
    count_up_to 5 = [2,3] ∧ count_up_to 6 = [2,3,5] ∧ count_up_to 7 = [2,3,5] ∧
    count_up_to 10 = [2,3,5,7] ∧ count_up_to 0 = [] ∧
    count_up_to 22 = [2,3,5,7,11,13,17,19] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- General property: every returned number is prime and strictly below `n`. -/
theorem count_up_to_all_prime (n p : Nat) (hp : p ∈ count_up_to n) : isPrime p = true :=
  (List.mem_filter.mp hp).2
theorem count_up_to_lt (n p : Nat) (hp : p ∈ count_up_to n) : p < n :=
  List.mem_range.mp (List.mem_filter.mp hp).1

end PastaBench.humaneval.CountUpTo
