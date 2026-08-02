import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RescaleToUnit

/-- The per-element linear map used by `rescale_to_unit`: `x ↦ (x - mi)/(ma - mi)`. -/
def rescale (mi ma x : ℚ) : ℚ := (x - mi) * (1 / (ma - mi))

/-- The defining property: the minimum maps to 0 and the maximum maps to 1. -/
theorem rescale_endpoints (mi ma : ℚ) (h : mi < ma) :
    rescale mi ma mi = 0 ∧ rescale mi ma ma = 1 := by
  have hne : ma - mi ≠ 0 := sub_ne_zero.mpr (ne_of_lt h).symm
  refine ⟨?_, ?_⟩
  · simp [rescale]
  · rw [rescale, mul_one_div, div_self hne]

end PastaBench.humaneval.RescaleToUnit
