import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsMultiplyPrime

def isPrime (k : Nat) : Bool := 2 ≤ k && (List.range k).all (fun x => x < 2 || k % x != 0)

/-- True iff `a` is a product of exactly three primes (with multiplicity). -/
def is_multiply_prime (a : Nat) : Bool :=
  let ps := (List.range (a + 1)).filter isPrime
  ps.any (fun p => ps.any (fun q => ps.any (fun r => p * q * r == a)))

theorem is_multiply_prime_correct :
    is_multiply_prime 5 = false ∧ is_multiply_prime 30 = true ∧ is_multiply_prime 8 = true ∧
    is_multiply_prime 10 = false ∧ is_multiply_prime 33 = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- Soundness: a true answer exhibits three factors whose product is `a`. -/
theorem is_multiply_prime_sound (a : Nat) (h : is_multiply_prime a = true) :
    ∃ p q r, p * q * r = a := by
  unfold is_multiply_prime at h
  rw [List.any_eq_true] at h; obtain ⟨p, _, h⟩ := h
  rw [List.any_eq_true] at h; obtain ⟨q, _, h⟩ := h
  rw [List.any_eq_true] at h; obtain ⟨r, _, h⟩ := h
  exact ⟨p, q, r, by simpa using h⟩

end PastaBench.humaneval.IsMultiplyPrime
