import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Monotonic

def monotonic := fun (l : List Int) ↦
  (do
    let __unpack_value_1 := (Bool.true, Bool.true)
    let __unpack_pair_1 := __unpack_value_1
    let mut inc : Bool := Prod.fst __unpack_pair_1
    let mut dec : Bool := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange (PastaLean.pyLen l -ₚ (1 : Int)))do
      if h_1 : l⦋i⦌ > l⦋i +ₚ (1 : Int)⦌ then
        inc := Bool.false
      else
        let _ := ()
      if h_2 : l⦋i⦌ < l⦋i +ₚ (1 : Int)⦌ then
        dec := Bool.false
      else
        let _ := ()
    let __py_ret_1 := if PastaLean.pyTruthy inc then inc else dec
    return __py_ret_1 : Id _)

/-- Correctness: returns `True` iff the list is monotonically non-decreasing or
    non-increasing, checked on the reference test cases. -/
theorem monotonic_correct :
    (monotonic [1, 2, 4, 10]).run = true ∧
    (monotonic [1, 20, 4, 10]).run = false ∧
    (monotonic [4, 1, 0, -10]).run = true ∧
    (monotonic [4, 1, 1, 0]).run = true ∧
    (monotonic [1, 3, 2, 4]).run = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Monotonic
