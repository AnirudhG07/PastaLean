import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Iscube

/-- True iff `a` is a perfect cube (allowing negatives). -/
def iscube (a : Int) : Bool :=
  (List.range (a.natAbs + 2)).any (fun n => let n := (n : Int); n ^ 3 == a || (-n) ^ 3 == a)

theorem iscube_correct :
    iscube 1 = true ∧ iscube 2 = false ∧ iscube (-1) = true ∧ iscube 64 = true ∧
    iscube 180 = false ∧ iscube 1000 = true ∧ iscube 0 = true ∧ iscube 1729 = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- Soundness: whenever `iscube` answers true, an actual integer cube root exists. -/
theorem iscube_sound (a : Int) (h : iscube a = true) : ∃ m : Int, m ^ 3 = a := by
  unfold iscube at h
  rw [List.any_eq_true] at h
  obtain ⟨n, _, hn⟩ := h
  rcases Bool.or_eq_true .. |>.mp hn with h1 | h1
  · exact ⟨(n:Int), beq_iff_eq.mp h1⟩
  · exact ⟨-(n:Int), beq_iff_eq.mp h1⟩

end PastaBench.humaneval.Iscube
