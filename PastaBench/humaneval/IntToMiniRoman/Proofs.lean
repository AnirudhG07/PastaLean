import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IntToMiniRoman

def int_to_mini_roman := fun (number : Int) ↦
  let m := (["", "m"] : List String)
  let c := (["", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm"] : List String)
  let x := (["", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc"] : List String)
  let i := (["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"] : List String)
  let thousands := (m⦋PastaLean.pyFloorDiv number (1000 : Int)⦌ : String)
  let hundreds := (c⦋PastaLean.pyFloorDiv (number %ₚ (1000 : Int)) (100 : Int)⦌ : String)
  let tens := (x⦋PastaLean.pyFloorDiv (number %ₚ (100 : Int)) (10 : Int)⦌ : String)
  let ones := (i⦋number %ₚ (10 : Int)⦌ : String)
  thousands +ₚ hundreds +ₚ tens +ₚ ones

/-- For a positive modulus the Python `%` agrees with Lean's `Int.emod`. -/
private theorem pyMod_pos (a b : Int) (hb : 0 < b) : PastaLean.pyMod a b = a % b := by
  have h1 : 0 ≤ a % b := Int.emod_nonneg a (by omega)
  rw [PastaLean.pyMod]
  simp only [beq_iff_eq, Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_eq, gt_iff_lt]
  split
  · omega
  · split
    · omega
    · rfl

/-- Python floor-division `a // b` with a nonnegative dividend and positive divisor
    is Lean's `Int.ediv`. -/
private theorem pyFloorDiv_pos (a b : Int) (hb : 0 < b) :
    PastaLean.pyFloorDiv a b = a / b := by
  have : ¬ (b = 0) := by omega
  simp only [pyFloorDiv, PyFloorDiv.floorDiv, beq_iff_eq, this, if_false]
  exact Int.fdiv_eq_ediv_of_nonneg a (by omega)

/-- Every table index used to build the numeral is within its table's bounds
    (given `1 ≤ number ≤ 1000`), so the function is well-defined. -/
theorem int_to_mini_roman_indices (number : Int) (h1 : 1 ≤ number) (h2 : number ≤ 1000) :
    (0 ≤ PastaLean.pyFloorDiv number (1000 : Int) ∧ PastaLean.pyFloorDiv number (1000 : Int) < 2) ∧
    (0 ≤ PastaLean.pyFloorDiv (number %ₚ (1000 : Int)) (100 : Int) ∧
        PastaLean.pyFloorDiv (number %ₚ (1000 : Int)) (100 : Int) < 10) ∧
    (0 ≤ PastaLean.pyFloorDiv (number %ₚ (100 : Int)) (10 : Int) ∧
        PastaLean.pyFloorDiv (number %ₚ (100 : Int)) (10 : Int) < 10) ∧
    (0 ≤ number %ₚ (10 : Int) ∧ number %ₚ (10 : Int) < 10) := by
  have m1000 : number %ₚ (1000 : Int) = number % 1000 := pyMod_pos number 1000 (by omega)
  have m100 : number %ₚ (100 : Int) = number % 100 := pyMod_pos number 100 (by omega)
  have m10 : number %ₚ (10 : Int) = number % 10 := pyMod_pos number 10 (by omega)
  have n1000 : (0 : Int) ≤ number % 1000 := Int.emod_nonneg number (by omega)
  have n100 : (0 : Int) ≤ number % 100 := Int.emod_nonneg number (by omega)
  have d0 : PastaLean.pyFloorDiv number (1000 : Int) = number / 1000 :=
    pyFloorDiv_pos number 1000 (by omega)
  rw [m1000, m100, m10]
  rw [d0, pyFloorDiv_pos (number % 1000) 100 (by omega),
      pyFloorDiv_pos (number % 100) 10 (by omega)]
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩, ⟨?_, ?_⟩, ?_, ?_⟩ <;> omega

end PastaBench.humaneval.IntToMiniRoman
