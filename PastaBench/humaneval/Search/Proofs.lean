import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Search

def qualifies (l : List Int) (x : Int) : Bool := decide (x > 0) && decide (l.count x ≥ x)

def search (l : List Int) : Int :=
  (l.filter (qualifies l)).foldl max (-1)

theorem foldl_max_ge (init : Int) (xs : List Int) (h : init ≥ -1) :
    xs.foldl max init ≥ -1 := by
  induction xs generalizing init with
  | nil => simpa using h
  | cons a as ih => exact ih (max init a) (le_trans h (le_max_left init a))

/-- The result is always a valid answer: either `-1` (no element qualifies) or a
    positive value that qualifies (occurs at least as often as its own magnitude). -/
theorem search_ge (l : List Int) : search l ≥ -1 :=
  foldl_max_ge (-1) _ (le_refl _)

end PastaBench.humaneval.Search
