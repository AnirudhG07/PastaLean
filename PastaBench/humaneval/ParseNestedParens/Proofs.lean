import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ParseNestedParens

private def count_depth := fun (s : String) ↦
  Id.run
    (do
      let mut max_depth : Int := 0
      let mut cnt : Int := 0
      for ch in (PastaLean.pyIter s)do
        if h_1 : ch = "(" then cnt := cnt +ₚ (1 : Int)
        else let _ := ()
        if h_2 : ch = ")" then cnt := cnt -ₚ (1 : Int)
        else let _ := ()
        max_depth := PastaLean.pyMax [max_depth, cnt]
      return max_depth)

def parse_nested_parens := fun (paren_string : String) ↦
  (List.filter (fun s => s ≠ "") (PastaLean.pyIter (PastaLean.pyStringSplit paren_string " "))).map fun s =>
    count_depth s

/-- Correctness: reports the maximum nesting depth of each space-separated paren
    group, checked on the reference test cases. -/
theorem parse_nested_parens_correct :
    parse_nested_parens "(()()) ((())) () ((())()())" = [2, 3, 1, 3] ∧
    parse_nested_parens "() (()) ((())) (((())))" = [1, 2, 3, 4] ∧
    parse_nested_parens "(()(())((())))" = [4] ∧
    parse_nested_parens "" = [] ∧
    parse_nested_parens "((()))" = [3] := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.ParseNestedParens
