import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Tri

def tri := fun n ↦
  (do
    if h_1 : n = (0 : Int) then 
      let __py_ret_1 := [(1 : Rat)]
      return __py_ret_1
    else
      let _ := ()
    if h_2 : n = (1 : Int) then 
      let __py_ret_1 := [(1 : Rat), (3 : Rat)]
      return __py_ret_1
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (n ≥ (2 : Int)))
    let mut ans := ([(1 : Rat), (3 : Rat)] : List Rat)
    for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (2 : Int))do
      let _ := Libraries.passta.pyPassInvariant (decide ((2 : Int) ≤ i) && decide (i ≤ n +ₚ (1 : Int)))
      let _ := Libraries.passta.pyPassInvariant (PastaLean.pyLen ans == i)
      -- The computed prefix of the sequence must satisfy the definition.
      let _ := Libraries.passta.pyPassInvariant (ans⦋(0 : Int)⦌ == (1 : Int))
      let _ := Libraries.passta.pyPassInvariant (ans⦋(1 : Int)⦌ == (3 : Int))
      let _ :=
        Libraries.passta.pyPassInvariant
          (PastaLean.pyAll
            ((PastaLean.pyRange i (2 : Int)).map fun k =>
              k %ₚ (2 : Int) == (0 : Int) && ans⦋k⦌ == (1 : Int) +ₚ k /ₚ (2 : Int) ||
                k %ₚ (2 : Int) != (0 : Int) &&
                  ans⦋k⦌ == ans⦋k -ₚ (1 : Int)⦌ +ₚ ans⦋k -ₚ (2 : Int)⦌ +ₚ (1 : Int) +ₚ (k +ₚ (1 : Int)) /ₚ (2 : Int)))
      let _ := Libraries.passta.pyPassDecreases (n +ₚ (1 : Int) -ₚ i)
      if h_3 : i %ₚ (2 : Int) = (0 : Int) then 
        ans := PastaLean.pyAppend ans ((1 : Int) +ₚ i /ₚ (2 : Int))
      else
        ans := PastaLean.pyAppend ans (ans⦋(-1 : Int)⦌ +ₚ ans⦋(-2 : Int)⦌ +ₚ (1 : Int) +ₚ (i +ₚ (1 : Int)) /ₚ (2 : Int))
    let _ := Libraries.passta.pyPassAssert (PastaLean.pyLen ans == n +ₚ (1 : Int))
    let _ := Libraries.passta.pyPassAssert (ans⦋(0 : Int)⦌ == (1 : Int) && ans⦋(1 : Int)⦌ == (3 : Int))
    let _ :=
      Libraries.passta.pyPassAssert
        (PastaLean.pyAll
          ((PastaLean.pyRange (n +ₚ (1 : Int)) (2 : Int)).map fun k =>
            k %ₚ (2 : Int) == (0 : Int) && ans⦋k⦌ == (1 : Int) +ₚ k /ₚ (2 : Int) ||
              k %ₚ (2 : Int) != (0 : Int) &&
                ans⦋k⦌ == ans⦋k -ₚ (1 : Int)⦌ +ₚ ans⦋k -ₚ (2 : Int)⦌ +ₚ (1 : Int) +ₚ (k +ₚ (1 : Int)) /ₚ (2 : Int)))
    return ans : Id _)

/-- The first entries of the Tribonacci-like sequence. -/
theorem tri_examples :
    (tri 0).run = [1] ∧ (tri 1).run = [1, 3] ∧ (tri 3).run = [1, 3, 2, 8] := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Tri
