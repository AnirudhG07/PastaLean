import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Add85

def add := fun (lst : List Int) ↦
  (do
    let mut s : Int := (0 : Int)
    for i in (PastaLean.pyRange (PastaLean.pyLen lst) (1 : Int) (2 : Int))do
      let _ := Libraries.passta.pyPassInvariant (s %ₚ (2 : Int) == (0 : Int))
      let _ := Libraries.passta.pyPassInvariant (i %ₚ (2 : Int) == (1 : Int))
      if h_1 : lst⦋i⦌ %ₚ (2 : Int) = (0 : Int) then
        s := s +ₚ lst⦋i⦌
      else
        let _ := ()
    return s : Id _)

/-- Correctness on the reference examples: `add` sums the even entries at odd indices. -/
theorem add_probe1 : (add [(4:Int), 88]).run = (88 : Int) := by native_decide
theorem add_probe2 : (add [(4:Int), 5, 6, 7, 2, 122]).run = (122 : Int) := by native_decide
theorem add_probe3 : (add [(4:Int), 0, 6, 7]).run = (0 : Int) := by native_decide

/-- The result is always even: it is a sum of even numbers, for ANY input list. -/
theorem add_even : ∀ (lst : List Int), ((add lst).run %ₚ (2:Int)) = (0 : Int) := by
  intro lst
  have hspec : ⦃⌜True⌝⦄ add lst ⦃⇓s => ⌜s %ₚ (2:Int) = (0:Int)⌝⦄ := by
    mvcgen [add, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
      · ⇓⟨_, s⟩ => ⌜s %ₚ (2:Int) = (0:Int)⌝
    all_goals
      simp_all (config := { zetaDelta := true })
        [taste_ingr, pyMod, PyModulo.hMod, PyHAdd.hAdd, Int.add_mul_emod_self_left]
    all_goals (first | omega | grind | (split_ifs <;> omega) | grind +locals)
  exact hspec True.intro

end PastaBench.humaneval.Add85
