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
