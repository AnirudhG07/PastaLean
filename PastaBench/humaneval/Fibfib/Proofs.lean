import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Fibfib

def fibfibSpec : Nat → Int
  | 0 => 0
  | 1 => 0
  | 2 => 1
  | (n+3) => fibfibSpec n + fibfibSpec (n+1) + fibfibSpec (n+2)

def fibfibTriple : Nat → Int × Int × Int
  | 0 => (0, 0, 1)
  | (n+1) => let p := fibfibTriple n; (p.2.1, p.2.2, p.1 + p.2.1 + p.2.2)

def fibfibIter (n : Nat) : Int := (fibfibTriple n).1

theorem fibfibTriple_eq (n : Nat) :
    fibfibTriple n = (fibfibSpec n, fibfibSpec (n+1), fibfibSpec (n+2)) := by
  induction n with
  | zero => rfl
  | succ k ih => simp only [fibfibTriple, ih]; rfl

theorem fibfibIter_correct (n : Nat) : fibfibIter n = fibfibSpec n := by
  simp [fibfibIter, fibfibTriple_eq]

example : fibfibIter 8 = 24 := by native_decide

end PastaBench.humaneval.Fibfib
