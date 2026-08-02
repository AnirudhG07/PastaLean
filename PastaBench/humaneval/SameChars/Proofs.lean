import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SameChars

def same_chars (s0 s1 : List Char) : Bool :=
  s0.all (fun c => decide (c ∈ s1)) && s1.all (fun c => decide (c ∈ s0))

/-- `same_chars` is true iff the two strings have exactly the same character sets. -/
theorem same_chars_correct (s0 s1 : List Char) :
    same_chars s0 s1 = true ↔ ((∀ c ∈ s0, c ∈ s1) ∧ (∀ c ∈ s1, c ∈ s0)) := by
  simp [same_chars, List.all_eq_true, decide_eq_true_eq]

end PastaBench.humaneval.SameChars
