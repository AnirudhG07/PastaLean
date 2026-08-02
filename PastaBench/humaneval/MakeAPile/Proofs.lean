import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MakeAPile

def make_a_pile := fun (n : Int) ↦
  (do
    let __unpack_value_1 := ([], n)
    let __unpack_pair_1 := __unpack_value_1
    let mut ans : List Int := Prod.fst __unpack_pair_1
    let mut num : Int := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange n)do
      ans := PastaLean.pyAppend ans num
      num := num +ₚ (2 : Int)
    return ans : Id _)

-- The pile has n levels forming an arithmetic progression from n with step 2.
theorem make_a_pile_correct :
    (make_a_pile 1).run = [1]
      ∧ (make_a_pile 3).run = [3, 5, 7]
      ∧ (make_a_pile 4).run = [4, 6, 8, 10]
      ∧ (make_a_pile 5).run = [5, 7, 9, 11, 13]
      ∧ (make_a_pile 6).run = [6, 8, 10, 12, 14, 16] := by
  native_decide

end PastaBench.humaneval.MakeAPile
