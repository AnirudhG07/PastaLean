import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FindClosestElements

def closestAux (pairs : List (ℚ × ℚ)) : Option (ℚ × ℚ) :=
  pairs.foldl
    (fun acc p =>
      match acc with
      | none => some p
      | some q => if p.2 - p.1 < q.2 - q.1 then some p else some q)
    none

def adjPairs (l : List ℚ) : List (ℚ × ℚ) := l.zip l.tail

def findClosest (numbers : List ℚ) : Option (ℚ × ℚ) :=
  closestAux (adjPairs (numbers.mergeSort (· ≤ ·)))

theorem closestAux_mem (pairs : List (ℚ × ℚ)) :
    ∀ p, closestAux pairs = some p → p ∈ pairs := by
  unfold closestAux
  suffices H : ∀ (ps : List (ℚ × ℚ)) (acc : Option (ℚ × ℚ)),
      (∀ q, acc = some q → q ∈ pairs) →
      (∀ q ∈ ps, q ∈ pairs) →
      ∀ p, ps.foldl (fun acc p => match acc with
        | none => some p
        | some q => if p.2 - p.1 < q.2 - q.1 then some p else some q) acc = some p → p ∈ pairs by
    intro p hp
    exact H pairs none (by simp) (fun q hq => hq) p hp
  intro ps
  induction ps with
  | nil => intro acc hacc _ p hp; simp at hp; exact hacc p hp
  | cons x xs ih =>
    intro acc hacc hmem p hp
    simp only [List.foldl_cons] at hp
    have key : ∀ q, (match acc with
        | none => some x
        | some a => if x.2 - x.1 < a.2 - a.1 then some x else some a) = some q → q ∈ pairs := by
      intro q hq
      cases acc with
      | none => simp only at hq; injection hq with hq; subst hq; exact hmem x (List.mem_cons_self ..)
      | some a =>
        simp only at hq
        by_cases hc : x.2 - x.1 < a.2 - a.1
        · rw [if_pos hc] at hq; injection hq with hq; subst hq; exact hmem x (List.mem_cons_self ..)
        · rw [if_neg hc] at hq; injection hq with hq; subst hq; exact hacc a rfl
    exact ih _ key (fun q hq => hmem q (List.mem_cons_of_mem _ hq)) p hp

theorem findClosest_mem (numbers : List ℚ) :
    ∀ p, findClosest numbers = some p → p ∈ adjPairs (numbers.mergeSort (· ≤ ·)) := by
  intro p hp; exact closestAux_mem _ p hp

end PastaBench.humaneval.FindClosestElements
