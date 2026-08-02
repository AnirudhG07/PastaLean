import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsSimplePower

/-- True iff `x = n ^ k` for some non-negative integer `k`. -/
def is_simple_power (x n : Int) : Bool :=
  if x == 1 then true
  else if n == 0 then x == 0
  else if n == 1 then x == 1
  else if n == -1 then x.natAbs == 1
  else (List.range 32).any (fun k => n ^ k == x)

theorem is_simple_power_correct :
    is_simple_power 16 2 = true ∧ is_simple_power 143214 16 = false ∧
    is_simple_power 4 2 = true ∧ is_simple_power 9 3 = true ∧ is_simple_power 16 4 = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- General property: 1 is a power of every base (n⁰ = 1). -/
theorem is_simple_power_one (n : Int) : is_simple_power 1 n = true := by simp [is_simple_power]

end PastaBench.humaneval.IsSimplePower
