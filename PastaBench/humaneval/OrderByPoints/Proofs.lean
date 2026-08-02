import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.OrderByPoints

private def weight := fun (x : Int) ↦
  Id.run
    (do
      let chars : List String := PastaLean.pyList (PastaLean.pyStr x)
      if h_1 : chars⦋(0 : Int)⦌ = "-" then
        let digits : List Int := PastaLean.pyMap PastaLean.pyInt (PastaLean.pySlice chars (some (1 : Int)) none none)
        let digits : List Int := PastaLean.pySetItem digits (0 : Int) (-digits⦋(0 : Int)⦌)
        return PastaLean.pySum digits
      else
        let digits : List Int := PastaLean.pyMap PastaLean.pyInt chars
        return PastaLean.pySum digits)

def order_by_points := fun (nums : List Int) ↦ PastaLean.pySortBy weight false nums

/-- Correctness: stable sort by digit-sum weight (a negative number's sign applies to
    its leading digit), checked on the reference test cases. -/
theorem order_by_points_correct :
    order_by_points [1, 11, -1, -11, -12] = [-1, -11, 1, -12, 11] ∧
    order_by_points [] = [] ∧
    order_by_points [1, -11, -32, 43, 54, -98, 2, -3] = [-3, -32, -98, -11, 1, 2, 43, 54] := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.OrderByPoints
