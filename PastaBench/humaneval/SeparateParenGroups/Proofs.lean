import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SeparateParenGroups

/-- Contribution of a single character to the parenthesis balance. -/
def parenVal (c : Char) : Int := if c = '(' then 1 else if c = ')' then -1 else 0

/-- Running parenthesis balance of a string: `#'(' - #')'`. This is the `cnt`
    quantity threaded through `separate_paren_groups`. -/
def balance (s : List Char) : Int := (s.map parenVal).sum

/-- The balance is additive over concatenation — the invariant that lets the
    algorithm cut the input at every point where the balance returns to zero. -/
theorem balance_append (s t : List Char) :
    balance (s ++ t) = balance s + balance t := by
  simp [balance, List.map_append, List.sum_append]

/-- Balance of the empty group is zero; appending a balanced group preserves balance. -/
theorem balance_nil : balance [] = 0 := by simp [balance]

end PastaBench.humaneval.SeparateParenGroups
