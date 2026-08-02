import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.CircularShift

/-- Right-rotate the decimal digits of `x` by `shift`; if shift exceeds the digit count, reverse. -/
def circular_shift (x : Nat) (shift : Nat) : String :=
  let s := toString x
  let n := s.length
  if shift > n then String.mk s.data.reverse
  else
    let sh := shift % n
    if sh == 0 then s
    else String.mk ((s.data.drop (n - sh)) ++ (s.data.take (n - sh)))

theorem circular_shift_correct :
    circular_shift 100 2 = "001" ∧ circular_shift 12 2 = "12" ∧
    circular_shift 97 8 = "79" ∧ circular_shift 12 1 = "21" ∧
    circular_shift 11 101 = "11" ∧ circular_shift 16 3 = "61" := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.CircularShift
