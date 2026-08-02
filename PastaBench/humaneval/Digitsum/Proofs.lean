import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Digitsum

/-- Sum of the ASCII codes of the uppercase characters. -/
def digitSum (s : String) : Int :=
  (s.data.filter Char.isUpper).foldl (fun acc c => acc + (c.toNat : Int)) 0

theorem digitSum_correct :
    digitSum "" = 0 ∧ digitSum "abAB" = 131 ∧ digitSum "abcCd" = 67 ∧
    digitSum "helloE" = 69 ∧ digitSum "woArBld" = 131 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Digitsum
