import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CheckIfLastCharIsALetter

def check_if_last_char_is_a_letter := fun (txt : String) ↦
  (do
    if h_1 : PastaLean.pyLen txt = (0 : Int) then
      let _ := Libraries.passta.pyPassAssert (PastaLean.pyLen txt == (0 : Int))
      return Bool.false
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (PastaLean.pyLen txt > (0 : Int)))
    if h_2 : PastaLean.pyLen txt = (1 : Int) then
      let _ := Libraries.passta.pyPassAssert (PastaLean.pyLen txt == (1 : Int))
      let __py_ret_1 := PastaLean.pyIsAlpha txt
      return __py_ret_1
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (PastaLean.pyLen txt ≥ (2 : Int)))
    let __py_ret_1 :=
      if PastaLean.pyTruthy (PastaLean.pyIsAlpha txt⦋(-1 : Int)⦌) then txt⦋(-2 : Int)⦌ == " "
      else PastaLean.pyIsAlpha txt⦋(-1 : Int)⦌
    return __py_ret_1 : Id _)

/-- Full functional characterization: the result matches the three-way branch on `len txt`. -/
theorem check_if_last_char_is_a_letter_correct :
    ∀ (txt : String),
      (check_if_last_char_is_a_letter txt).run =
        (if PastaLean.pyLen txt = (0 : Int) then false
         else if PastaLean.pyLen txt = (1 : Int) then PastaLean.pyIsAlpha txt
         else (if PastaLean.pyTruthy (PastaLean.pyIsAlpha txt⦋(-1 : Int)⦌) then txt⦋(-2 : Int)⦌ == " "
               else PastaLean.pyIsAlpha txt⦋(-1 : Int)⦌)) := by
  intro txt
  simp only [check_if_last_char_is_a_letter, Id.run, bind, pure, Id.instMonad]
  split_ifs <;> rfl

end PastaBench.humaneval.CheckIfLastCharIsALetter
