import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IsPrime

def is_prime := fun (n : Int) ↦
  (do
    if h_1 : n ≤ (1 : Int) then
      return Bool.false
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (n > (1 : Int)))
    let mut n_sqrt : Int := (1 : Int)
    while (n_sqrt ^ₚ (2 : Int) < n) do
      let _ := Libraries.passta.pyPassInvariant (decide (n_sqrt ≥ (1 : Int)))
      let _ := Libraries.passta.pyPassInvariant (decide ((n_sqrt -ₚ (1 : Int)) ^ₚ (2 : Int) < n))
      let _ := Libraries.passta.pyPassDecreases (n -ₚ n_sqrt ^ₚ (2 : Int))
      n_sqrt := n_sqrt +ₚ (1 : Int)
    let _ := Libraries.passta.pyPassAssert (decide (n ≤ n_sqrt ^ₚ (2 : Int)))
    for i in (PastaLean.pyRange (PastaLean.pyMin [n_sqrt +ₚ (1 : Int), n]) (2 : Int))do
      let _ := Libraries.passta.pyPassInvariant (decide ((2 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ PastaLean.pyMin [n_sqrt +ₚ (1 : Int), n]))
      let _ :=
        Libraries.passta.pyPassInvariant
          (PastaLean.pyAll ((PastaLean.pyRange i (2 : Int)).map fun d => n %ₚ d != (0 : Int)))
      if h_2 : n %ₚ i = (0 : Int) then
        return Bool.false
      else
        let _ := ()
    return Bool.true : Id _)

/-- Numbers `≤ 1` are correctly reported as non-prime. -/
theorem is_prime_small (n : Int) (h : n ≤ 1) : (is_prime n).run = false := by
  simp only [is_prime, Id.run, h, dif_pos]; rfl

end PastaBench.humaneval.IsPrime
