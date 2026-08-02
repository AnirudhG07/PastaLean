import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Fib

def fibSpec : Nat → Int
  | 0 => 0
  | 1 => 1
  | (n+2) => fibSpec n + fibSpec (n+1)

def fibPair : Nat → Int × Int
  | 0 => (0, 1)
  | (n+1) => let p := fibPair n; (p.2, p.1 + p.2)

def fibIter (n : Nat) : Int := (fibPair n).1

theorem fibPair_eq (n : Nat) : fibPair n = (fibSpec n, fibSpec (n+1)) := by
  induction n with
  | zero => rfl
  | succ k ih => simp only [fibPair, ih]; rfl

theorem fibIter_correct (n : Nat) : fibIter n = fibSpec n := by
  simp [fibIter, fibPair_eq]

example : fibIter 10 = 55 := by native_decide

end PastaBench.humaneval.Fib
