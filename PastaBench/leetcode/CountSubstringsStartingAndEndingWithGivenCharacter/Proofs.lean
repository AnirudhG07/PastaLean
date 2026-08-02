import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.leetcode.CountSubstringsStartingAndEndingWithGivenCharacter

def countSubstrings := fun (s : String) ↦ fun (c : String) ↦
  let cnt := (PastaLean.pyCount s c : Int)
  cnt +ₚ PastaLean.pyFloorDiv (cnt *ₚ (cnt -ₚ (1 : Int))) (2 : Int)

attribute [simp] countSubstrings

theorem countSubstrings_correct :
    ∀ (s : String),
      ∀ (c : String),
        let cnt := PastaLean.pyCount s c
        PastaLean.pyLen c > (0 : Int) →
          (2 : Int) *ₚ countSubstrings s c = PastaLean.pyCount s c *ₚ (PastaLean.pyCount s c +ₚ (1 : Int)) := by
  intro s c cnt hc
  clear cnt
  simp only [countSubstrings, pyFloorDiv, PyFloorDiv.floorDiv, PyHAdd.hAdd, PyHSub.hSub, PyHMul.hMul]
  rw [if_neg (by decide)]
  generalize pyCount s c = k
  have hev : (2:Int) ∣ k * (k - 1) := by
    have h := Int.even_mul_succ_self (k - 1)
    have hrw : (k - 1) * ((k - 1) + 1) = k * (k - 1) := by ring
    rw [hrw] at h
    exact h.two_dvd
  obtain ⟨q, hq⟩ := hev
  rw [hq, Int.mul_fdiv_cancel_left _ (by norm_num : (2:Int) ≠ 0)]
  nlinarith [hq]

end PastaBench.leetcode.CountSubstringsStartingAndEndingWithGivenCharacter
