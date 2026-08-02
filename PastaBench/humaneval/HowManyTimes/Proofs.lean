import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.HowManyTimes

def how_many_times := fun (string : String) ↦ fun (substring : String) ↦
  (do
    let mut occurences : Int := (0 : Int)
    for i in (PastaLean.pyRange (PastaLean.pyLen string))do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ PastaLean.pyLen string))
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ occurences))
      let _ := Libraries.passta.pyPassInvariant (decide (occurences ≤ i))
      if h_1 :
          PastaLean.pyTruthy
            (PastaLean.pyStringStartswith (PastaLean.pySlice string (some i) none none) substring) then
        occurences := occurences +ₚ (1 : Int)
      else
        let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide ((0 : Int) ≤ occurences))
    let _ := Libraries.passta.pyPassAssert (decide (occurences ≤ PastaLean.pyLen string))
    return occurences : Id _)

@[spec]
theorem how_many_times_spec :
    ⦃⌜PastaLean.pyLen substring > (0 : Int)⌝⦄ how_many_times string substring ⦃⇓occurences =>
      ⌜(0 : Int) ≤ occurences ∧ occurences ≤ PastaLean.pyLen string⌝⦄ :=
  by
  mvcgen [how_many_times, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
  · ⇓⟨cur, occurences⟩ =>
    ⌜let i := (cur.prefix.length : Int);
      (((0 : Int) ≤ i ∧ i ≤ PastaLean.pyLen string) ∧ (0 : Int) ≤ occurences) ∧ occurences ≤ i⌝
  all_goals
    simp_all (config := { zetaDelta := true }) [taste_ingr, pyTruthy, PyTruthy.truthy] <;>
      (first | omega | grind | (split_ifs <;> omega) | grind +locals)

theorem how_many_times_correct :
    ∀ (string : String),
      ∀ (substring : String),
        PastaLean.pyLen substring > (0 : Int) →
          let occurences := (how_many_times string substring).run;
          (0 : Int) ≤ occurences ∧ occurences ≤ PastaLean.pyLen string :=
  by
  intro string substring hpre
  exact how_many_times_spec hpre

end PastaBench.humaneval.HowManyTimes
