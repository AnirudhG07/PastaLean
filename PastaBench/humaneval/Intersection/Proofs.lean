import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Intersection

/-- Trial-division primality (no sqrt): a ≥ 2 and no divisor in 2..a-1. -/
def isPrime (a : Int) : Bool :=
  2 ≤ a && (List.range a.toNat).all (fun x => x < 2 || a % (x : Int) != 0)

def intersection (i1 i2 : Int × Int) : String :=
  let len := min i1.2 i2.2 - max i1.1 i2.1
  if isPrime len then "YES" else "NO"

theorem intersection_correct :
    intersection (1, 2) (2, 3) = "NO" ∧
    intersection (-1, 1) (0, 4) = "NO" ∧
    intersection (-3, -1) (-5, 5) = "YES" := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

/-- General property: the verdict is always exactly "YES" or "NO". -/
theorem intersection_yes_or_no (i j : Int × Int) :
    intersection i j = "YES" ∨ intersection i j = "NO" := by
  simp only [intersection]; split <;> simp

end PastaBench.humaneval.Intersection
