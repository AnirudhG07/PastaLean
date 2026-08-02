import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Fib4

def fib4Spec : Nat → Int
  | 0 => 0
  | 1 => 0
  | 2 => 2
  | 3 => 0
  | (n+4) => fib4Spec n + fib4Spec (n+1) + fib4Spec (n+2) + fib4Spec (n+3)

def fib4Quad : Nat → Int × Int × Int × Int
  | 0 => (0, 0, 2, 0)
  | (n+1) => let p := fib4Quad n; (p.2.1, p.2.2.1, p.2.2.2, p.1 + p.2.1 + p.2.2.1 + p.2.2.2)

def fib4Iter (n : Nat) : Int := (fib4Quad n).1

theorem fib4Quad_eq (n : Nat) :
    fib4Quad n = (fib4Spec n, fib4Spec (n+1), fib4Spec (n+2), fib4Spec (n+3)) := by
  induction n with
  | zero => rfl
  | succ k ih => simp only [fib4Quad, ih]; rfl

theorem fib4Iter_correct (n : Nat) : fib4Iter n = fib4Spec n := by
  simp [fib4Iter, fib4Quad_eq]

example : fib4Iter 8 = 28 := by native_decide

end PastaBench.humaneval.Fib4
