import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FindZero

-- Horner-form polynomial: poly [c0,c1,...] x = c0 + c1*x + c2*x^2 + ...
def poly (xs : List ℚ) (x : ℚ) : ℚ := xs.foldr (fun c acc => c + x * acc) 0

theorem poly_nil (x : ℚ) : poly [] x = 0 := rfl

theorem poly_cons (c : ℚ) (xs : List ℚ) (x : ℚ) :
    poly (c :: xs) x = c + x * poly xs x := rfl

-- genuine evaluation lemmas
theorem poly_const (c : ℚ) (x : ℚ) : poly [c] x = c := by simp [poly]

theorem poly_linear (a b x : ℚ) : poly [a, b] x = a + b * x := by simp [poly]; ring

theorem poly_at_zero (xs : List ℚ) (x : ℚ) (h : xs ≠ []) :
    poly xs 0 = xs.head h := by
  cases xs with
  | nil => exact absurd rfl h
  | cons c t => simp [poly, List.head_cons]

-- a linear polynomial [a,b] with b ≠ 0 has an exact root at -a/b
theorem poly_root_linear (a b : ℚ) (hb : b ≠ 0) : poly [a, b] (-a / b) = 0 := by
  simp [poly]; field_simp; ring

end PastaBench.humaneval.FindZero
