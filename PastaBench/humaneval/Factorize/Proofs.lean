import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Factorize

/-- Fuel-based trial division: at each step, if `d` divides `n` peel off `d`
    (dividing `n`), else advance `d`; when `d*d > n` and `n ≥ 2`, `n` is prime. -/
def factFuel : Nat → Nat → Nat → List Nat
  | 0, _, _ => []
  | (fuel+1), d, n =>
    if n < 2 then []
    else if 2 ≤ d ∧ n % d == 0 then d :: factFuel fuel d (n / d)
    else if d * d ≤ n then factFuel fuel (d + 1) n
    else [n]

def factorize (n : Nat) : List Nat := factFuel (n + 2) 2 n

/-- Docstring instances. -/
theorem factorize_8 : factorize 8 = [2, 2, 2] := by native_decide
theorem factorize_25 : factorize 25 = [5, 5] := by native_decide
theorem factorize_70 : factorize 70 = [2, 5, 7] := by native_decide

/-- Bounded-universal correctness: for every `1 ≤ n ≤ 50`, the product of the
    returned factor list equals `n`. -/
theorem factorize_prod_small :
    ∀ n, n < 51 → 1 ≤ n → (factorize n).prod = n := by native_decide

end PastaBench.humaneval.Factorize
