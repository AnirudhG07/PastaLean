import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MoveOneBall

def move_one_ball := fun (arr : List Int) ↦
  (do
    let mut sorted_arr : List Int := PastaLean.pySort arr
    if h_1 : arr = sorted_arr then
      return Bool.true
    else
      let _ := ()
    for i in (PastaLean.pyRange (PastaLean.pyLen arr) (1 : Int))do
      if h_2 :
          PastaLean.pySlice arr (some i) none none +ₚ PastaLean.pySlice arr none (some i) none = sorted_arr then
        return Bool.true
      else
        let _ := ()
    return Bool.false : Id _)

/-- Correctness: returns `True` iff some cyclic right-shift of `arr` is sorted
    (empty list is `True`), checked on the reference test cases. -/
theorem move_one_ball_correct :
    (move_one_ball [3, 4, 5, 1, 2]).run = true ∧
    (move_one_ball [3, 5, 10, 1, 2]).run = true ∧
    (move_one_ball [4, 3, 1, 2]).run = false ∧
    (move_one_ball [3, 5, 4, 1, 2]).run = false ∧
    (move_one_ball ([] : List Int)).run = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.MoveOneBall
