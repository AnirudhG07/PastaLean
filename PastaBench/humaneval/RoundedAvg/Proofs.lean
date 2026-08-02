import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RoundedAvg

def rounded_avg (n m : Int) : Int := if n > m then -1 else (n + m) / 2

theorem rounded_avg_correct (n m : Int) :
    (n > m → rounded_avg n m = -1) ∧
    (n ≤ m → n ≤ rounded_avg n m ∧ rounded_avg n m ≤ m) := by
  unfold rounded_avg
  refine ⟨?_, ?_⟩ <;> intro h <;> split <;> omega

end PastaBench.humaneval.RoundedAvg
