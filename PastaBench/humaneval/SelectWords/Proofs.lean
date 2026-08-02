import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SelectWords

def isVowel (c : Char) : Bool := c ∈ ['a', 'e', 'i', 'o', 'u', 'A', 'E', 'I', 'O', 'U']

/-- Number of consonants in a word. -/
def consonants (w : List Char) : Nat := (w.filter (fun ch => !(isVowel ch))).length

/-- Given a list of words, keep exactly those with `n` consonants. -/
def select_words (ws : List (List Char)) (n : Nat) : List (List Char) :=
  ws.filter (fun w => consonants w == n)

/-- Every selected word has exactly `n` consonants. -/
theorem select_words_correct (ws : List (List Char)) (n : Nat) (w : List Char) :
    w ∈ select_words ws n → consonants w = n := by
  intro h
  have h2 := (List.mem_filter.mp h).2
  simpa [beq_iff_eq] using h2

end PastaBench.humaneval.SelectWords
