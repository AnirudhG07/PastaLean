import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.SortArray88

/-- Sort ascending when first+last is odd, descending when even. -/
def sort_array (a : List Int) : List Int :=
  if a.isEmpty then []
  else
    let s := a.mergeSort (· ≤ ·)
    if (a.headD 0 + a.getLast!) % 2 == 1 then s else s.reverse

theorem sort_array_correct :
    sort_array [] = [] ∧
    sort_array [5] = [5] ∧
    sort_array [2,4,3,0,1,5] = [0,1,2,3,4,5] ∧
    sort_array [2,4,3,0,1,5,6] = [6,5,4,3,2,1,0] ∧
    sort_array [2,1] = [1,2] ∧
    sort_array [15,42,87,32,11,0] = [0,11,15,32,42,87] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SortArray88
