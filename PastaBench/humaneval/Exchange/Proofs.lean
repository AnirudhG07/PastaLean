import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Exchange

/-- Number of odd entries in a list of integers. -/
def cntOdd (l : List Int) : Nat := (l.filter (fun x => x % 2 == 1)).length

/-- Number of even entries in a list of integers. -/
def cntEven (l : List Int) : Nat := (l.filter (fun x => x % 2 == 0)).length

/-- Exchange feasibility: we can make `lst1` all-even iff `lst2` has at least as
    many even numbers as `lst1` has odd numbers. -/
def exchange (lst1 lst2 : List Int) : String :=
  if cntOdd lst1 ≤ cntEven lst2 then "YES" else "NO"

/-- Correctness: the answer is `"YES"` exactly when there are enough even numbers
    in `lst2` to cover the odd numbers in `lst1`. -/
theorem exchange_correct (lst1 lst2 : List Int) :
    (exchange lst1 lst2 = "YES") ↔ cntOdd lst1 ≤ cntEven lst2 := by
  unfold exchange
  split <;> simp_all

/-- The result is always one of the two sentinel strings. -/
theorem exchange_range (lst1 lst2 : List Int) :
    exchange lst1 lst2 = "YES" ∨ exchange lst1 lst2 = "NO" := by
  unfold exchange
  split <;> simp

end PastaBench.humaneval.Exchange
