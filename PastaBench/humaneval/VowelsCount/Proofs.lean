import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.VowelsCount

def vowels_count := fun (s : String) ↦
  (do
    if h_1 : s = "" then
      return (0 : Int)
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (PastaLean.pyLen s ≥ (1 : Int)))
    let mut cnt : Int :=
      PastaLean.pyLen (PastaLean.pyList (PastaLean.pyFilter (fun ch ↦ PastaLean.pyContains "aeiouAEIOU" ch) s))
    let _ := Libraries.passta.pyPassAssert (decide ((0 : Int) ≤ cnt) && decide (cnt ≤ PastaLean.pyLen s))
    if h_2 : PastaLean.pyContains "yY" s⦋(-1 : Int)⦌ then
      let _ := Libraries.passta.pyPassAssert (decide (cnt ≤ PastaLean.pyLen s -ₚ (1 : Int)))
      cnt := cnt +ₚ (1 : Int)
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide ((0 : Int) ≤ cnt) && decide (cnt ≤ PastaLean.pyLen s))
    return cnt : Id _)

-- `pyLen` of any list is a `Nat` cast, hence non-negative.
private theorem pyLen_list_nonneg (z : List String) : (0 : Int) ≤ PastaLean.pyLen z := by
  simpa [PastaLean.pyLen, PyLen.pyLen] using Int.natCast_nonneg z.length

-- The vowel count is always non-negative: it starts as a list length and is only ever
-- incremented.
@[spec]
theorem vowels_count_nonneg :
    ⦃⌜True⌝⦄ vowels_count s ⦃⇓cnt => ⌜(0 : Int) ≤ cnt⌝⦄ := by
  generalize hc :
    PastaLean.pyLen (PastaLean.pyList (PastaLean.pyFilter (fun ch ↦ PastaLean.pyContains "aeiouAEIOU" ch) s)) = c
  have hc0 : (0 : Int) ≤ c := by
    rw [← hc]; exact pyLen_list_nonneg _
  mvcgen [vowels_count]
  all_goals
    (simp_all (config := { zetaDelta := true })
        [taste_ingr, pyTruthy, PyTruthy.truthy, PyHAdd.hAdd] <;>
      omega)

theorem vowels_count_correct :
    ∀ (s : String), (0 : Int) ≤ (vowels_count s).run := by
  intro s
  exact vowels_count_nonneg True.intro

end PastaBench.humaneval.VowelsCount
