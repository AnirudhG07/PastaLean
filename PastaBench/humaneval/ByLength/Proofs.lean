import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ByLength

private def _by_length'to_word := fun (x : Int) ↦
  Id.run
    (do
      if h_1 : x = (1 : Int) then return "One"
      else if h_2 : x = (2 : Int) then return "Two"
      else if h_3 : x = (3 : Int) then return "Three"
      else if h_4 : x = (4 : Int) then return "Four"
      else if h_5 : x = (5 : Int) then return "Five"
      else if h_6 : x = (6 : Int) then return "Six"
      else if h_7 : x = (7 : Int) then return "Seven"
      else if h_8 : x = (8 : Int) then return "Eight"
      else return "Nine")

def by_length := fun (arr : List Int) ↦
  (do
    let __unpack_value_1 := (PastaLean.pySlice (PastaLean.pySort arr) none none (some (-(1 : Int))), ([] : List String))
    let __unpack_pair_1 := __unpack_value_1
    let mut sorted_list := Prod.fst __unpack_pair_1
    let mut ans := Prod.snd __unpack_pair_1
    for x in (PastaLean.pyIter sorted_list)do
      if h_1 : (1 : Int) ≤ x ∧ x ≤ (9 : Int) then
        ans := PastaLean.pyAppend ans (_by_length'to_word x)
      else
        let _ := ()
    return ans : Id _)

/-- `to_word` maps every digit 1..9 to its (non-empty) English name. -/
theorem to_word_valid :
    ∀ (x : Int), 1 ≤ x → x ≤ 9 →
      _by_length'to_word x ∈ ["One","Two","Three","Four","Five","Six","Seven","Eight","Nine"] := by
  intro x h1 h2
  interval_cases x <;> decide

/-- Correctness on the reference examples: sort 1..9 digits descending, spell them out. -/
theorem by_length_probe1 :
    (by_length [(2:Int), 1, 1, 4, 5, 8, 2, 3]).run =
      ["Eight", "Five", "Four", "Three", "Two", "Two", "One", "One"] := by native_decide
theorem by_length_probe2 : (by_length []).run = [] := by native_decide
theorem by_length_probe3 : (by_length [(1:Int), -1, 55]).run = ["One"] := by native_decide

end PastaBench.humaneval.ByLength
