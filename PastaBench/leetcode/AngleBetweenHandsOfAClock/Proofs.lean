import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.leetcode.AngleBetweenHandsOfAClock

def angleClock := fun (hour : Int) ↦ fun (minutes : Int) ↦
  (let h := (30 : Int) *ₚ hour +ₚ (0.5 : Rat) *ₚ minutes
    let m := ((6 : Int) *ₚ minutes : Int)
    let diff := PastaLean.pyAbs (h -ₚ m)
    PastaLean.pyMin [diff, (360 : Int) -ₚ diff] :
    Rat)

attribute [simp] angleClock

theorem angleClock_correct :
    ∀ (hour : Int),
      ∀ (minutes : Int),
        let h := (30 : Int) *ₚ hour +ₚ (0.5 : Rat) *ₚ minutes
        let m := (6 : Int) *ₚ minutes
        let diff := PastaLean.pyAbs (h -ₚ m)
        (((0 : Int) ≤ hour ∧ hour ≤ (12 : Int)) ∧ (0 : Int) ≤ minutes) ∧ minutes < (60 : Int) →
          (0 : Int) ≤ angleClock hour minutes ∧ angleClock hour minutes ≤ (180 : Int) := by
  intro hour minutes h m diff hyp
  obtain ⟨⟨⟨hh0, hh12⟩, hm0⟩, hm60⟩ := hyp
  simp only [angleClock]
  have hh0' : (0:ℚ) ≤ (hour:ℚ) := by exact_mod_cast hh0
  have hh12' : (hour:ℚ) ≤ 12 := by exact_mod_cast hh12
  have hm0' : (0:ℚ) ≤ (minutes:ℚ) := by exact_mod_cast hm0
  have hm59 : minutes ≤ 59 := by omega
  have hm59' : (minutes:ℚ) ≤ 59 := by exact_mod_cast hm59
  set x : ℚ := (30:Int) *ₚ hour +ₚ (0.5:Rat) *ₚ minutes -ₚ (6:Int) *ₚ minutes with hx
  have hxval : x = 30 * (hour:ℚ) + 0.5 * (minutes:ℚ) - 6 * (minutes:ℚ) := by
    rw [hx]; simp only [PyHMul.hMul, PyHAdd.hAdd, PyHSub.hSub]; push_cast; ring
  have hx_le : x ≤ 360 := by rw [hxval]; nlinarith
  have hx_ge : (-360:ℚ) ≤ x := by rw [hxval]; nlinarith
  set dd : ℚ := pyAbs x with hdd
  have habs : dd = if x < 0 then -x else x := rfl
  have hdd0 : (0:ℚ) ≤ dd := by rw [habs]; split <;> linarith
  have hdd360 : dd ≤ 360 := by rw [habs]; split <;> linarith
  have hpm : pyMin [dd, (360:Int) -ₚ dd]
      = (if (compare ((360:Int) -ₚ dd : ℚ) dd == Ordering.lt) then ((360:Int) -ₚ dd : ℚ) else dd) := rfl
  have he : ((360:Int) -ₚ dd : ℚ) = 360 - dd := by simp only [PyHSub.hSub]; push_cast; ring
  rw [hpm, he]
  have h0 : ((0:Int):ℚ) = 0 := by norm_num
  have h180 : ((180:Int):ℚ) = 180 := by norm_num
  rw [h0, h180]
  split_ifs with hc
  · have hlt : (360 - dd) < dd := compare_lt_iff_lt.mp (beq_iff_eq.mp hc)
    exact ⟨by linarith, by linarith⟩
  · have hge : dd ≤ 360 - dd := by
      have hne : ¬ ((360 - dd) < dd) := by
        intro hlt
        exact hc (beq_iff_eq.mpr (compare_lt_iff_lt.mpr hlt))
      linarith [not_lt.mp hne]
    exact ⟨by linarith, by linarith⟩

end PastaBench.leetcode.AngleBetweenHandsOfAClock
