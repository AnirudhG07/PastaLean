import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FilterIntegers

/-- A minimal model of "any Python value": either an integer or something else. -/
inductive Val where
  | int (n : Int)
  | other
  deriving DecidableEq

/-- Mirrors Python's `type(x) == int`. -/
def isInt : Val → Bool
  | .int _ => true
  | .other => false

/-- Keep only the integer-valued entries. -/
def filterIntegers (values : List Val) : List Val := values.filter isInt

/-- Membership characterization: a value is in the result iff it was in the input
    and it is an integer. -/
theorem filterIntegers_mem (values : List Val) (v : Val) :
    v ∈ filterIntegers values ↔ (v ∈ values ∧ isInt v = true) := by
  simp [filterIntegers, List.mem_filter]

/-- Every element of the result is an integer. -/
theorem filterIntegers_all_int (values : List Val) :
    ∀ v ∈ filterIntegers values, isInt v = true := by
  intro v hv
  exact ((filterIntegers_mem values v).1 hv).2

/-- The result is a sublist (every element came from the input). -/
theorem filterIntegers_subset (values : List Val) :
    ∀ v ∈ filterIntegers values, v ∈ values := by
  intro v hv
  exact ((filterIntegers_mem values v).1 hv).1

end PastaBench.humaneval.FilterIntegers
