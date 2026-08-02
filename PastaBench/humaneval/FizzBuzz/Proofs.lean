import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FizzBuzz

def fizz_buzz := fun (n : Int) ↦
  (do
    let mut cnt : Int := (0 : Int)
    for i in (PastaLean.pyRange n)do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ n))
      let _ := Libraries.passta.pyPassInvariant (decide (cnt ≥ (0 : Int)))
      let _ := Libraries.passta.pyPassDecreases (n -ₚ i)
      if h_1 : i %ₚ (11 : Int) = (0 : Int) ∨ i %ₚ (13 : Int) = (0 : Int) then
        cnt := cnt +ₚ PastaLean.pyLen (PastaLean.pyList (PastaLean.pyFilter (fun c ↦ c == "7") (PastaLean.pyStr i)))
      else
        let _ := ()
    return cnt : Id _)

/-- The count of digit-7 occurrences is always non-negative. -/
@[spec]
theorem fizz_buzz_spec : ⦃⌜n ≥ (0 : Int)⌝⦄ fizz_buzz n ⦃⇓cnt => ⌜cnt ≥ (0 : Int)⌝⦄ := by
  mvcgen [fizz_buzz, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, cnt⟩ => ⌜cnt ≥ (0 : Int)⌝
  all_goals
    simp_all (config := { zetaDelta := true }) [taste_ingr, PyHAdd.hAdd]
  all_goals
    first
      | omega
      | (have := PastaLean.pyLen_list_nonneg
          (PastaLean.pyList (α := String) (PastaLean.pyFilter (fun c ↦ c == "7") (PastaLean.pyStr _))); omega)
      | grind

theorem fizz_buzz_correct :
    ∀ (n : Int), n ≥ (0 : Int) →
      let cnt := (fizz_buzz n).run; cnt ≥ (0 : Int) := by
  intro n hpre
  exact fizz_buzz_spec hpre

end PastaBench.humaneval.FizzBuzz
