import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Solve84

def solve := fun (N : Int) ↦
  let s := PastaLean.pySum (PastaLean.pyMap (fun x ↦ PastaLean.pyInt x) (PastaLean.pyStr N))
  PastaLean.pySlice (PastaLean.pyBin s) (some (2 : Int)) none none

theorem solve_correct :
    solve 1000 = "1" ∧ solve 150 = "110" ∧ solve 147 = "1100" ∧
      solve 333 = "1001" ∧ solve 963 = "10010" ∧ solve 9999 = "100100" := by
  native_decide

end PastaBench.humaneval.Solve84
