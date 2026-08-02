import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SpecialFactorial

def special_factorial := fun (n : Int) ↦
  (do
    let __unpack_value_1 := ((1 : Int), (1 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut fac : Int := Prod.fst __unpack_pair_1
    let mut ans : Int := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (2 : Int))do
      let _ := Libraries.passta.pyPassInvariant (decide ((2 : Int) ≤ i) && decide (i ≤ n +ₚ (1 : Int)))
      let _ := Libraries.passta.pyPassInvariant (decide (fac ≥ (1 : Int)))
      let _ := Libraries.passta.pyPassInvariant (decide (ans ≥ (1 : Int)))
      let _ := Libraries.passta.pyPassInvariant (ans %ₚ fac == (0 : Int))
      let _ := Libraries.passta.pyPassDecreases (n +ₚ (1 : Int) -ₚ i)
      fac := fac *ₚ i
      ans := ans *ₚ fac
    return ans : Id _)

@[spec]
theorem special_factorial_spec :
    ⦃⌜n ≥ (0 : Int)⌝⦄ special_factorial n ⦃⇓ans => ⌜ans ≥ (1 : Int)⌝⦄ :=
  by
  mvcgen [special_factorial, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨_cur, fac, ans⟩ => ⌜(1 : Int) ≤ fac ∧ (1 : Int) ≤ ans⌝
  all_goals
    simp_all (config := { zetaDelta := true }) [taste_ingr, PyHMul.hMul, PyHAdd.hAdd,
      PyHSub.hSub]
  all_goals
    first
      | omega
      | ( obtain ⟨ha, hb⟩ := ‹(1 : Int) ≤ _ ∧ (1 : Int) ≤ _›
          exact ⟨one_le_mul_of_one_le_of_one_le ha
                   (one_le_mul_of_one_le_of_one_le hb (by omega)),
                 one_le_mul_of_one_le_of_one_le hb (by omega)⟩ )

theorem special_factorial_correct :
    ∀ (n : Int), n ≥ (0 : Int) → (special_factorial n).run ≥ (1 : Int) :=
  by
  intro n hpre
  exact special_factorial_spec hpre

end PastaBench.humaneval.SpecialFactorial
