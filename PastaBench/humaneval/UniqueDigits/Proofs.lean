import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.UniqueDigits

/-- Every decimal digit of |n| is odd. -/
def allOdd (n : Int) : Bool :=
  (toString n.natAbs).data.all (fun c => (c.toNat - '0'.toNat) % 2 == 1)

def unique_digits (x : List Int) : List Int := (x.filter allOdd).mergeSort (· ≤ ·)

theorem unique_digits_correct :
    unique_digits [15,33,1422,1] = [1,15,33] ∧
    unique_digits [152,323,1422,10] = [] ∧
    unique_digits [12345,2033,111,151] = [111,151] ∧
    unique_digits [135,103,31] = [31,135] ∧
    unique_digits [257,369,781,409] = [] ∧
    unique_digits [1357,79,8642,246] = [79,1357] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.UniqueDigits
