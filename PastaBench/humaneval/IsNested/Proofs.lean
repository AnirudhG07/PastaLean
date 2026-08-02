import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsNested

def is_nested := fun (string : String) ↦
  (do
    for i in (PastaLean.pyRange (PastaLean.pyLen string))do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i) && decide (i ≤ PastaLean.pyLen string))
      if h_1 : string⦋i⦌ = "]" then 
        continue
      else
        let _ := ()
      let _ := Libraries.passta.pyPassAssert (decide ((0 : Int) ≤ i) && decide (i < PastaLean.pyLen string))
      let _ := Libraries.passta.pyPassAssert (string⦋i⦌ == "[")
      let __unpack_value_1 := ((0 : Int), (0 : Int))
      let __unpack_pair_1 := __unpack_value_1
      let mut cnt : Int := Prod.fst __unpack_pair_1
      let mut max_nest : Int := Prod.snd __unpack_pair_1
      for j in (PastaLean.pyRange (PastaLean.pyLen string) i)do
        let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i) && decide (i < PastaLean.pyLen string))
        let _ := Libraries.passta.pyPassInvariant (decide (i ≤ j) && decide (j ≤ PastaLean.pyLen string))
        let _ := Libraries.passta.pyPassInvariant (string⦋i⦌ == "[")
        -- Invariant: `max_nest` tracks the maximum nesting depth, which cannot be negative.
        let _ := Libraries.passta.pyPassInvariant (decide (max_nest ≥ (0 : Int)))
        -- Invariant: `cnt` tracks the balance of brackets in the prefix `string[i:j]`.
        -- Its value is bounded by the number of characters processed.
        let _ := Libraries.passta.pyPassInvariant (decide (i -ₚ j ≤ cnt))
        let _ := Libraries.passta.pyPassInvariant (decide (cnt ≤ j -ₚ i))
        -- Invariant: `max_nest` is the maximum of `cnt` values seen so far in this scan.
        let _ := Libraries.passta.pyPassInvariant (decide (cnt ≤ max_nest))
        let _ := Libraries.passta.pyPassDecreases (PastaLean.pyLen string -ₚ j)
        if h_2 : string⦋j⦌ = "[" then 
          cnt := cnt +ₚ (1 : Int)
        else
          cnt := cnt -ₚ (1 : Int)
        max_nest := PastaLean.pyMax [max_nest, cnt]
        if h_3 : cnt = (0 : Int) then 
          -- A balanced subsequence `string[i:j+1]` has been found.
          -- If its maximum nesting depth was 2 or more, it's a success.
          if h_4 : max_nest ≥ (2 : Int) then 
            return Bool.true
          else
            let _ := ()
          break
        else
          let _ := ()
    return Bool.false : Id _)

theorem is_nested_correct :
    (is_nested "[[]]").run = true ∧
    (is_nested "[]]]]]]][[[[[]").run = false ∧
    (is_nested "[][]").run = false ∧
    (is_nested "[]").run = false ∧
    (is_nested "[[[[]]]]").run = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.IsNested
