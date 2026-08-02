import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.TriplesSumToZero

def triples_sum_to_zero := fun (l : List Int) ↦
  (do
    for i in (PastaLean.pyRange (PastaLean.pyLen l)) do
      for j in (PastaLean.pyRange (PastaLean.pyLen l)) do
        for k in (PastaLean.pyRange (PastaLean.pyLen l)) do
          if h_1 : ((i ≠ j ∧ i ≠ k) ∧ j ≠ k) ∧ l⦋i⦌ +ₚ l⦋j⦌ +ₚ l⦋k⦌ = (0 : Int) then
            return Bool.true
          else
            let _ := ()
    return Bool.false : Id _)

-- Soundness: the search can only succeed when the list has at least three (distinct)
-- indices, which forces `len l ≥ 3`.
@[spec]
theorem triples_sum_to_zero_spec :
    ⦃⌜True⌝⦄ triples_sum_to_zero l ⦃⇓r => ⌜r = true → (3 : Int) ≤ PastaLean.pyLen l⌝⦄ := by
  have key : ∀ {n : ℕ} {pref suff : List ℕ} {c : ℕ},
      List.range n = pref ++ c :: suff → c < n := by
    intro n pref suff c h
    have hc : c ∈ List.range n := by rw [h]; simp
    simpa using hc
  have hpl : PastaLean.pyLen l = (l.length : Int) := rfl
  mvcgen [triples_sum_to_zero, PastaLean.pyRange_forIn] invariants
  · Invariant.withEarlyReturn
      (onReturn := fun r _ => ⌜r = true → (3 : Int) ≤ PastaLean.pyLen l⌝)
      (onContinue := fun _ _ => ⌜True⌝)
  · Invariant.withEarlyReturn
      (onReturn := fun r _ => ⌜r = true → (3 : Int) ≤ PastaLean.pyLen l⌝)
      (onContinue := fun _ _ => ⌜True⌝)
  · Invariant.withEarlyReturn
      (onReturn := fun r _ => ⌜r = true → (3 : Int) ≤ PastaLean.pyLen l⌝)
      (onContinue := fun _ _ => ⌜True⌝)
  all_goals grind

theorem triples_sum_to_zero_correct :
    ∀ (l : List Int),
      (triples_sum_to_zero l).run = true → (3 : Int) ≤ PastaLean.pyLen l := by
  intro l
  exact triples_sum_to_zero_spec True.intro

end PastaBench.humaneval.TriplesSumToZero
