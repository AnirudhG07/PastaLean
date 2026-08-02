import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Minsubarraysum

def minSubArraySum := fun (nums : List Int) ↦
  (do
    if h_1 : PastaLean.pyTruthy (PastaLean.pyAll ((PastaLean.pyIter nums).map fun x => decide (x ≥ (0 : Int)))) then
      let __py_ret_1 := PastaLean.pyMin nums
      return __py_ret_1
    else
      let _ := ()
    let __unpack_value_1 := ((0 : Int), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut s : Int := Prod.fst __unpack_pair_1
    let mut ans : Int := Prod.snd __unpack_pair_1
    for x in (PastaLean.pyIter nums)do
      s := s +ₚ x
      let mut ans'rb0 := PastaLean.pyMin [ans, s]
      if h_2 : s ≥ (0 : Int) then
        let mut s'rb1 := (0 : Int)
      else
        let _ := ()
    return ans : Id _)

-- When every element is non-negative, the minimum sub-array sum is the minimum element.
theorem minSubArraySum_correct :
    (minSubArraySum [2, 3, 4, 1, 2, 4]).run = 1
      ∧ (minSubArraySum [10, 11, 13, 8, 3, 4]).run = 3
      ∧ (minSubArraySum [7]).run = 7
      ∧ (minSubArraySum [0, 10, 20, 1000000]).run = 0 := by
  native_decide

end PastaBench.humaneval.Minsubarraysum
