import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ChooseNum

def choose_num := fun (x : Int) ↦ fun (y : Int) ↦
  (do
    if h_1 : x > y then
      let __py_ret_1 := -(1 : Int)
      return __py_ret_1
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (x ≤ y))
    if h_2 : x = y then
      let __py_ret_1 := if y %ₚ (2 : Int) = (0 : Int) then y else -(1 : Int)
      return __py_ret_1
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (x < y))
    if h_3 : y %ₚ (2 : Int) = (0 : Int) then
      return y
    else
      let _ := Libraries.passta.pyPassAssert (y %ₚ (2 : Int) != (0 : Int))
      let _ := Libraries.passta.pyPassAssert (decide (x ≤ y -ₚ (1 : Int)))
      let __py_ret_1 := y -ₚ (1 : Int)
      return __py_ret_1 : Id _)

theorem choose_num_correct :
    ∀ (x y : Int),
      let result := (choose_num x y).run
      result = -(1 : Int) ∨
        (result %ₚ (2 : Int) = (0 : Int) ∧ x ≤ result ∧ result ≤ y ∧ result +ₚ (2 : Int) > y) := by
  have hmod : ∀ n : Int, pyMod n 2 = n % 2 := by
    intro n; simp only [pyMod]; split_ifs with h <;> simp_all <;> omega
  intro x y
  simp only [choose_num, Id.run, bind, pure, Id.instMonad, PyModulo.hMod, PyHAdd.hAdd, PyHSub.hSub,
    hmod]
  split_ifs <;> omega

end PastaBench.humaneval.ChooseNum
