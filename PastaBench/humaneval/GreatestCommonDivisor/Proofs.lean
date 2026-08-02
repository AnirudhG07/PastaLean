import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.GreatestCommonDivisor

/-- Python floored modulo strictly shrinks the `natAbs` of a nonzero modulus,
which is exactly the termination measure of Euclid's algorithm. -/
theorem pyMod_natAbs_lt (a b : Int) (hb : b ≠ 0) : (pyMod a b).natAbs < b.natAbs := by
  have h1 : 0 ≤ a % b := Int.emod_nonneg a hb
  have h2 : a % b < (b.natAbs : Int) := Int.emod_lt a hb
  rw [pyMod]
  simp only [beq_iff_eq, hb, if_false, Bool.or_eq_true, Bool.and_eq_true,
    decide_eq_true_eq, gt_iff_lt]
  split <;> omega

/-- For a positive modulus the Python `%` agrees with Lean's `Int.emod`. -/
theorem pyMod_pos (a b : Int) (hb : 0 < b) : pyMod a b = a % b := by
  have h1 : 0 ≤ a % b := Int.emod_nonneg a (by omega)
  rw [pyMod]
  simp only [beq_iff_eq, Bool.or_eq_true, Bool.and_eq_true, decide_eq_true_eq, gt_iff_lt]
  split
  · omega
  · split
    · omega
    · rfl

/-- Euclid's algorithm exactly as emitted for `query_gcd`. -/
def greatest_common_divisor (a b : Int) : Int :=
  if b = 0 then a else greatest_common_divisor b (a %ₚ b)
termination_by b.natAbs
decreasing_by
  rename_i hb
  have : (pyMod a b).natAbs < b.natAbs := pyMod_natAbs_lt a b hb
  simpa [HMod.hMod, PyModulo.hMod] using this

/-- Non-trivial correctness: for non-negative inputs the result is a common divisor
of both arguments (`Result ∣ a ∧ Result ∣ b`), matching the `a % Result == 0`
and `b % Result == 0` postconditions. -/
theorem greatest_common_divisor_dvd :
    ∀ (a b : Int), 0 ≤ a → 0 ≤ b →
      greatest_common_divisor a b ∣ a ∧ greatest_common_divisor a b ∣ b := by
  intro a b
  induction a, b using greatest_common_divisor.induct with
  | case1 a =>
    intro ha hb
    rw [greatest_common_divisor]; simp
  | case2 a b hne ih =>
    intro ha hb
    have hbpos : 0 < b := lt_of_le_of_ne hb (Ne.symm hne)
    have hmod : a %ₚ b = a % b := pyMod_pos a b hbpos
    have hmnn : 0 ≤ a %ₚ b := by rw [hmod]; exact Int.emod_nonneg a (by omega)
    obtain ⟨hdb, hdm⟩ := ih hb hmnn
    rw [greatest_common_divisor, if_neg hne]
    refine ⟨?_, hdb⟩
    have hrec : a %ₚ b + b * (a / b) = a := by rw [hmod]; exact Int.emod_add_mul_ediv a b
    have hd : greatest_common_divisor b (a %ₚ b) ∣ (a %ₚ b + b * (a / b)) :=
      Dvd.dvd.add hdm (Dvd.dvd.mul_right hdb _)
    rwa [hrec] at hd

end PastaBench.humaneval.GreatestCommonDivisor
