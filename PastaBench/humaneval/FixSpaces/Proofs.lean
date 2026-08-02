import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FixSpaces

def replaceChar (c d : Char) : List Char → List Char
  | [] => []
  | (x :: xs) => (if x = c then d else x) :: replaceChar c d xs

theorem replaceChar_removes (c d : Char) (h : c ≠ d) (l : List Char) :
    c ∉ replaceChar c d l := by
  induction l with
  | nil => simp only [replaceChar]; exact List.not_mem_nil
  | cons x xs ih =>
    simp only [replaceChar, List.mem_cons, not_or]
    refine ⟨fun heq => ?_, ih⟩
    split at heq
    · exact h heq
    · rename_i hne; exact hne heq.symm

-- collapse maximal runs of ≥3 spaces to a single '-', leaving shorter runs of
-- spaces in place (the final replaceChar turns those remaining spaces into '_').
def flushSpaces (cnt : Nat) : List Char :=
  if cnt ≥ 3 then ['-'] else List.replicate cnt ' '

def collapseGo : Nat → List Char → List Char
  | cnt, [] => flushSpaces cnt
  | cnt, (c :: rest) =>
    if c = ' ' then collapseGo (cnt + 1) rest
    else flushSpaces cnt ++ c :: collapseGo 0 rest

def collapse (l : List Char) : List Char := collapseGo 0 l

def fixSpacesChars (l : List Char) : List Char := replaceChar ' ' '_' (collapse l)

def fixSpaces (text : String) : String := String.ofList (fixSpacesChars text.toList)

-- the character-level no-space property (the genuine content)
theorem fixSpacesChars_no_space (l : List Char) : ' ' ∉ fixSpacesChars l := by
  unfold fixSpacesChars
  exact replaceChar_removes ' ' '_' (by decide) _

theorem fixSpaces_no_space (text : String) : ' ' ∉ (fixSpaces text).toList := by
  unfold fixSpaces
  rw [String.toList_ofList]
  exact fixSpacesChars_no_space _

end PastaBench.humaneval.FixSpaces
