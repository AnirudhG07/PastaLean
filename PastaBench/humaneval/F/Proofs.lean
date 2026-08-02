import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.F

/-- Value at 1-indexed position `i`: factorial i if i even, else 1+2+...+i. -/
def term (i : Nat) : Int :=
  if i % 2 == 0 then (Nat.factorial i : Int)
  else (i * (i + 1) / 2 : Int)

/-- Build `[term 1, term 2, ..., term n]`. -/
def build (n : Nat) : List Int := (List.range n).map (fun k => term (k + 1))

def f (n : Nat) : List Int := build n

/-- Universal length theorem: `f n` has length `n`. -/
theorem f_length (n : Nat) : (f n).length = n := by
  simp [f, build]

/-- Docstring instance: f 5 = [1,2,6,24,15]. -/
theorem f_5 : f 5 = [1, 2, 6, 24, 15] := by native_decide

/-- Odd-tail instance: f 7 = [1,2,6,24,15,720,28]. -/
theorem f_7 : f 7 = [1, 2, 6, 24, 15, 720, 28] := by native_decide

/-- Base cases match the Python spec. -/
theorem f_0 : f 0 = [] := by native_decide
theorem f_1 : f 1 = [1] := by native_decide
theorem f_2 : f 2 = [1, 2] := by native_decide

end PastaBench.humaneval.F
