import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.StartsOneEnds

def starts_one_ends := fun (n : Int) ↦
  (do
    if h_1 : n = (1 : Int) then
      return (1 : Int)
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (n > (1 : Int)))
    let __py_ret_1 := (18 : Int) *ₚ (10 : Int) ^ₚ (n -ₚ (2 : Int))
    return __py_ret_1 : Id _)

theorem starts_one_ends_correct :
    ∀ (n : Int),
      (starts_one_ends n).run = if n = 1 then 1 else 18 * (10 : Int) ^ (n - 2).toNat := by
  intro n
  simp only [starts_one_ends, Id.run, bind, pure, Id.instMonad,
    PyHMul.hMul, PyHPow.hPow, PyHSub.hSub]
  split_ifs with h <;> simp_all [PyHMul.hMul, PyHPow.hPow, PyHSub.hSub]

end PastaBench.humaneval.StartsOneEnds
