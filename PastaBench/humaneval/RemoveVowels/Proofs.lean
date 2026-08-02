import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RemoveVowels

def isVowel (c : Char) : Bool := c ∈ ['a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U']

def remove_vowels (s : List Char) : List Char := s.filter (fun c => !(isVowel c))

/-- No vowel survives, and the result is a sublist of the input (chars only removed). -/
theorem remove_vowels_no_vowels (s : List Char) (c : Char) :
    c ∈ remove_vowels s → isVowel c = false := by
  intro h
  have h2 := (List.mem_filter.mp h).2
  simpa using h2

end PastaBench.humaneval.RemoveVowels
