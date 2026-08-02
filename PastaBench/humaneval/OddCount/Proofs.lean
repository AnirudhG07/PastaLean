import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.OddCount

def odd_count := fun (lst : List String) ↦
  Id.run
    (do
      let template : String := "the number of odd elements in the string i of the input."
      let mut ans : List String := []
      for s in (PastaLean.pyIter lst)do
        let odd_cnt : Int :=
          PastaLean.pyLen
            (PastaLean.pyList (PastaLean.pyFilter (fun ch ↦ PastaLean.pyInt ch %ₚ (2 : Int) == (1 : Int)) s))
        ans := PastaLean.pyAppend ans (PastaLean.pyStringReplace template "i" (PastaLean.pyStr odd_cnt))
      return ans)

/-- Correctness: for each digit string, fills the template with its count of odd
    digits, checked on the reference test cases. -/
theorem odd_count_correct :
    odd_count ["1234567"] = ["the number of odd elements 4n the str4ng 4 of the 4nput."] ∧
    odd_count ["3", "11111111"] =
      ["the number of odd elements 1n the str1ng 1 of the 1nput.",
       "the number of odd elements 8n the str8ng 8 of the 8nput."] ∧
    odd_count [] = [] ∧
    odd_count ["2468"] = ["the number of odd elements 0n the str0ng 0 of the 0nput."] := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.OddCount
