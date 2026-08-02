import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.HexKey

/-- A hexadecimal number modelled as its list of one-character digit strings
(iterating a Python `str` yields length-1 `str`s). -/
def hex_key (num : List String) : Int :=
  PastaLean.pyLen (PastaLean.pyList (PastaLean.pyFilter (fun x ↦ PastaLean.pyContains "2357BD" x) num))

/-- Non-trivial correctness: the count of prime hex digits is between `0` and the
length of the input, i.e. `0 ≤ hex_key num ≤ len(num)`. -/
theorem hex_key_bounds (num : List String) :
    0 ≤ hex_key num ∧ hex_key num ≤ pyLen num := by
  have h1 : hex_key num
      = ((num.filter (fun x ↦ PastaLean.pyContains "2357BD" x)).length : Int) := rfl
  have h2 : pyLen num = (num.length : Int) := rfl
  rw [h1, h2]
  refine ⟨by positivity, ?_⟩
  exact_mod_cast List.length_filter_le (fun x ↦ PastaLean.pyContains "2357BD" x) num

end PastaBench.humaneval.HexKey
