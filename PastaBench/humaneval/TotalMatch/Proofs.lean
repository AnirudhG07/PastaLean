import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.TotalMatch

def total_match := fun (lst1 : List String) ↦ fun (lst2 : List String) ↦
  (do
    let __unpack_value_1 :=
      (PastaLean.pySum (PastaLean.pyMap (fun s ↦ PastaLean.pyLen s) lst1),
        PastaLean.pySum (PastaLean.pyMap (fun s ↦ PastaLean.pyLen s) lst2))
    let __unpack_pair_1 := __unpack_value_1
    let mut c1 := Prod.fst __unpack_pair_1
    let mut c2 := Prod.snd __unpack_pair_1
    let _ :=
      Libraries.passta.pyPassAssert (c1 == PastaLean.pySum ((PastaLean.pyIter lst1).map fun s => PastaLean.pyLen s))
    let _ :=
      Libraries.passta.pyPassAssert (c2 == PastaLean.pySum ((PastaLean.pyIter lst2).map fun s => PastaLean.pyLen s))
    let __py_ret_1 := if c1 ≤ c2 then lst1 else lst2
    return __py_ret_1 : Id _)

/-- Returns the list whose strings have the smaller total character count (ties → first). -/
theorem total_match_examples :
    (total_match (["hi", "admin"] : List String) (["hI", "Hi"] : List String)).run
        = (["hI", "Hi"] : List String) ∧
    (total_match (["4"] : List String) (["1", "2", "3", "4", "5"] : List String)).run
        = (["4"] : List String) := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.TotalMatch
