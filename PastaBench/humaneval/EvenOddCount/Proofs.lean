import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.humaneval.EvenOddCount

def even_odd_count := fun (num : Int) ↦
  (do
    let mut s : String := PastaLean.pyStr num
    let __unpack_value_1 := ((0 : Int), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut even : Int := Prod.fst __unpack_pair_1
    let mut odd : Int := Prod.snd __unpack_pair_1
    for _pair_1 in (PastaLean.pyIter (PastaLean.pyEnumerate s))do
      let i := Prod.fst _pair_1
      let ch := Prod.snd _pair_1
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i) && decide (i ≤ PastaLean.pyLen s))
      if h_1 : PastaLean.pyContains "02468" ch then
        even := even +ₚ (1 : Int)
      else
        let _ := ()
      if h_2 : PastaLean.pyContains "13579" ch then
        odd := odd +ₚ (1 : Int)
      else
        let _ := ()
    let __py_ret_1 := (even, odd)
    return __py_ret_1 : Id _)

@[spec]
theorem even_odd_count_spec :
    ⦃⌜True⌝⦄ even_odd_count num ⦃⇓result =>
      ⌜result⦋(0 : Int)⦌ ≥ (0 : Int) ∧ result⦋(1 : Int)⦌ ≥ (0 : Int)⌝⦄ := by
  mvcgen [even_odd_count] invariants
    · ⇓⟨_cur, even, odd⟩ => ⌜even ≥ (0 : Int) ∧ odd ≥ (0 : Int)⌝
  all_goals
    simp_all (config := { zetaDelta := true })
      [pyGetItem, pyListGetItem, PyGetItem.getItem, PyHAdd.hAdd, taste_ingr, pyTruthy,
        PyTruthy.truthy] <;>
    (first | omega | grind | (split_ifs <;> omega) | grind +locals)

theorem even_odd_count_correct :
    ∀ (num : Int),
      let result := (even_odd_count num).run
      result⦋(0 : Int)⦌ ≥ (0 : Int) ∧ result⦋(1 : Int)⦌ ≥ (0 : Int) := by
  intro num
  exact even_odd_count_spec True.intro

end PastaBench.humaneval.EvenOddCount
