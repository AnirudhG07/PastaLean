import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SumProduct

def sum_product := fun (numbers : List Int) ↦
  (do
    let __unpack_value_1 := ((0 : Int), (1 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut s : Int := Prod.fst __unpack_pair_1
    let mut p : Int := Prod.snd __unpack_pair_1
    for _pair_1 in (PastaLean.pyIter (PastaLean.pyEnumerate numbers))do
      let i := Prod.fst _pair_1
      let number := Prod.snd _pair_1
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i) && decide (i ≤ PastaLean.pyLen numbers))
      let _ := Libraries.passta.pyPassInvariant (s == PastaLean.pySum (PastaLean.pySlice numbers none (some i) none))
      let _ :=
        Libraries.passta.pyPassInvariant
          (p == Libraries.math.pyMathProd (PastaLean.pySlice numbers none (some i) none))
      s := s +ₚ number
      p := p *ₚ number
    let _ := Libraries.passta.pyPassAssert (s == PastaLean.pySum numbers)
    let _ := Libraries.passta.pyPassAssert (p == Libraries.math.pyMathProd numbers)
    let __py_ret_1 := (s, p)
    return __py_ret_1 : Id _)

/-- On the documented examples the function returns the (sum, product) pair. -/
theorem sum_product_examples :
    (sum_product []).run = (0, 1) ∧ (sum_product [1, 2, 3, 4]).run = (10, 24) := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SumProduct
