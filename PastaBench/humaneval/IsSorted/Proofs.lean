import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsSorted

/-- Ascending (non-strict) and no value occurring more than twice. -/
def is_sorted (lst : List Int) : Bool :=
  (List.range (lst.length - 1)).all (fun i => lst[i]! ≤ lst[i+1]!) &&
  lst.all (fun v => lst.count v ≤ 2)

theorem is_sorted_correct :
    is_sorted [5] = true ∧ is_sorted [1,2,3,4,5] = true ∧
    is_sorted [1,3,2,4,5] = false ∧ is_sorted [1,2,3,4,5,6] = true ∧
    is_sorted [1,2,2,3,3,4] = true ∧ is_sorted [1,2,2,2,3,4] = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.IsSorted
