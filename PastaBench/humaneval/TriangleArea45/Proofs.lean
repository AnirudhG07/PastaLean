import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.TriangleArea45

def triangle_area := fun (a : Rat) ↦ fun (h : Rat) ↦ (a *ₚ h /ₚ (2 : Int) : Rat)

/-- Twice the area equals base times height: the defining relation of a triangle's area. -/
theorem triangle_area_correct :
    ∀ (a h : Rat), (2 : Rat) * triangle_area a h = a * h := by
  intro a h
  simp only [triangle_area, PyHMul.hMul, PyHDiv.hDiv]
  ring

end PastaBench.humaneval.TriangleArea45
