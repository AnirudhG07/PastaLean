import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ReverseDelete

def reverse_delete (s c : List Char) : List Char × Bool :=
  let ss := s.filter (fun ch => decide (ch ∉ c))
  (ss, ss == ss.reverse)

/-- The returned flag correctly reports whether the filtered string is a palindrome. -/
theorem reverse_delete_palindrome (s c : List Char) :
    (reverse_delete s c).2 = true ↔ (reverse_delete s c).1 = (reverse_delete s c).1.reverse := by
  simp [reverse_delete, beq_iff_eq]

/-- The filtered string contains no character from the deletion set `c`. -/
theorem reverse_delete_no_c (s c : List Char) (ch : Char) :
    ch ∈ (reverse_delete s c).1 → ch ∉ c := by
  intro h
  have h2 := (List.mem_filter.mp h).2
  simpa using h2

end PastaBench.humaneval.ReverseDelete
