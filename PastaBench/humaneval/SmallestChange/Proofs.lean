import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SmallestChange

def smallest_change := fun (arr : List Int) ↦
  (do
    let __unpack_value_1 := (PastaLean.pySlice arr none none (some (-(1 : Int))), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut arr_reversed : List Int := Prod.fst __unpack_pair_1
    let mut cnt : Int := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange (PastaLean.pyFloorDiv (PastaLean.pyLen arr) (2 : Int)))do
      if arr⦋i⦌ ≠ arr_reversed⦋i⦌ then
        cnt := cnt +ₚ (1 : Int)
      else
        let _ := ()
    return cnt : Id _)

@[spec]
theorem smallest_change_spec :
    ⦃⌜True⌝⦄ smallest_change arr ⦃⇓cnt =>
      ⌜(0 : Int) ≤ cnt ∧ cnt ≤ PastaLean.pyFloorDiv (PastaLean.pyLen arr) (2 : Int)⌝⦄ := by
  mvcgen [smallest_change, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, cnt⟩ =>
      ⌜let i := (cur.prefix.length : Int);
        ((0 : Int) ≤ i ∧ i ≤ PastaLean.pyFloorDiv (PastaLean.pyLen arr) (2 : Int)) ∧
          (0 : Int) ≤ cnt ∧ cnt ≤ i⌝
  all_goals
    have hB : (0 : Int) ≤ PastaLean.pyFloorDiv (PastaLean.pyLen arr) (2 : Int) := by
      have h0 : (0 : Int) ≤ PastaLean.pyLen arr := by
        show (0 : Int) ≤ ((arr.length : Nat) : Int); exact Int.natCast_nonneg _
      simp only [PastaLean.pyFloorDiv, PyFloorDiv.floorDiv]
      exact Int.fdiv_nonneg h0 (by norm_num)
  all_goals
    try (simp only [List.length_nil, List.length_cons, List.length_append,
      Nat.cast_zero, Nat.cast_add, Nat.cast_one, Nat.cast_ofNat] at *)
  all_goals
    first
      | omega
      | (simp_all (config := { zetaDelta := true })
          [taste_ingr, PyHAdd.hAdd, PyHSub.hSub] <;> omega)
      | (simp_all (config := { zetaDelta := true }) [taste_ingr] <;> grind +locals)
      | grind +locals

theorem smallest_change_correct :
    ∀ (arr : List Int),
      let cnt := (smallest_change arr).run;
      (0 : Int) ≤ cnt ∧ cnt ≤ PastaLean.pyFloorDiv (PastaLean.pyLen arr) (2 : Int) := by
  intro arr
  exact smallest_change_spec True.intro

end PastaBench.humaneval.SmallestChange
