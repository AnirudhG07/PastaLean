import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.PrimeLength

private def is_prime := fun (a : Int) ↦
  !if PastaLean.pyTruthy (decide (a < (2 : Int))) then decide (a < (2 : Int))
    else
      PastaLean.pyStdAny
        ((PastaLean.pyRange (PastaLean.pyInt (a ^ₚ (0.5 : Float)) +ₚ (1 : Int)) (2 : Int)).map fun x =>
          a %ₚ x == (0 : Int))

def prime_length := fun (string : String) ↦ is_prime (PastaLean.pyLen string)

/-- Correctness: returns `True` iff the string length is prime, checked on the
    reference test cases. -/
theorem prime_length_correct :
    prime_length "Hello" = true ∧
    prime_length "abcdcba" = true ∧
    prime_length "kittens" = true ∧
    prime_length "orange" = false ∧
    prime_length "wow" = true ∧
    prime_length "" = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.PrimeLength
