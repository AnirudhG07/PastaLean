import PastaBench.leetcode.SmallestEvenMultiple.Generated
import PastaBench.Support

/-!
# smallest-even-multiple — hand-written proofs  (Easy, bucket `term`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

The reference example for the benchmark. LeetCode asks for *the smallest positive integer that is
a multiple of both `2` and `n`*, and `smallestEvenMultiple` answers it with a one-line ternary.
That full specification — even, a multiple of `n`, and **minimal** among such — is proved here.
-/

namespace PastaBench.leetcode.SmallestEvenMultiple

open PastaLean PastaBench

/-- Python's floored `%` detects evenness just like the mathematical one. -/
theorem pyMod_two_eq_zero_iff (n : Int) : pyMod n 2 = 0 ↔ 2 ∣ n := by
  unfold pyMod; simp; omega

/-- The returned value is even. -/
theorem even_result (n : Int) : 2 ∣ smallestEvenMultiple n := by
  simp only [smallestEvenMultiple]
  split <;> rename_i h
  · exact (pyMod_two_eq_zero_iff n).mp (by simpa using h)
  · exact ⟨n, by simp; ring⟩

/-- The returned value is a multiple of `n`. -/
theorem dvd_result (n : Int) : n ∣ smallestEvenMultiple n := by
  simp only [smallestEvenMultiple]
  split
  · exact dvd_refl n
  · exact ⟨2, by simp⟩

/-- Minimality — the actual point of the problem: every positive common multiple of `2` and `n`
is at least the returned value. With `even_result`/`dvd_result` this is the full specification. -/
theorem le_of_common_multiple (n m : Int) (_hn : 0 < n) (hm : 0 < m)
    (h2 : 2 ∣ m) (hnm : n ∣ m) : smallestEvenMultiple n ≤ m := by
  simp only [smallestEvenMultiple]
  split <;> rename_i h
  · exact Int.le_of_dvd hm hnm
  · -- `n` is odd. Then the cofactor `k` in `m = n * k` must be even, so `2 * n ∣ m`.
    have hodd : ¬ (2 ∣ n) := fun hd => h (by simp [(pyMod_two_eq_zero_iff n).mpr hd])
    obtain ⟨a, ha⟩ : Odd n := (Int.not_even_iff_odd).mp fun he => hodd he.two_dvd
    obtain ⟨k, hk⟩ := hnm
    obtain ⟨j, hj⟩ : Even k := by
      rcases Int.even_or_odd k with hke | hko
      · exact hke
      · exfalso
        obtain ⟨b, hb⟩ := hko
        rw [hk, ha, hb, show (2*a+1)*(2*b+1) = 2*(2*a*b+a+b)+1 by ring] at h2
        omega
    exact Int.le_of_dvd hm ⟨j, by simp; rw [hk, hj]; ring⟩

end PastaBench.leetcode.SmallestEvenMultiple
