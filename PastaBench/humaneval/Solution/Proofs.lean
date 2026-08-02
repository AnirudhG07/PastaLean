import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Solution

def solution := fun (lst : List Int) ↦
  (do
    let mut total : Int := (0 : Int)
    for i in (PastaLean.pyRange (PastaLean.pyLen lst))do
      -- The loop counter `i` is bounded by the length of the list.
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ PastaLean.pyLen lst))
      -- The core invariant: the running total must remain 0, because the
      -- condition to add to it (`lst[i] % 2 == 1`) can never be true,
      -- given the function's precondition.
      let _ := Libraries.passta.pyPassInvariant (total == (0 : Int))
      if h_1 : i %ₚ (2 : Int) = (0 : Int) ∧ lst⦋i⦌ %ₚ (2 : Int) = (1 : Int) then 
        total := total +ₚ lst⦋i⦌
      else
        let _ := ()
    return total : Id _)

theorem solution_correct :
    (solution [5, 8, 7, 1]).run = 12 ∧
    (solution [3, 3, 3, 3, 3]).run = 9 ∧
    (solution [30, 13, 24, 321]).run = 0 ∧
    (solution [5, 9]).run = 5 ∧
    (solution [2, 4, 8]).run = 0 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Solution
