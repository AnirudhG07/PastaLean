import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CountUpper

def count_upper := fun (s : String) ↦
  (do
    let mut cnt : Int := (0 : Int)
    for i in (PastaLean.pyRange (PastaLean.pyLen s) (0 : Int) (2 : Int)) do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ PastaLean.pyLen s))
      let _ := Libraries.passta.pyPassInvariant (i %ₚ (2 : Int) == (0 : Int))
      let _ := Libraries.passta.pyPassInvariant (decide (cnt ≥ (0 : Int)))
      let _ := Libraries.passta.pyPassInvariant (decide (cnt ≤ PastaLean.pyFloorDiv i (2 : Int)))
      if h_1 : PastaLean.pyContains "AEIOU" s⦋i⦌ then
        cnt := cnt +ₚ (1 : Int)
      else
        let _ := ()
    return cnt : Id _)

-- The result counts vowels at even positions, hence is between 0 and the number of
-- even indices `len(range(0, len(s), 2))`.
theorem count_upper_spec :
    ⦃⌜True⌝⦄ count_upper s ⦃⇓cnt =>
      ⌜cnt ≥ (0 : Int) ∧ cnt ≤ ((PastaLean.pyRange (PastaLean.pyLen s) (0 : Int) (2 : Int)).length : Int)⌝⦄ := by
  mvcgen [count_upper] invariants
  · ⇓⟨cur, cnt⟩ => ⌜cnt ≥ (0 : Int) ∧ cnt ≤ (cur.prefix.length : Int)⌝
  all_goals
    (simp_all (config := { zetaDelta := true }) [taste_ingr] <;>
      (first | omega | grind | (split_ifs <;> omega) | grind +locals))

theorem count_upper_correct :
    ∀ (s : String),
      let cnt := (count_upper s).run
      cnt ≥ (0 : Int) ∧
        cnt ≤ ((PastaLean.pyRange (PastaLean.pyLen s) (0 : Int) (2 : Int)).length : Int) := by
  intro s
  exact count_upper_spec True.intro

end PastaBench.humaneval.CountUpper
