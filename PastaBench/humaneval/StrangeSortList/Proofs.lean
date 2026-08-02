import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.StrangeSortList

def strange_sort_list := fun (lst : List Int) ↦
  (do
    let mut sorted_list : List Int := PastaLean.pySort lst
    let _ := Libraries.passta.pyPassAssert (PastaLean.pySort lst == sorted_list)
    let _ := Libraries.passta.pyPassAssert (PastaLean.pyLen sorted_list == PastaLean.pyLen lst)
    let __unpack_value_1 := ([], ((0 : Int), PastaLean.pyLen sorted_list -ₚ (1 : Int)))
    let __unpack_pair_1 := __unpack_value_1
    let mut ans : List Int := Prod.fst __unpack_pair_1
    let mut i : Int := Prod.fst (Prod.snd __unpack_pair_1)
    let mut j : Int := Prod.snd (Prod.snd __unpack_pair_1)
    while (i < j) do
      -- Loop invariants capture the state of the partitioning:
      -- 1. Pointers `i` and `j` move inwards from the ends of `sorted_list`.
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (j < PastaLean.pyLen sorted_list))
      -- 2. `i` and `j` don't cross until the loop terminates.
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ j +ₚ (1 : Int)))
      -- 3. The pointers maintain a symmetric relationship.
      let _ := Libraries.passta.pyPassInvariant (i +ₚ j == PastaLean.pyLen sorted_list -ₚ (1 : Int))
      -- 4. The length of the result list `ans` is twice the number of pairs taken.
      let _ := Libraries.passta.pyPassInvariant (PastaLean.pyLen ans == (2 : Int) *ₚ i)
      -- 5. The core permutation property: elements already in `ans` plus the
      -- unprocessed elements between `i` and `j` constitute the original sorted list.
      let _ :=
        Libraries.passta.pyPassInvariant
          (PastaLean.pySort (ans +ₚ PastaLean.pySlice sorted_list (some i) (some (j +ₚ (1 : Int))) none) ==
            sorted_list)
      -- Termination: the gap between `i` and `j` shrinks.
      let _ := Libraries.passta.pyPassDecreases (j -ₚ i)
      ans := PastaLean.pyAppend ans sorted_list⦋i⦌
      ans := PastaLean.pyAppend ans sorted_list⦋j⦌
      i := i +ₚ (1 : Int)
      j := j -ₚ (1 : Int)
    let _ := Libraries.passta.pyPassAssert (i == j || i == j +ₚ (1 : Int))
    if h_1 : i = j then 
      ans := PastaLean.pyAppend ans sorted_list⦋i⦌
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (PastaLean.pySort ans == sorted_list)
    return ans : Id _)

/-- Strange order: min, max, next-min, next-max, ... of the sorted list. -/
theorem strange_sort_list_examples :
    (strange_sort_list [1, 2, 3, 4]).run = [1, 4, 2, 3] ∧
    (strange_sort_list [5, 5, 5, 5]).run = [5, 5, 5, 5] ∧
    (strange_sort_list []).run = [] := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.StrangeSortList
