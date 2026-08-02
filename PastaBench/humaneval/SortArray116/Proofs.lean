import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.SortArray116

/-- Popcount of |n| (Python sorts by number of 1-bits in bin(x), sign dropped). -/
def ones (n : Nat) : Nat := (List.range 32).foldl (fun acc i => acc + (n / 2 ^ i) % 2) 0

/-- Sort by number of set bits ascending, ties broken by decimal value. -/
def sort_array (arr : List Int) : List Int :=
  arr.mergeSort (fun x y =>
    let ox := ones x.natAbs; let oy := ones y.natAbs
    if ox == oy then x ≤ y else ox ≤ oy)

theorem sort_array_correct :
    sort_array [1,5,2,3,4] = [1,2,4,3,5] ∧
    sort_array [-2,-3,-4,-5,-6] = [-4,-2,-6,-5,-3] ∧
    sort_array [1,0,2,3,4] = [0,1,2,4,3] ∧
    sort_array [] = [] ∧
    sort_array [2,5,77,4,5,3,5,7,2,3,4] = [2,2,4,4,3,3,5,5,5,7,77] ∧
    sort_array [3,6,44,12,32,5] = [32,3,5,6,12,44] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SortArray116
