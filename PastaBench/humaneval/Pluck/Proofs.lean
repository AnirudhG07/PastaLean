import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Pluck

def pluck := fun (arr : List Int) ↦
  Id.run
    (do
      if h_1 :
          PastaLean.pyTruthy
            (PastaLean.pyAll ((PastaLean.pyIter arr).map fun val => val %ₚ (2 : Int) == (1 : Int))) then
        return ([] : List Int)
      else
        let _ := ()
      let min_even : Int := PastaLean.pyMin (PastaLean.pyFilter (fun x ↦ x %ₚ (2 : Int) == (0 : Int)) arr)
      for i in (PastaLean.pyRange (PastaLean.pyLen arr))do
        if h_2 : arr⦋i⦌ = min_even then
          return [min_even, i]
        else
          let _ := ()
      return default)

/-- Correctness: returns `[smallest even value, its index]` (empty if none), checked
    on the reference test cases. -/
theorem pluck_correct :
    pluck [4, 2, 3] = [2, 1] ∧
    pluck [1, 2, 3] = [2, 1] ∧
    pluck [] = [] ∧
    pluck [5, 0, 3, 0, 4, 2] = [0, 1] ∧
    pluck [1, 2, 3, 0, 5, 3] = [0, 3] := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Pluck
