import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsHappy

/-- Length ≥ 3 and every 3 consecutive characters are pairwise distinct. -/
def is_happy (s : String) : Bool :=
  let d := s.data
  d.length ≥ 3 && (List.range (d.length - 2)).all (fun i =>
    d[i]! ≠ d[i+1]! && d[i]! ≠ d[i+2]! && d[i+1]! ≠ d[i+2]!)

theorem is_happy_correct :
    is_happy "a" = false ∧ is_happy "aa" = false ∧ is_happy "abcd" = true ∧
    is_happy "aabb" = false ∧ is_happy "adb" = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- General property: only strings of length ≥ 3 can be happy. -/
theorem is_happy_len (s : String) (h : is_happy s = true) : s.data.length ≥ 3 := by
  unfold is_happy at h
  exact of_decide_eq_true (Bool.and_eq_true .. |>.mp h).1

end PastaBench.humaneval.IsHappy
