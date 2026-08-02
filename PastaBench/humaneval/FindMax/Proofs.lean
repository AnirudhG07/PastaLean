import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FindMax

def uniqCount (s : String) : Nat := s.toList.dedup.length

def better (cand best : String) : Bool :=
  decide (uniqCount best < uniqCount cand) ||
  (decide (uniqCount cand = uniqCount best) && decide (cand < best))

def step (best : String) (w : String) : String := if better w best then w else best

def findMax (words : List String) : String := words.foldl step ""

theorem foldl_step_mem (words : List String) (acc : String) :
    words.foldl step acc = acc ∨ words.foldl step acc ∈ words := by
  induction words generalizing acc with
  | nil => left; rfl
  | cons w ws ih =>
    simp only [List.foldl_cons]
    rcases ih (step acc w) with h | h
    · rw [h]
      unfold step
      split
      · right; exact List.mem_cons.mpr (Or.inl rfl)
      · left; rfl
    · right; exact List.mem_cons.mpr (Or.inr h)

theorem findMax_correct (words : List String) :
    findMax words = "" ∨ findMax words ∈ words := by
  unfold findMax
  rcases foldl_step_mem words "" with h | h
  · left; exact h
  · right; exact h

end PastaBench.humaneval.FindMax
