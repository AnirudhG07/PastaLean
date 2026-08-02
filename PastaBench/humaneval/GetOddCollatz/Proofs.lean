import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.GetOddCollatz

/-- Faithful model of the Python solution. The loop is a Collatz iteration, whose
termination for all `n` is an open mathematical problem, so no universally-quantified
`.run` characterization is provable; we verify the actual reference outputs instead. -/
def get_odd_collatz := fun (n : Int) ↦
  (do
    let mut ans : List Int := []
    let mut x := n
    while (x ≠ (1 : Int)) do
      let _ := Libraries.passta.pyPassInvariant (decide (x > (0 : Int)))
      if h_1 : x %ₚ (2 : Int) = (1 : Int) then
        ans := PastaLean.pyAppend ans x
      else
        let _ := ()
      x := if x %ₚ (2 : Int) = (0 : Int) then PastaLean.pyFloorDiv x (2 : Int) else x *ₚ (3 : Int) +ₚ (1 : Int)
    ans := PastaLean.pyAppend ans (1 : Int)
    let __py_ret_1 := PastaLean.pySort ans
    return __py_ret_1 : Id _)

/-- Non-trivial correctness on the reference examples: the result is the sorted list of odd
numbers occurring in the Collatz sequence of `n`. -/
theorem get_odd_collatz_probe1 : (get_odd_collatz 5).run = [1, 5] := by native_decide
theorem get_odd_collatz_probe2 : (get_odd_collatz 14).run = [1, 5, 7, 11, 13, 17] := by native_decide
theorem get_odd_collatz_probe3 : (get_odd_collatz 12).run = [1, 3, 5] := by native_decide
theorem get_odd_collatz_probe4 : (get_odd_collatz 1).run = [1] := by native_decide
theorem get_odd_collatz_probe5 : (get_odd_collatz 15).run = [1, 5, 15, 23, 35, 53] := by native_decide
theorem get_odd_collatz_probe6 : (get_odd_collatz 3).run = [1, 3, 5] := by native_decide

end PastaBench.humaneval.GetOddCollatz
