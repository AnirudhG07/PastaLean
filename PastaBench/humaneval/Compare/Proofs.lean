import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Compare

def compare := fun (game : List Int) ↦ fun (guess : List Int) ↦
  (PastaLean.pyRange (PastaLean.pyLen game)).map fun i => PastaLean.pyAbs (game⦋i⦌ -ₚ guess⦋i⦌)

/-- `compare` returns a list of the same length as `game`, all of whose entries are
non-negative (each is the absolute difference of a score/guess pair). -/
theorem compare_correct : ∀ (game guess : List Int),
    (PastaLean.pyLen (compare game guess) = PastaLean.pyLen game) ∧
      (∀ x ∈ compare game guess, (0 : Int) ≤ x) := by
  intro game guess
  refine ⟨?_, ?_⟩
  · simp only [compare, PastaLean.pyLen, PyLen.pyLen, List.length_map]
    rw [PastaLean.pyRange_eq_ofNat]
    simp
  · intro x hx
    simp only [compare, List.mem_map] at hx
    obtain ⟨i, _, rfl⟩ := hx
    show (0 : Int) ≤ (if (game⦋i⦌ -ₚ guess⦋i⦌) < 0 then -(game⦋i⦌ -ₚ guess⦋i⦌) else (game⦋i⦌ -ₚ guess⦋i⦌))
    split_ifs <;> omega

end PastaBench.humaneval.Compare
