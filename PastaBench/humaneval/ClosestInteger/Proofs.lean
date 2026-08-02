import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.ClosestInteger

/-- Parse a decimal string (optionally signed) into an exact `Rat`. -/
def parseRat (s : String) : Rat :=
  match s.splitOn "." with
  | [i, f] =>
    let ip : Int := i.toInt?.getD 0
    let fval : Rat := ((f.toNat?.getD 0 : Int) : Rat) / (((10 : Nat) ^ f.length : Nat) : Rat)
    if i.startsWith "-" then (ip : Rat) - fval else (ip : Rat) + fval
  | _ => ((s.toInt?.getD 0 : Int) : Rat)

/-- Closest integer, rounding halves away from zero. -/
def closest_integer (value : String) : Int :=
  let q := parseRat value
  if q ≥ 0 then Rat.floor (q + 1/2) else -Rat.floor (-q + 1/2)

theorem closest_integer_correct :
    closest_integer "10" = 10 ∧ closest_integer "14.5" = 15 ∧
    closest_integer "-15.5" = -16 ∧ closest_integer "15.3" = 15 ∧
    closest_integer "0" = 0 ∧ closest_integer "-2.8" = -3 := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.ClosestInteger
