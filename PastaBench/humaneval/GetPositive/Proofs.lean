import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.GetPositive

def get_positive := fun (l : List Int) ↦ PastaLean.pyList (PastaLean.pyFilter (fun x ↦ decide (x > (0 : Int))) l)

/-- Non-trivial correctness: every element of the result is positive, and every element
of the result occurs in the input list. -/
theorem get_positive_correct :
    ∀ (l : List Int),
      PastaLean.pyTruthy (PastaLean.pyAll ((PastaLean.pyIter (get_positive l)).map fun x => decide (x > (0 : Int)))) =
          true ∧
        PastaLean.pyTruthy
            (PastaLean.pyAll ((PastaLean.pyIter (get_positive l)).map fun x => PastaLean.pyContains l x)) =
          true := by
  intro l
  have hall : ∀ (L : List Bool), pyAll L = L.all pyBool := fun _ => rfl
  have htru : ∀ (b : Bool), pyTruthy b = b := fun _ => rfl
  have hpb : ∀ (b : Bool), pyBool b = b := fun _ => rfl
  have hiter : ∀ (L : List Int), pyIter L = L := fun _ => rfl
  simp only [get_positive, pyList, pyFilter, hiter, htru, hall, hpb]
  simp only [pyContains, PyContains.contains]
  constructor
  · rw [List.all_eq_true]
    intro b hb
    simp only [List.mem_map, List.mem_filter] at hb
    obtain ⟨x, ⟨hxl, hxp⟩, rfl⟩ := hb
    exact hxp
  · rw [List.all_eq_true]
    intro b hb
    simp only [List.mem_map, List.mem_filter] at hb
    obtain ⟨x, ⟨hxl, hxp⟩, rfl⟩ := hb
    exact List.elem_eq_true_of_mem hxl

end PastaBench.humaneval.GetPositive
