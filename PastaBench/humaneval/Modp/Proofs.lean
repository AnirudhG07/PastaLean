import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Modp

def modp := fun (n : Int) ↦ fun (p : Int) ↦
  (do
    let mut n := n
    let __unpack_value_1 := ((1 : Int), (2 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut res : Int := Prod.fst __unpack_pair_1
    let mut x : Int := Prod.snd __unpack_pair_1
    while (n ≠ (0 : Int)) do
      if h_1 : n %ₚ (2 : Int) = (1 : Int) then
        res := res *ₚ x %ₚ p
      else
        let _ := ()
      x := x *ₚ x %ₚ p
      n := PastaLean.pyFloorDiv n (2 : Int)
    let __py_ret_1 := res %ₚ p
    return __py_ret_1 : Id _)

/-- Correctness: computes `2^n mod p`, checked on the reference test cases. -/
theorem modp_correct :
    (modp 3 5).run = 3 ∧
    (modp 1101 101).run = 2 ∧
    (modp 0 101).run = 1 ∧
    (modp 3 11).run = 8 ∧
    (modp 100 101).run = 1 ∧
    (modp 100 89).run = 2 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Modp
