import PastaLean
import PastaLean.PyAPI.Operators

open PastaLean

/-! Python's `&`/`|`/`^` on integers are ARBITRARY-PRECISION two's complement, not fixed 64-bit: a
non-negative result never becomes negative (`reduce(or_, big)` stays positive) and nothing truncates. -/

#guard (pyBitOr (5 : Int) (3 : Int) : Int) == 7
#guard (pyBitAnd (-1 : Int) (5 : Int) : Int) == 5
#guard (pyBitOr (-1 : Int) (5 : Int) : Int) == -1
#guard (pyBitXor (12 : Int) (10 : Int) : Int) == 6
#guard (pyBitAnd (-5 : Int) (3 : Int) : Int) == 3
#guard (pyBitXor (-8 : Int) (-3 : Int) : Int) == 5
-- 2^64-1: the old fixed-64-bit model wrongly re-signed this to -1.
#guard (pyBitOr ((2 ^ 64 - 1 : Nat) : Int) (1 : Int) : Int) == ((2 ^ 64 - 1 : Nat) : Int)
-- Wider than 64 bits: no truncation.
#guard (pyBitOr ((2 ^ 70 : Nat) : Int) (1 : Int) : Int) == ((2 ^ 70 + 1 : Nat) : Int)

/-! Python's `//` floors and `%` takes the DIVISOR's sign. Lean's own `/` and `%` on `Int` are
Euclidean (`7 / -2 = -3`, `7 % -2 = 1`), so the mixed-sign cases are where they diverge. -/

#guard (pyFloorDiv (-7 : Int) (2 : Int) : Int) == -4   -- Python: -7 // 2 == -4
#guard (pyFloorDiv (7 : Int) (-2 : Int) : Int) == -4   -- Python:  7 // -2 == -4
#guard pyMod (-7) 2 == 1                               -- Python: -7 % 2 == 1
#guard pyMod 7 (-2) == -1                              -- Python:  7 % -2 == -1
#guard pyRatMod (-11/2) 2 == 1/2                       -- Python: -5.5 % 2 == 0.5

/-! Python's `round` breaks ties to EVEN, unlike Mathlib's half-up `round`. -/

#guard pyRound 0.5 == 0
#guard pyRound 1.5 == 2
#guard pyRound 2.5 == 2
#guard pyRound (-2.5) == -2
#guard pyRound 2.6 == 3
