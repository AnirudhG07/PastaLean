import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.humaneval.Eat

def eat := fun (number : Int) ↦ fun (need : Int) ↦ fun (remaining : Int) ↦
  (do
    if h_1 : need ≤ remaining then
      let __py_ret_1 := [number +ₚ need, remaining -ₚ need]
      return __py_ret_1
    else
      let __py_ret_1 := [number +ₚ remaining, (0 : Int)]
      return __py_ret_1 : Id _)

@[spec]
theorem eat_spec :
    ⦃⌜True⌝⦄
      eat number need remaining ⦃⇓result =>
      ⌜((result⦋(0 : Int)⦌ = number +ₚ (if need ≤ remaining then need else remaining)) ∧
            result⦋(1 : Int)⦌ = remaining -ₚ (if need ≤ remaining then need else remaining)) ∧
          result⦋(0 : Int)⦌ +ₚ result⦋(1 : Int)⦌ = number +ₚ remaining⌝⦄ := by
  mvcgen [eat]
  all_goals
    simp_all (config := { zetaDelta := true })
      [pyGetItem, pyListGetItem, PyGetItem.getItem, PyHAdd.hAdd, PyHSub.hSub] <;> omega

theorem eat_correct :
    ∀ (number need remaining : Int),
      let result := (eat number need remaining).run
      ((result⦋(0 : Int)⦌ = number +ₚ (if need ≤ remaining then need else remaining)) ∧
          result⦋(1 : Int)⦌ = remaining -ₚ (if need ≤ remaining then need else remaining)) ∧
        result⦋(0 : Int)⦌ +ₚ result⦋(1 : Int)⦌ = number +ₚ remaining := by
  intro number need remaining
  exact eat_spec True.intro

end PastaBench.humaneval.Eat
