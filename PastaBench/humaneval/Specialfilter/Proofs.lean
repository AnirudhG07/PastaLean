import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Specialfilter

def specialFilter := fun (nums : List Int) ↦
  (do
    let __unpack_value_1 := ((0 : Int), ["1", "3", "5", "7", "9"])
    let __unpack_pair_1 := __unpack_value_1
    let mut ans : Int := Prod.fst __unpack_pair_1
    let mut odd : List String := Prod.snd __unpack_pair_1
    for num in (PastaLean.pyIter nums)do
      if h_1 :
          (num > (10 : Int) ∧ PastaLean.pyContains odd (PastaLean.pyStr num)⦋(0 : Int)⦌) ∧
            PastaLean.pyContains odd (PastaLean.pyStr num)⦋(-1 : Int)⦌ then
        ans := ans +ₚ (1 : Int)
      else
        let _ := ()
    return ans : Id _)

/-- The count of "special" numbers is between 0 and the total number of inputs: the loop
visits each element once and increments the counter by at most one. -/
@[spec]
theorem specialFilter_spec :
    ⦃⌜True⌝⦄ specialFilter nums ⦃⇓ans => ⌜ans ≥ (0 : Int) ∧ ans ≤ PastaLean.pyLen nums⌝⦄ := by
  mvcgen [specialFilter, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, ans⟩ => ⌜(0 : Int) ≤ ans ∧ ans ≤ (cur.prefix.length : Int)⌝
  all_goals
    have hL : PastaLean.pyLen nums = (nums.length : Int) := rfl
  all_goals
    have hiter : PastaLean.pyIter nums = nums := rfl
  all_goals
    try (simp only [hiter, hL, List.length_nil, List.length_cons, List.length_append,
      Nat.cast_zero, Nat.cast_add, Nat.cast_one, Nat.cast_ofNat] at *)
  all_goals
    first
      | omega
      | (simp_all (config := { zetaDelta := true })
          [taste_ingr, PyHAdd.hAdd, PyHSub.hSub] <;> omega)
      | (simp_all (config := { zetaDelta := true }) [taste_ingr] <;> grind +locals)
      | grind +locals

theorem specialFilter_correct :
    ∀ (nums : List Int),
      let ans := (specialFilter nums).run;
      ans ≥ (0 : Int) ∧ ans ≤ PastaLean.pyLen nums := by
  intro nums
  exact specialFilter_spec True.intro

end PastaBench.humaneval.Specialfilter
