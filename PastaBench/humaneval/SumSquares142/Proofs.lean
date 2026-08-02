import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SumSquares142

def sum_squares := fun (lst : List Int) ↦
  (do
    let mut ans : Int := (0 : Int)
    for _pair_1 in (PastaLean.pyIter (PastaLean.pyEnumerate lst))do
      let i := Prod.fst _pair_1
      let num := Prod.snd _pair_1
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i) && decide (i ≤ PastaLean.pyLen lst))
      let _ :=
        Libraries.passta.pyPassInvariant
          (ans ==
            PastaLean.pySum
              ((PastaLean.pyRange i).map fun k =>
                if k %ₚ (3 : Int) = (0 : Int) then lst⦋k⦌ ^ₚ (2 : Int)
                else if k %ₚ (4 : Int) = (0 : Int) then lst⦋k⦌ ^ₚ (3 : Int) else lst⦋k⦌))
      if h_1 : i %ₚ (3 : Int) = (0 : Int) then 
        ans := ans +ₚ num ^ₚ (2 : Int)
      else
        if h_2 : i %ₚ (4 : Int) = (0 : Int) then 
          ans := ans +ₚ num ^ₚ (3 : Int)
        else
          ans := ans +ₚ num
    let _ :=
      Libraries.passta.pyPassAssert
        (ans ==
          PastaLean.pySum
            ((PastaLean.pyRange (PastaLean.pyLen lst)).map fun k =>
              if k %ₚ (3 : Int) = (0 : Int) then lst⦋k⦌ ^ₚ (2 : Int)
              else if k %ₚ (4 : Int) = (0 : Int) then lst⦋k⦌ ^ₚ (3 : Int) else lst⦋k⦌))
    return ans : Id _)

/-- Sum with index-dependent powers (square at idx%3==0, cube at idx%4==0). -/
theorem sum_squares_examples :
    (sum_squares [1, 2, 3]).run = 6 ∧
    (sum_squares []).run = 0 ∧
    (sum_squares [-1, -5, 2, -1, -5]).run = -126 := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SumSquares142
