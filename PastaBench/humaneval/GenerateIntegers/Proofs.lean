import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.GenerateIntegers

/-- After the `a > b` swap, return the even numbers in `range(lo, min(hi+1, 10))`. -/
def generate_integers := fun (a : Int) ↦ fun (b : Int) ↦
  let lo := if a > b then b else a
  let hi := if a > b then a else b
  (List.filter (fun i => decide (i %ₚ (2 : Int) = (0 : Int)))
      (PastaLean.pyRange (PastaLean.pyMin [hi +ₚ (1 : Int), (10 : Int)]) lo)).map (fun i => i)

/-- Every element of a `pyRange stop start` is strictly below `stop`. -/
theorem mem_pyRange_lt (stop start x : Int) (h : x ∈ PastaLean.pyRange stop start) : x < stop := by
  rw [PastaLean.pyRange_eq_start] at h
  simp only [List.mem_map, List.mem_range] at h
  obtain ⟨k, hk, rfl⟩ := h
  show start + (k : Int) < stop
  omega

/-- Correctness: every returned integer is even and a single digit (`< 10`). -/
theorem generate_integers_correct (a b : Int) :
    ∀ x ∈ generate_integers a b, x %ₚ (2 : Int) = (0 : Int) ∧ x < 10 := by
  intro x hx
  simp only [generate_integers, List.mem_map, List.mem_filter] at hx
  obtain ⟨y, ⟨hy_range, hy_even⟩, rfl⟩ := hx
  rw [decide_eq_true_eq] at hy_even
  refine ⟨hy_even, ?_⟩
  have hlt := mem_pyRange_lt _ _ _ hy_range
  rw [PastaLean.pyMin_pair] at hlt
  omega

end PastaBench.humaneval.GenerateIntegers
