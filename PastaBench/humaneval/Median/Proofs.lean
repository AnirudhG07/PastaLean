import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Median

def median := fun (l : List Rat) ↦
  (do
    let mut sorted_l := PastaLean.pySort l
    if h_1 : PastaLean.pyLen l %ₚ (2 : Int) = (1 : Int) then
      let __py_ret_1 := sorted_l⦋PastaLean.pyFloorDiv (PastaLean.pyLen l) (2 : Int)⦌
      return __py_ret_1
    else
      let __py_ret_1 :=
        (sorted_l⦋PastaLean.pyFloorDiv (PastaLean.pyLen l) (2 : Int) -ₚ (1 : Int)⦌ +ₚ
            sorted_l⦋PastaLean.pyFloorDiv (PastaLean.pyLen l) (2 : Int)⦌) /ₚ
          (2 : Int)
      return __py_ret_1 :
    Id _)

-- Median of the sorted list: middle element (odd) or mean of the two middle ones (even).
theorem median_correct :
    (median [3, 1, 2, 4, 5]).run = 3
      ∧ (median [-10, 4, 6, 1000, 10, 20]).run = 8
      ∧ (median [5]).run = 5
      ∧ (median [6, 5]).run = 11/2
      ∧ (median [8, 1, 3, 9, 9, 2, 7]).run = 7
      ∧ (median [1, 3, 7, 8, 10, 10]).run = 15/2 := by
  native_decide

end PastaBench.humaneval.Median
